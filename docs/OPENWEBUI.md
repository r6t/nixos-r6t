# Open WebUI

Open WebUI runs in the `llm` LXC container on crown alongside `llama-server`.
Configuration lives in its sqlite database (`/var/lib/private/open-webui`,
bind-mounted to `/mnt/crownstore/app-storage/open-webui`); it is not file-driven
from this flake. This doc records the recipes that need to be poked into the
admin UI by hand.

## Backing services

- **Reverse proxy**: caddy on crown serves `https://oi.r6t.io` and proxies to
  the container's port 8087 (incus proxy device).
- **OAuth/OIDC**: PocketID. Secrets injected via `/etc/oi.env` (bind-mounted
  from `/mnt/crownstore/Sync/app-config/open-webui/oi.env`).
- **Local model backend**: `llama-server` on `localhost:8080` inside the
  container, registered as the first OpenAI connection.
- **Cloud model backend**: OpenRouter as the second OpenAI connection.

## Thinking toggle for Qwen3.6

Crown's `llama-server` runs with `--reasoning off` as the global default — fast
direct responses for typical chat. To get Qwen3.6's thinking mode (the
`<think>...</think>` reasoning trace) when needed, create a second model preset
in the Workspace that flips `enable_thinking=true` per-request.

### How it works

llama.cpp's chat completions endpoint accepts a top-level `chat_template_kwargs`
object that is forwarded to the model's jinja template. For Qwen3.6 the relevant
kwarg is `enable_thinking`. Since our server-level `--reasoning off` is just the
template default, any request that explicitly sends
`chat_template_kwargs: {"enable_thinking": true}` overrides it for that one call
and the response comes back with `reasoning_content` populated alongside
`content`.

Open WebUI exposes per-model "custom params" that get merged into every outgoing
request to the model's backend. So creating a Workspace model preset with that
custom param produces a second entry in the model picker that always thinks.

### One-time setup (admin UI)

1. Sign in to <https://oi.r6t.io> as admin.
2. Open **Workspace > Models**.
3. Find the existing `unsloth/Qwen3.6-27B-GGUF` entry (the default fast preset
   that the llama-server connection auto-discovers). Either edit it or, more
   safely, **clone** it.
4. On the cloned/edited preset:
   - **Name**: `Qwen3.6 27B (Thinking)`
   - **Description**: `Reasoning enabled per-request via chat_template_kwargs.
Visible <think> trace in chat. Slower wallclock to first visible token.`
   - **Tags**: `local`, `thinking` (optional, just for filtering in the picker).
   - Leave the **Base Model** as `unsloth/Qwen3.6-27B-GGUF`.
5. Scroll down to **Advanced Params** and click **Show**. Find the
   **Custom Parameters** section near the bottom (it lets you enter arbitrary
   key/value pairs that get merged into the request body).
6. Add a single custom parameter:
   - **Key**: `chat_template_kwargs`
   - **Value**: `{"enable_thinking": true}`

   Open WebUI parses values as JSON when possible — the curly braces are
   mandatory. Without them you'd send the literal string instead of an object.

7. **Save**. The model now appears in the picker as `Qwen3.6 27B (Thinking)`.

### Verifying

In a fresh chat with the thinking preset selected, ask anything that benefits
from reasoning ("What is 17 × 23 step by step?"). You should see:

- A `<think>` block streamed first containing the model's reasoning, rendered
  by Open WebUI as a collapsible "Thinking" section.
- The visible answer afterwards.
- Total wallclock noticeably longer than the same prompt on the default preset
  (thinking adds 100–500 invisible tokens before any visible output).

If thinking does NOT activate, check that `chat_template_kwargs` was saved as a
JSON object (`{"enable_thinking": true}`) and not a string. Open WebUI's UI may
display the value with quotes around it; that's fine as long as the actual
serialized value is a JSON object — easiest verification is to look at the
`llama-server` journal during a request:

```fish
incus exec llm -- journalctl -u llama-cpp --since "1 minute ago" | grep -E "thinking|reasoning"
```

A working request shows `init: chat template, thinking = 1` for that request
specifically (separate from the server-level default of `thinking = 0`).

### Why two presets instead of a single toggle button

Open WebUI's UI does not (as of the version we run) expose a "thinking on/off"
button in the chat header — only paid hosted services like ChatGPT and Claude
do. Workspace model presets are the closest equivalent: they appear in the
model picker as separate entries and switching is a single click. The two
presets share the same KV cache slot on the llama-server side because they
reference the same base model; the only difference is the request body.

### Caveats

- Qwen3.6's official model card explicitly notes it does NOT support the `/think`
  and `/nothink` soft-switch tokens that earlier Qwen3 generations recognized.
  The chat template kwarg is the only supported way to toggle.
- Qwen3.6 thinking can be unbounded — it occasionally produces 1000+ tokens of
  reasoning before the visible answer. There is no client-side budget cap; if
  this becomes a problem, set `--reasoning-budget N` on `llama-server` (still
  applies as the server-level cap regardless of per-request kwargs).
- Switching presets mid-conversation may invalidate prefix-cache reuse for the
  next message because the chat template differs slightly between
  thinking/no-thinking modes. Not a correctness issue, just a small re-prefill
  cost on the first message after switching.

## Web search

Open WebUI has two distinct "web search" mechanisms and they behave very
differently. Picking the right one for your situation matters.

### A) Built-in "Web Search" button (RAG-style, retrieval-before-generation)

This is what the **Web Search toggle in the chat composer** does. When toggled
on for a chat, Open WebUI:

1. Sends your query to the configured search backend
2. Fetches the top N result pages
3. Loads each page's text content
4. Embeds the content as additional context in the prompt to the model

