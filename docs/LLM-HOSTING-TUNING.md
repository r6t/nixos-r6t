# LLM Hosting & Tuning on Crown

How the `llm` LXC container hosts local large language models on crown's AMD
Radeon AI Pro R9700, what works well, what's slow and why, and how to swap
between models. Captures lessons learned through May 2026.

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
- [Cold-start vs warm performance](#cold-start-vs-warm-performance)
- [Multi-turn TTFT (the perceived-speed problem)](#multi-turn-ttft-the-perceived-speed-problem)
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

| Component        | Spec                                              |
| ---------------- | ------------------------------------------------- |
| GPU              | AMD Radeon AI Pro R9700                           |
| Architecture     | RDNA 4 / gfx1201 (Navi 48)                        |
| VRAM             | 32 GB GDDR6                                       |
| Memory bandwidth | 640 GB/s                                          |
| PCIe             | Gen 5 x16 (negotiated as Gen 4 x16 on this board) |
| Kernel driver    | in-tree amdgpu                                    |
| Userspace        | Mesa 26.0.5 + RADV ICD                            |

The R9700 has the **best $/VRAM-GB ratio of any consumer-class card in May
2026** — ~$1,600 for 32 GB, vs $4,300 for a 5090 with the same 32 GB. It has
~1/2 the memory bandwidth of a 5090 and ~1/2 the prefill throughput, but for
chat-rate workloads (read: anything where you read the response as it streams)
the difference is mostly imperceptible.

What the R9700 is **not** good for: training, fine-tuning, anything that wants
mature CUDA/PyTorch (ROCm 6/7 still trails CUDA significantly), or multi-GPU
ML where NVLink-class interconnects matter.

What it **is** good for: single-GPU local inference up to ~30B-class models at
reasonable quants. Which is exactly what we use it for.

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

Five model presets are defined in `containers/llm.nix` under `let { models = … }`.
Switch between them with one line: `activeModel = models.<name>;`.

| Preset                 | Architecture   | Active params | Quant / Size        | Multi-turn TTFT            | Decode tok/s (R9700)     | When to use                               |
| ---------------------- | -------------- | ------------- | ------------------- | -------------------------- | ------------------------ | ----------------------------------------- |
| `qwen3-6-27b`          | dense hybrid   | 27B           | Q6_K, 22.5 GB       | **Slow every turn** (3-8s) | ~21                      | Quality fallback, one-shot Q&A            |
| `gemma4-26b-a4b`       | MoE SWA        | 3.8B / 26B    | UD-Q6_K_XL, 21.7 GB | Snappy (req ≥ b8819)       | **~110-160** (predicted) | New chat primary once llama.cpp is bumped |
| `gemma4-31b`           | dense SWA      | 31B           | Q5_K_M, 20.2 GB     | Snappy (req ≥ b8819)       | ~25                      | Deterministic Gemma 4 fallback            |
| `qwen3-coder-30b-a3b`  | MoE standard   | 3.3B / 30B    | UD-Q6_K_XL, 26.3 GB | Snappy                     | ~140-180                 | opencode backend, coding-only             |
| `devstral-small-2-24b` | dense standard | 24B           | UD-Q6_K_XL, 19.4 GB | Snappy                     | ~25-30                   | Mistral coding alternative                |

### Architecture notes

- **`qwen3-6-27b`**: hybrid GatedDeltaNet attention (only 16 of 64 layers
  carry traditional KV). Highest single-shot quality among 32-GB-fitting models
  for general chat per most benchmarks. Native 256K context. Default thinking
  mode (`<think>...</think>` blocks); we set `--reasoning off` at the server
  level and let clients opt-in per-request via `chat_template_kwargs`.

- **`gemma4-26b-a4b`**: MoE with 3.8B active params, alternating local SWA +
  global attention, Shared KV Cache architecture. 256K native context. Tool
  calling, vision (we use `--no-mmproj` for text-only). Optional thinking via
  `chat_template_kwargs.enable_thinking = true`. Per llama.cpp PR
  [#22288](https://github.com/ggml-org/llama.cpp/pull/22288) (merged
  2026-04-24), multi-turn cache reuse works on build ≥ b8819 with
  `--swa-full`. Reporter measured 13× warm prefill speedup.

- **`gemma4-31b`**: Same SWA architecture as the MoE sibling but dense and a
  bit bigger. Lower decode rate (~25 tok/s, dense-bandwidth-bound) but
  deterministic — no MoE routing variance. Fallback if the MoE variant hits
  an unresolved corner case (issue [#21831](https://github.com/ggml-org/llama.cpp/issues/21831)
  reports a separate MoE bug that may or may not be closed by #22288).

- **`qwen3-coder-30b-a3b`**: Standard MoE transformer (NOT hybrid).
  Coding-tuned, no thinking mode (fast tool-call iterations). "Specially
  designed function call format" per the model card — works well with
  opencode. Already in production-ready shape; this is the recommended
  opencode backend.

- **`devstral-small-2-24b`**: Latest dense Mistral coder (Dec 2025 / Feb 2026
  update). Standard transformer, snappy multi-turn, no fancy features.
  Less academic-benchmark-strong than Gemma 4 / Qwen3.6 but tight on
  real-world dev tasks. A/B alternative to `qwen3-coder-30b-a3b`.

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

Estimates for our presets, at their configured context size:

| Preset                                        | Weights | KV @ ctx  | Compute graph | Total | Headroom |
| --------------------------------------------- | ------- | --------- | ------------- | ----- | -------- |
| qwen3-6-27b (Q6_K, 131072 ctx)                | 22.5    | 4.4       | 3.8           | 30.7  | ~0.5     |
| gemma4-26b-a4b (UD-Q6_K_XL, 131072 ctx)       | 21.7    | 3.5 (est) | 3.5 (est)     | 28.7  | ~2.5     |
| gemma4-31b (Q5_K_M, 65536 ctx)                | 20.2    | 5.0 (est) | 3.0 (est)     | 28.2  | ~3.0     |
| qwen3-coder-30b-a3b (UD-Q6_K_XL, 65536 ctx)   | 26.3    | 2.5       | 1.5           | 30.3  | ~0.7     |
| devstral-small-2-24b (UD-Q6_K_XL, 131072 ctx) | 19.4    | 5.0       | 4.0 (est)     | 28.4  | ~3.0     |

Qwen3.6 and Qwen3-Coder run tight — keep an eye on `nvidia-smi`-equivalent
(via `incus exec llm -- ls /sys/class/drm/card*/device/mem_info_vram_used`)
during real use, especially on long contexts. If you OOM, drop context size
or quant.

Gemma 4 26B-A4B has comfortable headroom even at full 128K context, which is
another argument for it as a primary.

### Why we use `--no-mmproj` everywhere

Multimodal projector (vision encoder) adds ~1 GB to VRAM for Qwen3.6,
Mistral-Small-3.1, Gemma 4 etc. We don't use vision in chat or coding
workflows — saving 1 GB lets us run a slightly larger quant or context.
Web search retrieves text, not images, so this doesn't hurt that flow.

If you ever want vision (e.g. paste a screenshot to chat about it), remove
`--no-mmproj` from the model's `extraFlags` and rebuild. Costs ~1 GB VRAM.

### Why we use `q8_0` KV cache, not f16

K and V cache tensors don't need full f16 precision to be accurate — `q8_0`
halves their memory footprint with no measurable quality loss. The fused
flash-attention kernel requires K and V to be the _same_ type, so the only
valid choices are f16/f16 (default) or q8_0/q8_0. Going to q4_0 KV is
possible but degrades long-context generation noticeably.

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
   2026-04-24). The current nixpkgs pin is older — see prerequisites for
   the new presets.

### Measured baseline (Qwen3.6, single-turn warm, our hardware)

- Prompt processing (warm pipeline): ~700-800 tok/s
- Generation (Q6_K, R9700 Vulkan): ~21 tok/s steady state
- Time to first visible token after prompt arrives: ~1.5 seconds for a
  500-token prompt
- TTFT on multi-turn after history grows to 2000 tokens: ~3 seconds
- TTFT on multi-turn after history grows to 8000 tokens: ~12 seconds

### Predicted (Gemma 4 26B-A4B with PR #22288 + `--swa-full`)

- Generation: 110-160 tok/s steady state (active params 3.8B vs 27B
  bandwidth → 6-8× speedup)
- TTFT on multi-turn at 8000 tokens: **under 1 second** (cache hits cover
  most of the history, only the latest user turn needs prefill)

The predicted speedup needs validation once you bump nixpkgs. The current
config has the preset ready; flip activeModel after the version bump.

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

For coding sessions, you'll typically want to switch the server-side active
model to `qwen3-coder-30b-a3b` (standard transformer, fast multi-turn, no
thinking blocks getting in the way of tool calls) before starting a long
opencode session. Switch back after.

Reality check: as of May 2026, no 32-GB-fitting open-weights model breaks
50% on Aider polyglot. The 60-70% range is 600B+ models (DeepSeek V3.2,
Kimi K2). **Local coding is for fast iteration on bounded tasks** — single
file refactors, lint fixes, test additions, boilerplate. Cross-file
architecture work still wants Claude / GPT-5.

## Should you buy a different GPU?

Honest answer: **no, not for current pain.** The R9700 is performing within
spec.

Measured: 21 tok/s gen on Qwen3.6 Q6_K = 92% of the theoretical bandwidth
ceiling (22.7 tok/s from 640 GB/s × 80% utilization / 22.5 GB streamed per
token). There is essentially zero software headroom to push that number on
this specific model.

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

What changing **models** buys you on the R9700 you already own:

- **Switching from Qwen3.6 to Gemma 4 26B-A4B**: expected 6-8× decode rate
  (21 → 110-160 tok/s) AND snappy multi-turn TTFT. **Same hardware, $0.**

Spend the afternoon on the model swap before considering hardware.

If after running Gemma 4 26B-A4B for a week with the prereqs satisfied
(b8819+, `--swa-full`, ASPM=performance kernel param active) the system
still feels slow for your workload, the bottleneck is probably:

- The model quality ceiling at 32 GB (no software fixes that, only larger
  models do)
- llama.cpp upstream still-incomplete work (will land in coming months,
  free updates)

A 5090 would only address the prefill-throughput piece, not the quality
ceiling.

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
