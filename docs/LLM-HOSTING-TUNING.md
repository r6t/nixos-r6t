# LLM Hosting & Tuning on Crown

How the `llm` LXC container hosts local large language models on crown's AMD
Radeon AI Pro R9700, what works well, what's slow and why, and how to swap
between models. Captures lessons learned through May 2026 (last updated
2026-05-16).

This is a long doc. Skim the table of contents and jump to what you need.

## Contents

- [Architecture overview](#architecture-overview)
- [Hardware](#hardware)
- [GPU backend choice (Vulkan over ROCm)](#gpu-backend-choice-vulkan-over-rocm)
- [The model architecture trap (hybrid vs SWA vs standard)](#the-model-architecture-trap-hybrid-vs-swa-vs-standard)
- [Available model presets](#available-model-presets)
- [Switching models](#switching-models)
- [Multi-model serving (router mode)](#multi-model-serving-router-mode)
- [Model download / caching](#model-download--caching)
- [llama-server tuning flags](#llama-server-tuning-flags)
- [VRAM budgeting](#vram-budgeting)
- [KV cache quantization](#kv-cache-quantization)
- [Cold-start vs warm performance](#cold-start-vs-warm-performance)
- [Multi-turn TTFT (the perceived-speed problem)](#multi-turn-ttft-the-perceived-speed-problem)
- [Measured benchmarks](#measured-benchmarks)
- [MTP speculative decoding](#mtp-speculative-decoding)
- [Open WebUI integration](#open-webui-integration)
- [opencode integration](#opencode-integration)
- [Should you buy a different GPU?](#should-you-buy-a-different-gpu)
- [Quick reference](#quick-reference)

## Architecture overview

```
                                  crown (NixOS host)
                                  ┌──────────────────────────────────────────┐
  https://oi.r6t.io      caddy    │                                          │
  https://llm.r6t.io  ─────────►  │  llm LXC container (containers/llm.nix) │
                                  │  ┌────────────────────────────────────┐ │
                                  │  │  open-webui   (port 8087)          │ │
                                  │  │  llama-server (port 8080)          │ │
                                  │  │      │                             │ │
                                  │  │      └──► /dev/dri/renderD129      │ │
                                  │  │           (R9700 Vulkan via RADV)  │ │
                                  │  └────────────────────────────────────┘ │
                                  │      ▲                                  │
                                  │      │ AMD Radeon AI Pro R9700          │
                                  │      │ 32 GB VRAM, RDNA 4 / gfx1201     │
                                  │      │ vendorid 1002 productid 7551     │
                                  │      │ (productid-filtered by incus)    │
                                  └──────┼──────────────────────────────────┘
                                         │
                                         └── PCIe → host kernel amdgpu
```

The container exposes the GPU's DRM render node only (no `/dev/kfd` since we
use Vulkan, not ROCm). Networking and DNS follow the standard pattern
documented in `docs/INCUS.md`.

## Hardware

| Component        | Spec                                               |
| ---------------- | -------------------------------------------------- |
| GPU              | AMD Radeon AI Pro R9700                            |
| Architecture     | RDNA 4 / gfx1201 (Navi 48)                         |
| VRAM             | 32 GB GDDR6                                        |
| Memory bandwidth | 640 GB/s                                           |
| PCIe             | Gen 5 x16 (32 GT/s, Thunderbolt enclosure → crown) |
| Kernel driver    | in-tree amdgpu                                     |
| Userspace        | Mesa 26.0.5 + RADV ICD                             |
| llama-cpp build  | b8983 (as of 2026-05-16)                           |

The R9700 is in an **external Thunderbolt enclosure** attached to crown. The
GPU is passed directly into the `llm` LXC container via incus `gputype:
physical` filtered by vendorid `1002` / productid `7551` (Navi 48 only —
excludes the Ryzen Phoenix iGPU which shares the same vendorid).

## GPU backend choice (Vulkan over ROCm)

The `llm` container uses **`pkgs.llama-cpp-vulkan`**, not `pkgs.llama-cpp-rocm`.
This was measured, not assumed. On RDNA 4 (gfx1201) the Vulkan backend with the
RADV driver is:

- **More stable** than ROCm/HIP on this generation (gfx1201 ROCm support in
  ROCm 6.x is functional but tuning is years behind CUDA on similar generations).
- **Often faster** for inference workloads. Multiple R9700 benchmark posts
  (r/LocalLLaMA, llama.cpp discussions #21043, #19890 from Q1 2026) all use
  Vulkan, not ROCm.
- **No `/dev/kfd` dependency** — simpler container setup.
- **No host-side ROCm package** — host stays clean, all GPU stack lives in the
  container's Mesa + RADV.

The choice is captured in `mine.llama-cpp.vulkan = true` in
`containers/llm.nix`. The `mine.llama-cpp` module also has a `rocm = true`
mutually-exclusive option for hardware where ROCm is the better path
(e.g. older CDNA accelerators, or specific RDNA 3 setups where ROCm has
matured well enough).

### Required environment

The llama-cpp module sets these env vars automatically for the Vulkan path:

- **`RADV_PERFTEST=nogttspill`** — measured 4.5× decode speedup on Mesa 26.x
  with the R9700. Without it, the driver spills model weight allocations from
  VRAM into GTT (host-mapped GPU-visible RAM) under perceived pressure,
  causing catastrophic PCIe round-trips per token. The community claim that
  this flag is a no-op on newer Mesa (llama.cpp discussion #21043 from
  2026-03-26) **does NOT hold** for this setup — A/B benchmarked it, kept it.
- **`MESA_SHADER_CACHE_DIR=/var/cache/llama-cpp/mesa-shaders`** — persists the
  Mesa pipeline cache across service restarts. First-time prompt-processing
  with each unique batch shape compiles a SPIR-V → ISA pipeline (slow, ~15-20
  seconds for the typical ubatch=2048 path on first hit). Cached compiles are
  ~instant. Without persistence, every container relaunch re-pays this cost.
  See [Cold-start vs warm performance](#cold-start-vs-warm-performance) below.

### Also required: container-side Mesa

The container needs `hardware.graphics.enable = true` so the Vulkan ICD JSON
files (`/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json`) and the
RADV shared libraries are actually present in the container's nix closure.
Without this, `pkgs.llama-cpp-vulkan` starts cleanly but reports
`no usable GPU found` because the Vulkan loader has nothing to load — even
though `/dev/dri/renderD129` is passed through correctly.

## The model architecture trap (hybrid vs SWA vs standard)

This is the single most important thing to understand for chat-speed
perception. It is not about quality, not about quant, not about the GPU. It
is about how the model's attention layers handle the KV cache.

### Three categories

| Category                                               | Examples                                                               | Partial KV sequence removal                                          | Multi-turn cache reuse on llama.cpp | Feel                         |
| ------------------------------------------------------ | ---------------------------------------------------------------------- | -------------------------------------------------------------------- | ----------------------------------- | ---------------------------- |
| **Hybrid attention**                                   | Qwen3.5, Qwen3.6, Qwen3-Next, RWKV, Mamba/Jamba                        | Not supported                                                        | Permanently disabled                | Slow every turn              |
| **SWA + global** (newer Gemma, others)                 | Gemma 4 series                                                         | Supported, **but only on llama.cpp build ≥ b8819 with `--swa-full`** | Works on recent builds              | Snappy when configured right |
| **Standard transformer** (dense or pure-attention MoE) | Qwen3-Coder dense MoE, Mistral / Devstral, Llama, most everything else | Supported                                                            | Works                               | Snappy                       |

### Why this matters

When you reply to a model's message in a chat, ~95% of the prompt is the
existing conversation history you've already sent before. A working KV cache
lets the engine **skip re-processing tokens it has already prefilled** — only
the new tokens (your latest user turn + a bit of template glue) need fresh
prefill. That's how Ollama on a small Llama variant feels instant on turn N:
~10 new tokens to prefill, then immediately generate.

**Hybrid attention models break this** because their recurrent layers carry
rolled-up state across all positions in the sequence. You can't surgically
remove the KV state for "the last 200 tokens because the user edited their
prompt" — the rolled-up state has already mixed those tokens in. llama.cpp
detects this and silently disables cache reuse entirely. **Every turn does a
full re-prefill of the entire conversation.** On a 2000-token chat history at
700 tok/s prefill that's ~3 seconds of dead time before the model starts
generating, even though the actual model speed (21 tok/s) hasn't changed.

llama.cpp [issue #22940](https://github.com/ggml-org/llama.cpp/issues/22940)
(filed 2026-05-11) confirms this is a known limitation. A ~50-line patch
exists but is unmerged. Reporter measured a 12-turn agent loop at 298.5s →
121.7s with the patch (~2.4× faster). When that patch lands upstream we'll
get the speedup for free.

### Why setting `cacheRamMiB = 0` matters for hybrid models

llama-server has a separate **disk-backed prompt cache** (`--cache-ram N`) that
tries to checkpoint slot KV state to disk so future turns can skip work. For
hybrid models this writes 150-200 MiB per turn (taking 1-30 seconds in
practice due to what appears to be O(n²) state serialization in llama.cpp,
not the disk — NVMe sequential bandwidth is 1.8 GB/s through the LXC bind
mount) and **never reads it back** because cache reuse is disabled. Pure
overhead.

`mine.llama-cpp.cacheRamMiB` is per-model so each preset sets the right value:

- Hybrid (Qwen3.6): `cacheRamMiB = 0`
- Standard / SWA: `cacheRamMiB = 8192` (llama-server default)

The disk cache also has a documented [silent corruption
bug](https://github.com/ggml-org/llama.cpp/issues/21681) on hybrid models —
mid-history mutations can cause output digit-drops. `cacheRamMiB = 0` is the
only correctness-safe setting for these models today.

## Available model presets

Presets are defined in `containers/llm.nix` under `let { models = … }`.
Switch between them with one line: `activeModel = models.<name>;`.

| Preset                 | Architecture     | Active params | Quant / Size        | Multi-turn TTFT                      | Decode tok/s (R9700, measured) | When to use                                                      |
| ---------------------- | ---------------- | ------------- | ------------------- | ------------------------------------ | ------------------------------ | ---------------------------------------------------------------- |
| `qwen3-6-35b-a3b`      | MoE hybrid GDN   | ~3B / 35B     | UD-Q4_K_M, ~20 GB   | **Slow every turn** (full reprefill) | **~63 tok/s** (measured)       | **Current primary** — best quality/speed balance that fits 32 GB |
| `qwen3-6-27b`          | dense hybrid GDN | 27B           | Q6_K, 22.5 GB       | **Slow every turn**                  | ~21                            | Higher quant fallback if 35B feels off                           |
| `qwen3-30b-a3b`        | MoE standard     | ~3B / 30B     | UD-Q6_K_XL, ~26 GB  | Snappy                               | ~140-180 (predicted)           | Snappy multi-turn, standard transformer                          |
| `devstral-small-2-24b` | dense standard   | 24B           | UD-Q6_K_XL, 19.4 GB | Snappy                               | ~25-30                         | Deterministic coding alternative                                 |
| `gemma4-26b-a4b`       | MoE SWA          | 3.8B / 26B    | UD-Q6_K_XL, 21.7 GB | Snappy (req ≥ b8819 + --swa-full)    | ~110-160 (predicted)           | Fastest decode; commented out in config                          |

### Why `qwen3-6-35b-a3b` is the current primary

After A/B testing all available presets (May 2026), Qwen3.6-35B-A3B
UD-Q4_K_M emerged as the best practical choice for this hardware:

- **Quality**: 35B total params with GatedDeltaNet hybrid attention produces
  noticeably better reasoning and coding output than the 27B sibling. The
  UD-Q4_K_M dynamic quant preserves quality on attention-sensitive tensors
  while fitting within the VRAM budget.
- **Speed**: ~63 tok/s measured decode on the R9700. Subjectively fast for
  interactive chat.
- **VRAM fit**: ~20 GB weights leaves 12 GB for KV cache + compute graph,
  enabling 128K context with q4_0 KV cache quant.
- **Architecture caveat**: hybrid GatedDeltaNet attention means every turn
  does a full re-prefill of the conversation history. At short context
  (under ~5K tokens) this is sub-second. At long context (25K+ tokens) it
  becomes multi-second. See [Multi-turn TTFT](#multi-turn-ttft-the-perceived-speed-problem).

### Architecture notes

- **`qwen3-6-35b-a3b`**: hybrid GatedDeltaNet MoE. ~3B active params out of
  35B total. UD-Q4_K_M dynamic quant from unsloth — higher precision on
  attention layers, lower on FFN. No plain Q4_K_M exists for this model;
  UD-Q4_K_M is the correct file. Native 256K context. Thinking via
  `enable_thinking` kwarg; `--reasoning off` at server level, clients opt in.
  `cacheRamMiB = 0` mandatory (hybrid attention makes disk cache pure overhead,
  see below).

- **`qwen3-6-27b`**: same hybrid GDN family, higher quant (Q6_K), lower total
  params. Useful if the 35B UD-Q4_K_M shows quality regressions from
  quantization — Q6_K is meaningfully higher precision.

- **`qwen3-30b-a3b`**: standard MoE transformer (NOT hybrid GDN). Full KV
  cache reuse, snappy multi-turn. UD-Q6_K_XL at ~26 GB is tight on 32 GB at
  64K context. Trade: slower decode than 35B hybrid (fewer routed experts) but
  every turn is fast.

- **`devstral-small-2-24b`**: dense standard transformer, most deterministic.
  No MoE routing variance. Good opencode backend when tool-call reliability
  matters more than speed or quality.

- **`gemma4-26b-a4b`**: MoE SWA, fastest predicted decode (~110-160 tok/s) due
  to only 3.8B active params. Requires llama.cpp ≥ b8819 and `--swa-full` for
  multi-turn cache reuse. Comfortable VRAM headroom at 128K context. Commented
  out in the config because the 35B hybrid was preferred after A/B — uncomment
  and switch `activeModel` to try it.

### Quants explained

We use a mix of unsloth's **UD-Q\*\_K_XL** dynamic quants and plain **Q\*\_K**
where the UD variant isn't materially better. Unsloth's "Dynamic 2.0" recipe
applies higher precision to attention-sensitive tensors while keeping FFN
weights compressed, recovering most of the quality of the next quant up.

Per their published KLD measurements on Qwen3.6-27B:

| Quant  | KLD (lower is closer to Q8_0/BF16) | Weights  |
| ------ | ---------------------------------- | -------- |
| Q8_0   | 0.0038 (gold)                      | ~28.6 GB |
| Q6_K   | 0.0072                             | ~22.5 GB |
| Q5_K_M | 0.0108                             | ~19.7 GB |
| Q4_K_M | ~0.025                             | ~17 GB   |
| Q4_K_S | higher                             | smaller  |

Q6_K is "92% of Q8 in absolute quantization-error terms" — a safe choice that
trades 6 GB of weights for KV cache headroom at 128K context.

Avoid IQ-quants (IQ4_NL, IQ4_XS) on AMD — JohnTDI-cpu's RDNA 4 sweep showed
K-quants outperform IQ-quants on Vulkan/RADV for this generation.

## Switching models

llama-server is a **single-process, single-model** inference server. The
model is baked into the systemd ExecStart line at container build time via
the `--model` flag. To switch:

```fish
# 1. Edit containers/llm.nix, change `activeModel = models.<old>` to
#    `activeModel = models.<new>`
$EDITOR ~/git/nixos-r6t/containers/llm.nix

# 2. Rebuild the container image (picks up the new ExecStart)
python3 containers/build.py llm

# 3. Relaunch the container (stops old, starts new with new image)
python3 containers/relaunch.py llm

# 4. Wait ~30s for the new model to load into VRAM. Watch progress:
incus exec llm -- journalctl -u llama-cpp --no-pager -f
# Look for "main: model loaded" then Ctrl+C
```

The full round-trip is ~30-60 seconds end-to-end on a model that's already
cached locally. If the GGUF isn't cached, llama-server auto-fetches from
HuggingFace on first start (`--hf-repo`, `--hf-file`). 20+ GB GGUF download
over your home connection adds ~5-15 minutes.

**Currently active model is whichever `activeModel` is in
`containers/llm.nix`** — only one at a time. Open WebUI sees the active
model in its picker as one entry.

## Multi-model serving (router mode)

If you find yourself constantly toggling between models (e.g. chat in
Gemma 4, coding in Qwen3-Coder, drafting with Qwen3.6), llama-server has a
**router mode** that lazy-loads models from a directory on demand.

Run llama-server without `--model` but with `--models-dir /var/lib/llama-cpp/models`.
Clients hitting `/v1/chat/completions` with different `"model": "<name>"`
fields trigger load/unload. Open WebUI's `/v1/models` call returns the full
list and the model picker shows them all.

**Tradeoffs**:

- Cold model swap is 15-30 seconds per change (must unload one, load another).
- Only one model is GPU-resident at a time — VRAM doesn't get magically
  shared.
- Idle models still occupy disk in the cache.
- The first request to each model is slow; subsequent requests to that model
  are warm until you swap.

We have not yet implemented router mode. The `mine.llama-cpp` module's
`modelsPreset` option is the hook for it. If/when we do, the pattern would be
to define each model in `modelsPreset` (HF repo + file) and drop the
single-`modelFile` config. Model picker then shows all of them in OWUI and
opencode. Cold-load-on-switch UX is acceptable for occasional use; not for
real-time alternation between models within a conversation.

**Current recommendation**: single-active model is simpler and matches how
you actually use this. If/when toggling becomes annoying, switch to router
mode.

## Model download / caching

GGUF files are persisted via the LXC bind-mount from
`/mnt/crownstore/app-storage/llama-cpp-cache` to
`/var/cache/llama-cpp` (which is systemd's `CacheDirectory` = the
DynamicUser-namespaced view of `/var/cache/private/llama-cpp` on the
container's root filesystem).

`/mnt/crownstore` is a Crucial P3 Plus 4TB NVMe (Gen4) — fast.

### What's auto-downloaded

llama-server uses `--hf-repo` + `--hf-file` flags. On startup it checks the
local cache; if the file isn't there it downloads from HuggingFace into the
HF-conventional path `models--{org}--{repo}/snapshots/<rev>/<file>.gguf`.

Only the **active** model is auto-downloaded. Adding a preset to
`containers/llm.nix` does NOT pre-fetch the GGUF — that happens on first use.

### Cache hygiene

Check what's cached:

```fish
incus exec llm -- du -sh /var/cache/llama-cpp/models--*/
```

If you have models from old experiments that you'll never use again:

```fish
incus exec llm -- rm -rf /var/cache/llama-cpp/models--unsloth--<repo>-GGUF/
```

### Pre-caching without making a model active

If you want to download a model in advance without making it the active
preset (e.g. before bedtime so it's ready in the morning):

```fish
incus exec llm -- bash -c '
  cd /var/cache/llama-cpp
  /nix/store/.../hf-cli-or-curl ...  # download to the right snapshot path
'
```

Easier approach: temporarily set `activeModel = models.<new>`, build+relaunch
(triggers download), then switch `activeModel` back and rebuild+relaunch
again. The first round downloads; subsequent loads are from cache.

## llama-server tuning flags

The `mine.llama-cpp` module emits a baseline set of flags. Individual model
presets can append more via `extraFlags`.

### Baseline (always emitted)

```
-ngl 99                       # full GPU offload (all layers)
--flash-attn auto             # KHR_coopmat on RADV → +4-11% prefill, +4% gen
--cache-type-k q8_0           # halve KV VRAM, near-zero quality loss
--cache-type-v q8_0           # symmetric for fused FA kernel
-c <contextSize>              # per-model
-ub <ubatchSize>              # default 2048, great for warm prefill
--prio 2                      # high process priority for GPU-bound work
--cache-reuse 256             # silently no-op on hybrid, helps on others
--cache-ram <cacheRamMiB>     # per-model (0 for hybrid, 8192 for standard)
-np 1                         # one parallel slot (all VRAM to one session)
```

### Per-model `extraFlags` patterns

```nix
# Qwen3.6 — hybrid, thinking off by default
extraFlags = [
  "--jinja"           # required for Qwen tool-use template
  "--no-mmproj"       # text-only
  "--reasoning" "off" # client opts in via chat_template_kwargs
];

# Gemma 4 — needs --swa-full for cache reuse to work
extraFlags = [
  "--jinja"
  "--no-mmproj"
  "--swa-full"        # REQUIRED for SWA cache reuse (llama.cpp ≥ b8819)
  "--reasoning" "off"
];

# Qwen3-Coder — no special flags, defaults are fine
extraFlags = [ "--jinja" ];
```

### Flags to never use on this hardware

- **`--spec-type ngram-mod`** — speculative decoding via n-gram match. Looks
  attractive but is silently rejected by hybrid-attention models (Qwen3.6
  specifically). Even when accepted, the verification step needs partial KV
  sequence removal — incompatible with hybrid. For SWA models, may or may
  not work; haven't validated. Don't add globally.
- **`--no-host`** — has been linked to 94% slowdowns on AMDVLK (not our
  driver, but adjacent). Don't try it on RADV either.
- **`GGML_VK_DISABLE_FUSION`** env — catastrophic (-18.5% MoE, -5% dense) on
  RADV per JohnTDI's sweep. Don't disable Vulkan graph fusion.
- **`-sm row` or `-sm tensor`** — split modes for multi-GPU. Single-GPU
  setup, irrelevant.

## VRAM budgeting

Current R9700: 32 GB total, ~31.5 GB usable for compute. The budget
constraint is:

```
weights + KV_cache + compute_graph + (optional mmproj) ≤ ~31 GB
```

Estimates for our presets at their configured context size, with q4_0 KV
(current config for the primary):

| Preset                                        | Weights | KV @ ctx (q4_0) | Compute graph | Total | Headroom |
| --------------------------------------------- | ------- | --------------- | ------------- | ----- | -------- |
| qwen3-6-35b-a3b (UD-Q4_K_M, 131072 ctx, q4_0) | ~20.0   | ~4.3            | ~4.7          | ~29.0 | ~2.5     |
| qwen3-6-27b (Q6_K, 65536 ctx, q8_0)           | 22.5    | 2.2             | 3.8           | 28.5  | ~3.0     |
| qwen3-30b-a3b (UD-Q6_K_XL, 65536 ctx, q8_0)   | 26.3    | 2.5             | 1.5           | 30.3  | ~0.7     |
| devstral-small-2-24b (UD-Q6_K_XL, 98304 ctx)  | 19.4    | 5.0             | 4.0 (est)     | 28.4  | ~3.0     |
| gemma4-26b-a4b (UD-Q6_K_XL, 65536 ctx, q8_0)  | 21.7    | 3.5 (est)       | 3.5 (est)     | 28.7  | ~2.5     |

Qwen3-30B-A3B runs tight — keep an eye on VRAM during real use, especially
on long contexts. If you OOM, drop context size or switch to q4_0 KV.

**Measured during inference (2026-05-16)**: 23.72 GB / 32 GB (74%) for
qwen3-6-35b-a3b at ~25K token context with q8_0 KV. After switching to
q4_0 KV + 131K context, expect similar utilization at the larger context.

### Why we use `--no-mmproj` everywhere

Multimodal projector (vision encoder) adds ~1 GB to VRAM for Qwen3.6,
Gemma 4 etc. We don't use vision in chat or coding workflows — saving 1 GB
lets us run a slightly larger quant or context. Web search retrieves text,
not images, so this doesn't hurt that flow.

If you ever want vision (e.g. paste a screenshot to chat about it), remove
`--no-mmproj` from the model's `extraFlags` and rebuild. Costs ~1 GB VRAM.

## KV cache quantization

K and V cache tensors store the model's attention state for the current
context. Quantizing them saves significant VRAM, enabling larger context
windows at the cost of some attention precision at long range.

| KV quant | VRAM vs f16 | Quality impact                                                                | Use when                                     |
| -------- | ----------- | ----------------------------------------------------------------------------- | -------------------------------------------- |
| `f16`    | 1×          | None (reference)                                                              | Never — wastes VRAM                          |
| `q8_0`   | 0.5×        | None measurable                                                               | Default for most models                      |
| `q4_0`   | 0.25×       | Negligible at short/medium context; slight long-range retrieval fuzz at 100K+ | Primary when you need 128K+ context on 32 GB |

**Important**: `q4_0` KV does **not** make the model "dumber" — it does not
affect model weights. It reduces precision in how the model _attends to
earlier tokens_ at very long range. For opencode tool-call loops and typical
chat, the difference is unmeasurable. For a 200-message chat where you need
to recall a specific detail from message 3, you may notice occasional
imprecision.

The fused flash-attention kernel requires K and V to be the **same** type, so
the only valid choices are `f16/f16`, `q8_0/q8_0`, or `q4_0/q4_0`. Mixed
types disable the fused kernel and cost ~4-10% throughput.

**Current config**: `q4_0` for `qwen3-6-35b-a3b` to enable 131K context on
32 GB. All other presets use `q8_0` at their respective smaller context sizes.

## Cold-start vs warm performance

Two distinct cold paths:

### 1. Container restart → first generation request

The Mesa shader pipeline cache might or might not be warm depending on
what pipeline shapes were exercised previously. With `MESA_SHADER_CACHE_DIR`
persistence pointing to `/var/cache/llama-cpp/mesa-shaders`, the cache
survives container relaunches (it lives in the bind-mounted volume, not the
ephemeral container rootfs).

The slowest path is **first prompt prefill at ubatch=2048 size** — Mesa
needs to compile that pipeline variant if it isn't cached. Measured at
~18 seconds for a ~20-token prompt on a fresh container relaunch.

Subsequent generations are warm: ~700 tok/s prefill, ~21-180 tok/s decode
depending on model.

The 5.4 MB / 200-entry cache built up through normal use covers most common
pipeline shapes. After a few sessions, even container restarts feel fast.

### 2. First model load

Loading a 22 GB GGUF from NVMe into VRAM takes ~15 seconds:

- ~10s to mmap+stream the file
- ~5s for llama.cpp's internal tensor placement and initial GPU buffer setup

If the GGUF isn't cached locally (first time using a new preset), add
~5-15 minutes for the HuggingFace download. Watch `journalctl -u llama-cpp`
during startup to see download progress.

## Multi-turn TTFT (the perceived-speed problem)

This is the question that drove most of the tuning work.

The "first feels fast, second turn feels slow" pattern users see in our
setup comes from **hybrid attention's full re-prefill on every turn**. See
the [model architecture trap](#the-model-architecture-trap-hybrid-vs-swa-vs-standard)
section above.

The fix has two parts:

1. **Run a model that supports partial KV sequence removal**. Standard
   transformers (Devstral, Qwen3-Coder, etc.) always do. SWA models (Gemma 4)
   do with the recent llama.cpp fix and `--swa-full`.
2. **For Gemma 4 specifically, ensure llama.cpp is build ≥ b8819** (PR
   [#22288](https://github.com/ggml-org/llama.cpp/pull/22288) merged
   2026-04-24). The current nixpkgs pin is b8983 ✓.

### Measured baseline (Qwen3.6-35B-A3B UD-Q4_K_M, our hardware, 2026-05-16)

- Mesa shader cache **cold** (first request after container relaunch):
  prefill ~1 tok/s (28-29 seconds for 20-50 token prompt)
- Mesa shader cache **warm** (subsequent requests): prefill ~300-560 tok/s
- Generation steady state: **~63 tok/s** (measured, short-medium context)
- Generation at ~25K context (hybrid re-prefill penalty): **~11-12 tok/s**
- TTFT multi-turn at ~500 token history: ~sub-second (prefix still short)
- TTFT multi-turn at ~25K token history: **multi-second** (full re-prefill)

The cold Mesa prefill (1 tok/s) is **not** a model or GPU problem — it is
Mesa compiling SPIR-V → ISA shader pipelines on first use of each unique
batch shape. The `MESA_SHADER_CACHE_DIR` persistence ensures this only
happens once per unique shape. After warmup, prefill is 300-560 tok/s.

### Predicted (Gemma 4 26B-A4B with `--swa-full`, our hardware)

- Generation: 110-160 tok/s steady state (3.8B active params vs ~3B for 35B)
- TTFT on multi-turn at 8000 tokens: **under 1 second** (cache hits)

## Measured benchmarks

All measurements taken 2026-05-16, Qwen3.6-35B-A3B UD-Q4_K_M, q8_0 KV,
65K context, build b8983, Mesa 26.0.5 RADV, R9700 32 GB.

| Test                                                     | Prefill                                   | Decode           | Notes                              |
| -------------------------------------------------------- | ----------------------------------------- | ---------------- | ---------------------------------- |
| A: Short prompt, 22 tok in, ~20 tok out                  | **1 tok/s** (cold) → **297 tok/s** (warm) | 65 tok/s         | Cold = Mesa shader compile         |
| B: Medium prompt, 54 tok in, 512 tok out                 | **2 tok/s** (cold) → **561 tok/s** (warm) | 63 tok/s         |                                    |
| C: Code gen, 43 tok in, 1024 tok out                     | **497 tok/s** (warm)                      | 63 tok/s         |                                    |
| D: Multi-turn turn 1, 30 tok in                          | **1 tok/s** (cold)                        | 63 tok/s         | Cold Mesa                          |
| D: Multi-turn turn 2, 83 tok in (prior history included) | **517 tok/s**                             | 63 tok/s         | Fast because context still short   |
| Live session ~25K ctx                                    | ~250-420 tok/s                            | **~11-12 tok/s** | Hybrid re-prefill at long context  |
| VRAM during inference                                    | —                                         | —                | 23.72 GB / 32 GB (74%) at ~25K ctx |

**Key takeaways:**

- Decode is consistently ~63 tok/s at short-medium context — good, near
  bandwidth ceiling for this model+quant combination
- The cold Mesa compile penalty (1 tok/s prefill) only hits once per unique
  batch shape per container lifecycle; warmed up it disappears completely
- The hybrid re-prefill penalty at long context (11-12 tok/s) is
  architectural — no tuning fixes it, only model switching or MTP (see below)
- 74% VRAM utilization at 25K ctx with q8_0 KV; switching to q4_0 KV +
  131K context brings this to ~29 GB, staying within budget

## MTP speculative decoding

MTP (Multi-Token Prediction) is a speculative decoding technique specific
to models that have MTP head layers baked into the GGUF (currently Qwen3.6
family only). It predicts N draft tokens per step, the main model verifies
them in parallel, and accepts the ones that match — yielding 1.5-1.9×
decode speedup at ~75% acceptance rate with 3 draft tokens.

**Status as of 2026-05-16**: PR [#22673](https://github.com/ggml-org/llama.cpp/pull/22673)
merged to llama.cpp master today. Dedicated MTP GGUFs exist:
`ggml-org/Qwen3.6-35B-A3B-MTP-GGUF`. **Vulkan support for the underlying
PR [#22400](https://github.com/ggml-org/llama.cpp/pull/22400) (required
for hybrid GDN partial seq removal) was incomplete at PR open time** — an
early R9700 tester reported garbage output. Vulkan support may have landed
by merge; needs verification on our hardware.

**Not yet enabled** — waiting for nixpkgs to bump llama.cpp past today's
master, then we can test:

```fish
# Switch hfRepo/hfFile to the MTP GGUF in containers/llm.nix:
hfRepo = "ggml-org/Qwen3.6-35B-A3B-MTP-GGUF";
hfFile = "Qwen3.6-35B-A3B-MTP-UD-Q4_K_M.gguf";  # check repo for exact filename
# Add to extraFlags:
"--spec-type" "draft-mtp" "--spec-draft-n-max" "2"
```

Measured speedups from the PR (RTX 3090, similar bandwidth class):

- Baseline: ~23 tok/s → MTP n=2: ~29 tok/s (1.26×) → MTP n=3: ~42 tok/s (1.85×)
- Prefill is ~50% slower with MTP enabled (known issue, being fixed upstream)
- MTP adds ~2.5 GB VRAM overhead for the draft head context

For our use case (1-2% GPU utilization, interactive chat), MTP n=2 is the
best tradeoff: meaningful decode speedup without excessive prefill regression.

## Open WebUI integration

See `docs/OPENWEBUI.md` for the full Open WebUI recipes (thinking toggle via
custom_params, web search setup, etc.). Key points for the LLM hosting side:

- Open WebUI runs in the same `llm` LXC as llama-server. Talks to
  `http://localhost:8080/v1` (no network hop, no TLS).
- Per-conversation model switching works **within whatever models llama-server
  exposes via `/v1/models`**, which is currently the one active preset.
- Workspace > Models lets you build custom presets (system prompt + custom
  params) on top of the active base model. That's how the
  "Qwen3.6 27B (Thinking)" preset works — same base model, different
  `chat_template_kwargs`.
- Open WebUI's web search is **RAG-style retrieval**, not tool-calling. It
  fetches pages, optionally embeds them, and injects as context **before**
  the model generates. The model never decides to search. See
  `docs/OPENWEBUI.md` for setup.

## opencode integration

See `modules/home/nixvim/default.nix` for the `opencode-llamacpp` home-manager
module. Currently enabled on mountainball, points at `https://llm.r6t.io/v1`.

The integration registers the active model as a provider in
`~/.config/opencode/opencode.json`. Per-model `variants` let you toggle
thinking on/off without changing the active model on the server side
(thinking is per-request via `chat_template_kwargs`, same mechanism as the
Open WebUI workspace preset).

Reality check: as of May 2026, no 32-GB-fitting open-weights model breaks
50% on Aider polyglot. The 60-70% range is 600B+ models (DeepSeek V3.2,
Kimi K2). **Local coding is for fast iteration on bounded tasks** — single
file refactors, lint fixes, test additions, boilerplate. Cross-file
architecture work still wants Claude / GPT-5.

## Should you buy a different GPU?

Honest answer: **no, not for current pain.** The R9700 is performing within
spec.

Measured: 63 tok/s gen on Qwen3.6-35B-A3B UD-Q4_K_M — near the theoretical
bandwidth ceiling for this model+quant combination. There is essentially zero
software headroom to push that number further without MTP or a model change.

What changing GPUs would buy:

- **Single 5090** (~$4,300): 1.52× decode rate, 2.6-3.4× prefill rate on
  the same models. Most of that is imperceptible during interactive chat
  (anything past ~30 tok/s reads faster than humans). Matters for batch /
  agentic tool loops. Pricey.
- **Used 3090 × 2** (~$1,400 total): 48 GB total VRAM enables larger
  models (Llama-3.3-70B Q4 etc.) at the cost of split-mode complexity and
  cross-card PCIe traffic.
- **Used 4090** (~$1,400): less VRAM than R9700, similar bandwidth. Strict
  downgrade for 30B-class workloads.

What costs **$0** and is worth trying first:

- **MTP** (when nixpkgs catches up to 2026-05-16 master): expected 1.5-1.9×
  decode speedup on Qwen3.6 family specifically. Try this before any hardware.
- **Switch to Gemma 4 26B-A4B**: 110-160 tok/s predicted vs 63 tok/s measured
  on the 35B hybrid. Same hardware, same VRAM budget, much faster decode.
  Trade: less quality depth than the 35B hybrid.

Spend the afternoon on MTP or model swapping before considering hardware.

## Quick reference

### Switch active model

```fish
# Edit containers/llm.nix, change `activeModel = models.X;`
python3 containers/build.py llm
python3 containers/relaunch.py llm
```

### Check what's running

```fish
incus exec llm -- systemctl status llama-cpp --no-pager
incus exec llm -- journalctl -u llama-cpp --no-pager -f
incus exec llm -- bash -c 'curl -s http://127.0.0.1:8080/v1/models | head'
```

### Measure performance

```fish
ssh crown 'incus exec llm -- bash -c "curl -s -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H \"Content-Type: application/json\" \
  -d \"{\\\"messages\\\":[{\\\"role\\\":\\\"user\\\",\\\"content\\\":\\\"Reply with one word: ok\\\"}],\\\"max_tokens\\\":50}\""' \
  | python3 -c "import json,sys; t=json.load(sys.stdin)['timings']; \
    print(f'prompt {t[\"prompt_per_second\"]:.0f} tok/s, gen {t[\"predicted_per_second\"]:.1f} tok/s')"
```

### Clean up old cached models

```fish
incus exec llm -- du -sh /var/cache/llama-cpp/models--*/
incus exec llm -- rm -rf /var/cache/llama-cpp/models--<old-org-and-repo>/
```

### Check VRAM use during inference

```fish
ssh crown 'cat /sys/class/drm/card*/device/mem_info_vram_used' \
  | awk '{print $1/1024/1024/1024 " GB"}'
# 32212254720 = 30 GB used, 32 - 30 = 2 GB free
```

### Diagnose "feels slow" complaints

Check the slot timings in journalctl. The relevant line patterns are:

```
prompt eval time =     XXX ms /   YYY tokens (... ms per token,  ZZZ tokens per second)
       eval time =    XXXX ms /   YYY tokens (... ms per token,   ZZ tokens per second)
forcing full prompt re-processing due to lack of cache data
saving prompt with length XXX, total state size = YYY MiB
prompt cache update took XXXXX ms
```

If you see:

- `forcing full prompt re-processing` repeatedly → hybrid attention bug,
  cannot be software-fixed, switch model.
- `prompt cache update took XXXXms` slow → set `cacheRamMiB = 0` for this
  model (already done for hybrid presets).
- Slow `prompt eval` but fast `eval` → Mesa shader cache miss, will warm
  up with use.
- Slow `eval` itself → model is correctly bandwidth-bound, nothing to do
  except switch quant or model.

## Related docs

- `docs/INCUS.md` — LXC architecture, networking, GPU passthrough
- `docs/OPENWEBUI.md` — Open WebUI recipes (thinking, web search)
- `containers/llm.nix` — current model presets and active selection
- `modules/nixos/llama-cpp/default.nix` — module options, baseline flags
- `modules/home/nixvim/default.nix` — opencode integration