The model **does not decide** to search — Open WebUI always searches when the
toggle is on, and the model just sees the retrieved chunks. Any model that
reads text can use this; no tool-calling required.

The crown LXC fleet already runs a SearXNG instance at `https://searxng.r6t.io`,
which is the search backend we use.

#### One-time setup (admin UI)

1. **Verify SearXNG's JSON API is reachable.** Open WebUI uses the JSON
   format, not HTML. Test from anywhere on the LAN/tailnet:

   ```fish
   curl -s "https://searxng.r6t.io/search?q=test&format=json" | head -c 200
   ```

   Expect a JSON object beginning with `{"query":` — if you get HTTP 403, the
   SearXNG container is missing `json` in `services.searx.settings.search.formats`.
   This flake's `containers/searxng.nix` declares it; rebuild + relaunch that
   container if it's missing.

2. **Configure Open WebUI to use SearXNG.**
   Admin Panel > Settings > Web Search:
   - **Enable Web Search**: ON
   - **Web Search Engine**: `searxng`
   - **Searxng Query URL**: `https://searxng.r6t.io/search?q=<query>&format=json`
     (the `<query>` placeholder is mandatory — Open WebUI substitutes the
     user's query into it).
   - **Search Result Count**: 3 is the default; 5 is fine; >10 starts to
     consume a lot of context tokens.
   - Leave the **Web Loader** at default; the built-in loader is good enough
     for most pages.
   - Save.

3. **Per-model: enable the Web Search capability.**
   Workspace > Models > (your model) > Capabilities:
   - **Web Search**: ON

   Without this toggle the model preset disables the web-search button for
   that model even though the global feature is enabled.

4. **In a chat: use the button.**
   The composer at the bottom of any chat now shows a globe / web-search icon.
   Click it before sending a message. The next response is generated with
   search results in context. The UI shows a "Searching..." step and links to
   the sources used.

#### Stopping the model from refusing

A common symptom: model replies "I cannot access the web" even though Web
Search is enabled. This happens when:

- **Web Search toggle was NOT on for that message.** The toggle is per-message,
  not per-chat — click it for each query that needs fresh data. To make it
  default-on for a model, set it as part of the model preset's Capabilities
  (step 3 above) — that turns it on by default in fresh chats with that model.
- **Backend was unreachable** (SearXNG returned 403 / 5xx). Look at the chat
  steps panel — if "Searching" failed silently, no results were injected and
  the model had to answer without context, often defaulting to refusal.
- **Model trained to refuse web claims**: Qwen3.6 sometimes says "I cannot
  browse" even when given fresh context, because its instruction tuning is
  conservative. Fix this with a one-line addition to the model preset's
  **System Prompt**:

  ```text
  When the user's message includes search results from the web, treat them as
  authoritative current information and answer based on them. Do not claim you
  cannot access the web — you have already been provided with relevant pages.
  ```

  Add it to the `Qwen3.6 27B` and `Qwen3.6 27B (Thinking)` presets in
  Workspace > Models. The system prompt is jinja-templated so this string is
  injected as the first system message before each request.

#### Verification

After enabling, ask the model a question it cannot answer from training data,
e.g. _"What was the closing price of TSLA today?"_ — toggle Web Search ON
before sending. You should see:

1. A "Searching..." step in the response
2. Citation links to the result pages
3. An answer that references current values from the linked pages

If you don't see step 1, the Web Search toggle wasn't on. If you see step 1
but the model still refuses, the system prompt fix above is needed.

### B) Tool-calling search (model decides when to search)

This is the more agentic pattern: the model is told it has a `web_search` tool
available and decides whether and when to call it during the response. Used by
ChatGPT's "browse" tool and Claude's MCP integrations.

For Open WebUI + llama-server this requires more setup:

1. **Verify llama-server tool-calling works** for Qwen3.6.
   Qwen3.6 has explicit tool-call support via its jinja template (we already
   pass `--jinja`). Test with a simple tool definition in `curl`:

   ```fish
   incus exec llm -- curl -s -X POST http://127.0.0.1:8080/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{
       "messages":[{"role":"user","content":"What is the weather in Seattle?"}],
       "tools":[{
         "type":"function",
         "function":{
           "name":"get_weather",
           "description":"Get current weather for a city",
           "parameters":{"type":"object","properties":{"city":{"type":"string"}}}
         }
       }]
     }'
   ```

   A working response includes `tool_calls` in `choices[0].message`. If yes,
   Qwen3.6 + llama-server can do tool-calling.

2. **Create or import an Open WebUI Tool** that performs the web search.
   In Workspace > Tools, either:
   - Write a Python tool calling SearXNG's JSON API directly, OR
   - Import an existing one from the [Open WebUI community](https://openwebui.com/tools)
     — search for "searxng" or "web search".

   The tool exposes a function like `search_web(query: str) -> str` that
   returns text the model can incorporate.

3. **Bind the tool to the model preset.**
   Workspace > Models > (preset) > Tools: enable the new `web_search` tool.

4. **In chat:** the model decides whether to call the tool based on the user's
   message. Tool calls appear as expandable steps in the response.

This route is more "Claude-like" but adds:

- Tool-call latency (model thinks → emits tool_call → OWUI runs tool → results
  fed back → model continues)
- Sensitivity to model tool-calling reliability (Qwen3.6 is good at this but
  not perfect, especially under long context)

For most chat use, the RAG-style toggle (A) is simpler and more reliable.
Pursue (B) when you want the model to dynamically decide what to search for.

## Other useful patterns

This section will grow as more recipes are needed. So far:

- **Per-conversation custom_params**: open the chat's settings cog in the
  upper-right and look for _Advanced > Custom Params_. Same key/value mechanism,
  scoped to a single conversation. Useful for one-off experiments without
  creating a Workspace preset.
