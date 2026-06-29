# LLM Hosting & Tuning

How local large language models are hosted across the R6T infrastructure,
what works well, what's slow and why, and how to swap between models.
Covers two distinct hardware platforms: crown's RTX 5060 Ti 16 GB and
goldenball's Strix Halo APU (Ryzen AI MAX+ 395, 128 GB unified RAM).
Updated June 2026.

**Goldenball runs the ROCmFP4 fork as its primary backend** (compiled from
`pkgs/rocmfp4-llama/package.nix` in this flake) for ~2× decode speedup on
the Qwen3.6-35B-A3B-MTP model vs stock Vulkan. See
[Goldenball: ROCmFP4 setup](#goldenball-rocmfp4-setup) for the full
pipeline (build → quantize → deploy).

## Contents

- [Hardware overview](#hardware-overview)
- [Crown: RTX 5060 Ti 16 GB](#crown-rtx-5060-ti-16-gb)
- [Goldenball: Strix Halo (Ryzen AI MAX+ 395)](#goldenball-strix-halo-ryzen-ai-max-395)
- [GPU backend choice — crown (CUDA over Vulkan/ROCm)](#gpu-backend-choice--crown-cuda-over-vulkanrocm)
- [GPU backend choice — goldenball (Vulkan vs ROCm vs ROCmFP4 vs MLX)](#gpu-backend-choice---goldenball-vulkan-vs-rocm-vs-rocmfp4-vs-mlx)
- [The model architecture trap (hybrid vs SWA vs standard)](#the-model-architecture-trap-hybrid-vs-swa-vs-standard)
- [Crown: model presets and VRAM budgeting](#crown-model-presets-and-vram-budgeting)
- [Goldenball: model presets and VRAM budgeting](#goldenball-model-presets-and-vram-budgeting)
- [ROCmFP4 on Strix Halo](#rocmfp4-on-strix-halo)
- [MLX Engine ROCm on Strix Halo](#mlx-engine-rocm-on-strix-halo)
- [MTP speculative decoding](#mtp-speculative-decoding)
- [vLLM on Strix Halo](#vllm-on-strix-halo)
- [Switching models](#switching-models)
- [Multi-model serving (router mode)](#multi-model-serving-router-mode)
- [llama-server tuning flags](#llama-server-tuning-flags)
- [KV cache quantization](#kv-cache-quantization)
- [Cold-start vs warm performance](#cold-start-vs-warm-performance)
- [Multi-turn TTFT (the perceived-speed problem)](#multi-turn-ttft-the-perceived-speed-problem)
- [Open WebUI integration](#open-webui-integration)
- [opencode integration](#opencode-integration)
- [Quick reference](#quick-reference)

---

## Hardware overview

Two distinct systems serve LLM inference, with very different capabilities:

|                  | Crown                                 | Goldenball                                                                                |
| ---------------- | ------------------------------------- | ----------------------------------------------------------------------------------------- |
| GPU              | NVIDIA GeForce RTX 5060 Ti 16 GB      | AMD Radeon 8060S (iGPU, gfx1151)                                                          |
| Architecture     | Blackwell (sm_120)                    | RDNA 3.5                                                                                  |
| GPU memory       | 16 GB GDDR7                           | ~104 GB visible unified (128 GB system RAM, shared with CPU)                              |
| Memory bandwidth | ~288 GB/s                             | ~256 GB/s (LPDDR5X, 1000 MHz)                                                             |
| PCIe             | PCIe 5.0 x16                          | PCIe 4.0 x16 (APU internal)                                                               |
| Primary backend  | CUDA                                  | ROCmFP4 fork (HIP via custom build) with Vulkan fallback                                  |
| Status           | GPU installed, **no model setup yet** | **Live**: Qwen3.6-35B-A3B-MTP ROCmFP4 STRIX_LEAN, ~50-71 tok/s decode (measured Jun 2026) |

The RTX 5060 Ti is a consumer Blackwell card (Ada Lovelace successor). The
Strix Halo APU is an AMD desktop-class APU with ~25 TOPS NPU and an 8-CU
RDNA 3.5 iGPU, designed for thin-and-light and small-form-factor desktops
with massive unified memory.

---

## Crown: RTX 5060 Ti 16 GB

| Component               | Spec                             |
| ----------------------- | -------------------------------- |
| GPU                     | NVIDIA GeForce RTX 5060 Ti 16 GB |
| Architecture            | Blackwell / sm_120               |
| VRAM                    | 16 GB GDDR7                      |
| Memory bandwidth        | ~288 GB/s (est.)                 |
| PCIe                    | Gen 5 x16                        |
| CUDA compute capability | 12.0 (sm_120)                    |

The RTX 5060 Ti is installed on crown and serves the `llm` LXC through a
CUDA-native OpenAI-compatible backend. Keep this container GPU-only: if CUDA is
unavailable, the service should fail closed rather than falling back to CPU
inference.

---

## Goldenball: Strix Halo (Ryzen AI MAX+ 395)

| Component          | Spec                                                                |
| ------------------ | ------------------------------------------------------------------- |
| GPU                | Radeon 8060S (iGPU)                                                 |
| Architecture       | RDNA 3.5 / gfx1151                                                  |
| Unified RAM        | 128 GB LPDDR5X (CPU + GPU shared)                                   |
| GPU-visible memory | ~104 GB (reserved for system/NPU)                                   |
| Memory bandwidth   | ~256 GB/s (fixed 1000 MHz clock)                                    |
| NPU                | XDNA 2, ~25 TOPS                                                    |
| Kernel driver      | in-tree amdgpu (RADV for Vulkan)                                    |
| Known issues       | DCN 3.5.1 `flip_done` display freeze, USB4 PCIe cascade, GPU ENOMEM |

See `docs/GOLDENBALL_FREEZES.md` for Strix Halo freeze troubleshooting.

---

## GPU backend choice — crown (CUDA over Vulkan/ROCm)

On crown's RTX 5060 Ti, **CUDA is the clear choice** — NVIDIA's proprietary
stack is years ahead of open alternatives on NVIDIA hardware:

- **Best performance** — CUDA kernels are highly optimized for NVIDIA GPUs
- **TensorRT-LLM support** — NVIDIA's fastest path for Blackwell serving
- **Triton / FlashAttention** — cutting-edge kernels (FA3, etc.)
- **Tensor Cores** — dedicated FP4/FP8/INT8 compute (Blackwell has fourth-gen)
- **Ecosystem** — PyTorch, TensorRT-LLM, vLLM, llama.cpp CUDA, and MLX all
  support CUDA first

When setting up crown's llm container, use TensorRT-LLM or another CUDA-native
backend rather than trying Vulkan/ROCm. llama.cpp CUDA is retained for reference,
but it is no longer the preferred crown backend after repeated long-prefill
driver failures on RTX 5060 Ti.

Required for CUDA path in the crown LXC:

- Incus GPU passthrough exposes `CUDA0`
- Docker inside the LXC with `hardware.nvidia-container-toolkit.enable = true`
- NVIDIA TensorRT-LLM release image from NGC for the primary service
- Incus mounts versioned NVIDIA driver libraries into `/usr/lib64`; the
  container creates `libcuda.so.1` and `libnvidia-ml.so.1` SONAME symlinks
- `docker-trtllm.service` starts `trtllm-serve` with explicit NVIDIA CDI
  (`--device=nvidia.com/gpu=all`); generic `--gpus=all` tried to resolve a
  missing AMD CDI spec inside the LXC before reaching NVIDIA
- `ExecStartPre` must verify `/dev/nvidia0`, `/dev/nvidiactl`, and
  `/usr/lib64/libcuda.so.1` exist before Docker starts the model server

---

## GPU backend choice — goldenball (Vulkan vs ROCm vs ROCmFP4 vs MLX)

Strix Halo has a fragmented but maturing ecosystem. Four main backends compete:

### 1. Vulkan (RADV / llama.cpp) — the safe default

The traditional path, identical to what the R9700 used (same RDNA family):

**Pros:**

- Most mature, most tested
- Works out of the box with Mesa + RADV
- No ROCm install needed
- MTP support in llama.cpp b9213+ (Lemonade v10.5.1+)

**Cons:**

- Slower than CUDA on comparable hardware (no Tensor Cores equivalent)
- GATED_DELTA_NET Vulkan ops have crash bugs ([llama.cpp #20515](https://github.com/ggml-org/llama.cpp/issues/20515))
- `vk::DeviceLostError` at medium context (65-80K tokens) on some models
- Vulkan AMDVLK crashes under sustained MTP + tool-calling ([lemonade #1971](https://github.com/lemonade-sdk/lemonade/issues/1971))

**Recommended env vars:**

- `RADV_PERFTEST=nogttspill` — prevents weight spilling from VRAM to GTT
- `MESA_SHADER_CACHE_DIR=/var/cache/llama-cpp/mesa-shaders` — persist pipeline cache

### 2. ROCm (llama.cpp ROCm build) — improving

ROCm 7.x on Strix Halo via TheROCk (portable ROCm):

**Pros:**

- Direct AMD GPU compute, no Vulkan abstraction layer
- TheROCk makes installation portable (no system ROCm needed)
- Supported on gfx1151 by Lemonade's backend detection ([PR #2093](https://github.com/lemonade-sdk/lemonade/pull/2093))

**Cons:**

- ROCm on iGPU vs dGPU has different tuning needs
- Less community data than CUDA
- ROCmFP4 (see below) is currently a fork, not upstream

### 3. ROCmFP4 — the speed king (experimental)

[rocmfp4-llama](https://github.com/charlie12345/rocmfp4-llama) — custom 4-bit
format specifically optimized for Strix Halo. Reported results on Strix Halo
395+ with 128 GB unified RAM:

| Model                                  | Backend | Context | Decode                                          |
| -------------------------------------- | ------- | ------- | ----------------------------------------------- |
| Qwen3.6 35B A3B MTP ROCmFP4 STRIX_LEAN | ROCm0   | 262144  | **104.4 tok/s** short, **89.3 tok/s** sustained |
| Qwen3.6 27B MTP ROCmFP4 STRIX_LEAN     | ROCm0   | 262144  | **33.6 tok/s** short, **28.0 tok/s** sustained  |

**Pros:**

- 2-4× faster than Vulkan llama.cpp for equivalent models
- HumanEval+ scores above vanilla Q8 baseline
- Tensor-aware presets preserve quality on sensitive tensors
- Built-in MTP regression guards

**Cons:**

- Experimental research build — not upstream llama.cpp
- Requires building a fork (`scripts/build-strix-rocmfp4-mtp.sh`)
- Results are hardware/driver/model/prompt sensitive
- No official GGUF quantization presets available yet
- Needs `HSA_OVERRIDE_GFX_VERSION=11.5.1` and `GGML_HIP_ENABLE_UNIFIED_MEMORY=1`

**Status as of June 2026:** Active development, 33 GitHub stars. A Lemonade
integration request was filed ([#2089](https://github.com/lemonade-sdk/lemonade/issues/2089), Jun 3).
For goldenball's use case, this is the highest-potential path but also the
riskiest — expect to troubleshoot.

### 4. MLX Engine ROCm — the dark horse

[lemon-mlx-engine](https://github.com/lemonade-sdk/lemon-mlx-engine) — Apple's
MLX framework ported to AMD ROCm. Pure C++ static binary, no Python/Torch.

Head-to-head benchmarks on Strix Halo 395+ / 128 GB unified:

| Model           | MLX tok/s | vLLM tok/s | Vulkan llama.cpp |
| --------------- | --------- | ---------- | ---------------- |
| Qwen3-0.6B 4bit | **151.2** | 116.7      | 82.5             |
| Qwen3-4B 4bit   | **46.9**  | 25.4       | —                |
| Qwen3-8B 4bit   | **21.7**  | 12.3       | —                |
| Phi-4-mini 4bit | **38.3**  | 25.1       | —                |

**Pros:**

- 50+ LLM architectures (Llama, Qwen, Gemma, DeepSeek, etc.)
- HuggingFace native — no GGUF conversion needed
- Cold start in seconds (vs minutes for vLLM)
- 83% faster than Vulkan on smaller models
- Latest release b1037-stable (Jun 5, 2026 — today)
- No Python runtime, no Triton JIT, no Torch dependency
- KV cache quantization support (`--kv-bits 4/8`)

**Cons:**

- Uses MLX's own 4-bit/8-bit quantization, not standard GGUF
- Not yet integrated into Lemonade as a selectable backend (PR #1646 closed)
- Standalone binary only — no packaging for NixOS yet
- Smaller community than llama.cpp

**Status:** Standalone binary exists and works. A Lemonade integration PR was
closed as abandoned. Worth watching — could be the simplest path for
goldenball if/when it gets packaged.

### Recommendation for goldenball

**ROCmFP4 is deployed and active** — the primary backend for the 35B-MTP model.
For large models (70B+), the 128 GB unified RAM enables configurations impossible
on crown's 16 GB. For quick experiments with smaller models, MLX Engine is
compelling. For coding-heavy workloads, consider switching to a standard
transformer (Qwen3-Coder, Devstral) for faster multi-turn via KV cache reuse.

---

## The model architecture trap (hybrid vs SWA vs standard)

This is the single most important thing to understand for chat-speed
perception. It is not about quality, not about quant, not about the GPU. It
is about how the model's attention layers handle the KV cache.

### Three categories

| Category                 | Examples                                                               | Partial KV sequence removal                                | Multi-turn cache reuse on llama.cpp | Feel                         |
| ------------------------ | ---------------------------------------------------------------------- | ---------------------------------------------------------- | ----------------------------------- | ---------------------------- |
| **Hybrid attention**     | Qwen3.5, Qwen3.6, Qwen3-Next, RWKV, Mamba/Jamba                        | Not supported                                              | Permanently disabled                | Slow every turn              |
| **SWA + global**         | Gemma 4 series                                                         | Supported, **only on llama.cpp ≥ b8819 with `--swa-full`** | Works on recent builds              | Snappy when configured right |
| **Standard transformer** | Qwen3-Coder dense MoE, Mistral / Devstral, Llama, most everything else | Supported                                                  | Works                               | Snappy                       |

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

---

## Crown: model presets and VRAM budgeting

### RTX 5060 Ti 16 GB — VRAM budgeting

GPU VRAM: **16 GB**. The budget constraint is:

```
weights + KV_cache + compute_graph ≤ ~15.5 GB
```

This is a **hard cap** — unlike goldenball's 128 GB unified RAM, you cannot
overflow to system memory. Models that exceed 16 GB will OOM.

Measured/validated llama.cpp operating points on crown:

| Model     | Quant  | Context | KV  | Prompt cache | Notes                                      |
| --------- | ------ | ------- | --- | ------------ | ------------------------------------------ |
| Qwen3-14B | Q4_K_M | 4K      | f16 | off          | Current conservative candidate             |
| Qwen3-14B | Q4_K_M | 16K     | f16 | off          | Starts, but long prefill crashed CUDA      |
| Qwen3-14B | Q4_K_M | 32K     | f16 | on           | Starts, but long prompt reuse crashed CUDA |

Follow-up testing showed prompt cache was not the root cause: with 16K and
`--cache-ram 0`, a larger prefill still crashed in
`ggml_cuda_mul_mat_q`/`mmq.cu` and the host driver lost the GPU. Removing forced
MMQ moved the failure to the generic CUDA matmul path, still around the 7K-token
prefill range. Do not force MMQ on crown; keep context and prefill batching
conservative, and disable CUDA fusion until the NVIDIA/llama.cpp Blackwell path
is stable.

Current TensorRT-LLM candidate on crown:

| Backend      | Model               | Quant | Context | Notes                                       |
| ------------ | ------------------- | ----- | ------- | ------------------------------------------- |
| TensorRT-LLM | nvidia/Qwen3-8B-FP8 | FP8   | 8K      | Primary safe candidate, needs reboot retest |

The TensorRT-LLM container uses NVIDIA's pinned NGC release image and serves
OpenAI-compatible API traffic on port 8080 for Open WebUI. This avoids the
current insecure `pkgs.vllm` package. Crown has only 16 GB VRAM.
`Qwen/Qwen3.6-35B-A3B-FP8` downloaded and reached model load, but OOMed before
KV cache creation on the RTX 5060 Ti and destabilized CUDA.
`nvidia/Qwen3-14B-NVFP4` fit far enough to run TensorRT warmup, but failed in
the NVFP4/CUTLASS path (`Failed to initialize cutlass FP4 gemm`, TMA descriptor 719) and again wedged the driver. Avoid FP4/NVFP4 on this card/driver/image for
now. The active TensorRT candidate is a smaller FP8 Qwen3 checkpoint at 8K
context with conservative KV and batching limits.

Old planning presets:

| Preset              | Architecture   | Active params | Quant / Size   | VRAM fit                                 | When to use                             |
| ------------------- | -------------- | ------------- | -------------- | ---------------------------------------- | --------------------------------------- | ------------------------ |
| `qwen3.6-35b-a3b`   | MoE hybrid GDN | ~3B / 35B     | Q4_K_M, ~20 GB | **NO** — too big for 16 GB               | —                                       |
| `qwen3.5-122b-a10b` | MoE hybrid GDN | ~10B / 122B   | Q4_K_M, ~65 GB | **NO** — way too big                     | —                                       |
| `qwen3-30b-a3b`     | MoE standard   | ~3B / 30B     | Q4_K_M, ~18 GB | **TIGHT** — barely fits at small context | Snappy multi-turn, standard transformer |
| `qwen3.5-32b`       | dense hybrid   | 32B           | Q4_K_M, ~19 GB | **NO** — too big                         | —                                       |
| `qwen3.6-30b-a3b`   | MoE standard   | ~3B / 30B     | Q4_K_M, ~18 GB | **TIGHT**                                | Same as 30B above                       |
| `qwen3-30b-coder`   | MoE standard   | ~3B / 30B     | Q4_K_M         | ~18 GB                                   | **TIGHT**                               | Coding-focused variant   |
| `qwen3-4b`          | dense          | 4B            | Q4_K_M         | ~2.7 GB                                  | Comfortable fit                         | Fast, small context work |
| `qwen3-8b`          | dense          | 8B            | Q4_K_M         | ~5.5 GB                                  | Comfortable fit                         | Medium-quality chat      |
| `llama3.3-70b`      | dense          | 70B           | Q4_K_M         | ~38 GB                                   | **NO** — too big                        | —                        |

**Practical models for 16 GB VRAM:**

The 16 GB limit is tight for 30B-class models. Realistic llama.cpp/GGUF-era
planning options:

| Model         | Quant  | Weights | Headroom for KV @ 32K                        | Notes                                                 |
| ------------- | ------ | ------- | -------------------------------------------- | ----------------------------------------------------- |
| Qwen3-8B      | Q4_K_M | ~5.5 GB | ~10 GB (4x larger KV than crown's 35B setup) | Comfortable, fast                                     |
| Qwen3-14B     | Q4_K_M | ~9 GB   | ~6.5 GB                                      | Fits VRAM, but llama.cpp CUDA crashed on long prefill |
| Qwen3-32B     | Q4_K_M | ~19 GB  | **NO** — won't fit                           | Need Q4_K_S or accept ~3K context                     |
| Qwen3-30B-A3B | Q4_K_S | ~14 GB  | ~2 GB                                        | Tight but possible                                    |
| Llama-3.1-8B  | Q4_K_M | ~5.2 GB | ~10 GB                                       | Standard transformer, fast                            |

**Key difference from crown's R9700:** The 16 GB on the 5060 Ti is a hard
limit (dedicated VRAM), not shared with CPU like goldenball's unified memory.
You cannot run 70B-class models. But CUDA gives much higher tokens/sec per GB
than AMD Vulkan.

### Recommended approach for crown

Since crown's GPU is CUDA, the setup path differs from goldenball:

1. **Use TensorRT-LLM + CUDA** for the always-on OpenAI-compatible service
2. **Use 14B-class Qwen3 first**; only revisit larger MoE/coder models after the TensorRT path is stable
3. **Use TabbyAPI/Exllama only as a clean fallback** if TensorRT-LLM is too rough
4. **Keep llama.cpp CUDA as a fallback only** after the repeated long-prefill crashes
5. **Don't try ROCm/Vulkan** — CUDA is orders of magnitude better on NVIDIA

---

## Goldenball: model presets and VRAM budgeting

### Strix Halo 128 GB unified — VRAM budgeting

GPU-visible memory: **~104 GB** (system/NPU reservation). Unlike crown's
16 GB hard cap, this is shared with the CPU — the OS and desktop still need
RAM, but you can push models far larger than any dedicated GPU.

Active presets in `llm-config.nix` (ROCmFP4 deployed, Vulkan baseline available):

| Preset                          | Architecture   | Active params | Quant / Size  | VRAM      | When to use                                              |
| ------------------------------- | -------------- | ------------- | ------------- | --------- | -------------------------------------------------------- |
| `qwen3-6-35b-a3b-rocmfp4-lean`  | MoE hybrid GDN | ~3B / 35B     | ROCmFP4 lean  | ~19 GB    | **Active**: ROCmFP4 STRIX_LEAN, MTP-3, reasoning on      |
| `qwen3-6-35b-a3b-rocmfp4-strix` | MoE hybrid GDN | ~3B / 35B     | ROCmFP4 strix | ~21 GB    | Higher quality fallback (5-10% slower)                   |
| `qwen3-6-35b-a3b-mtp`           | MoE hybrid GDN | ~3B / 35B     | UD-Q4_K_XL    | ~23 GB    | **Vulkan baseline** — MTP-2, reasoning off, ~22-45 tok/s |
| `qwen3-6-27b`                   | dense hybrid   | 27B           | Q6_K          | ~22.5 GB  | Higher quant fallback                                    |
| `qwen3.5-122b-a10b`             | MoE hybrid GDN | ~10B / 122B   | Q4_K_M        | ~65-70 GB | **Huge context** (256K+), lower speed per token          |
| `qwen3-8b`                      | dense          | 8B            | Q4_K_M        | ~5.5 GB   | Fast chat, small tasks                                   |
| `gemma4-26b-a4b`                | MoE SWA        | 3.8B / 26B    | UD-Q6_K_XL    | ~21.7 GB  | Fast multi-turn (standard SWA, not hybrid)               |
| `qwen3-57b-a14b`                | MoE standard   | ~14B / 57B    | Q6_K          | ~47 GB    | Standard MoE, KV cache reuse between turns               |
| `qwen3-32b`                     | dense          | 32B           | Q8_0          | ~34 GB    | Deterministic, no MoE variance, 64K context              |
| `devstral-small-2-24b`          | dense standard | 24B           | UD-Q6_K_XL    | ~20 GB    | Coding-focused, 131K context, standard transformer       |

The 128 GB unified RAM is the killer feature here — you can run models that
require more VRAM than any single dedicated GPU offers. The tradeoff is
bandwidth: ~256 GB/s vs the 5060 Ti's ~288 GB/s (roughly similar, but unified
memory has extra latency from the CPU-GPU path).

---

## ROCmFP4 on Strix Halo

### What is ROCmFP4?

A custom 4-bit weight format for GGUF models, built for AMD Strix Halo:

- **Q4_0_ROCMFP4** (dual-scale, 4.50 bits/weight) — quality-focused
- **Q4_0_ROCMFP4_FAST** (single-scale, 4.25 bits/weight) — speed-focused
- Codebook10 4-bit value table with unsigned E4M3 half-scale semantics
- ROCm/HIP kernels for vector ops, dequantization, and FlashAttention
- Vulkan shader support for decode and MMQ (for non-ROCm path)
- Tensor-aware presets that mix ROCmFP4 with higher-precision tensors

### Reported results from the fork (Strix Halo 395+, 128 GB unified)

From the fork's own benchmark documentation. Single-author setup; goldenball
numbers (next section) are independent measurements on identical hardware.

| Model                                                      | Context | Decode                                          |
| ---------------------------------------------------------- | ------- | ----------------------------------------------- |
| Qwen3.6-35B-A3B-MTP ROCmFP4 STRIX_LEAN, n-max=3, reason on | 262144  | **104.3 tok/s** short, **80.1 tok/s** sustained |
| Qwen3.6-35B-A3B-MTP ROCmFP4 STRIX_LEAN, n-max=2, reason on | 262144  | 92.6 tok/s short, **80.6 tok/s** sustained      |
| Qwen3.6-27B-MTP ROCmFP4 STRIX_LEAN, ROCm0                  | 262144  | 99.8 tok/s prompt / 27.6 tok/s decode           |
| Qwen3.6-27B-MTP UD-Q5_K_XL, ROCm0 (baseline)               | 262144  | 47.9 tok/s prompt / 15.7 tok/s decode           |

That's a ~76% decode speedup vs Q5_K on the 27B model, same binary.

### Measured results on goldenball (2026-06-07)

Live measurements on goldenball with the active config: ROCmFP4 STRIX_LEAN,
gfx1151, ROCm0 backend (FORCE_MMQ=1), `--reasoning on`, `--spec-type
draft-mtp --spec-draft-n-max 3`, q8 main KV + q4 draft KV, ubatch=512,
`-c 262144`, `HSA_OVERRIDE_GFX_VERSION=11.5.1`,
`GGML_HIP_ENABLE_UNIFIED_MEMORY=1`. All API requests via OpenAI-compat
`/v1/chat/completions`. Model has been running continuously 17+ hours
(process RSS: 45.5 GB), fully warmed.

| Test                                 | Prompt tok/s | Decode tok/s | Draft acceptance |
| ------------------------------------ | -----------: | -----------: | ---------------: |
| Short prompt (17 tok) + 50 tok reply |           67 |        49-61 | 56-73% (avg 65%) |
| Medium prompt (85 tok) + 256 tok     |          307 |        61-62 |              80% |
| Code gen (41 tok) + 512 tok          |          197 |           54 |              67% |
| Long output (56 tok) + 1024 tok out  |          249 |           52 |                — |
| Long prompt (1399 tok) + 256 reply   |          681 |           53 |                — |
| Burst test: 3× short replies (warm)  |            — |        67-71 |             ~80% |

**llama-bench raw GPU performance** (no warmup, ubatch=512):

| Test  |       tok/s |
| ----- | ----------: |
| pp1   | 38.4 ± 16.5 |
| pp128 |  45.2 ± 1.0 |
| pp512 |  45.7 ± 0.3 |
| tg128 |  43.2 ± 0.4 |
| tg512 |  45.7 ± 0.3 |
| tg1   |  39.4 ± 4.0 |

**ubatch comparison** (decode tg128, --no-warmup):

| ubatch | Decode (tg128) |
| ------ | -------------: |
| 512    |     43.2 ± 0.4 |
| 2048   |     26.2 ± 1.8 |

ubatch=512 is **65% faster** than ubatch=2048. Current config is optimal.

**Where we are vs the fork's published numbers:**

The fork reports 80-104 tok/s burst / 70-89 tok/s sustained for the same
model + flags. Goldenball measures ~50-71 tok/s decode via API, ~43 tok/s
raw GPU via llama-bench. That's **~50% below fork targets**.

Contributing factors:

- **MTP draft acceptance**: 56-80% avg (~65%) vs fork's 70-90%. Lower
  acceptance → fewer free tokens → less MTP speedup.
  Acceptance correlates with context: 56% (short) → 80% (medium) → 67% (code/long).
- **Host environment**: kernel 7.0.10 + RADV nixpkgs-unstable; fork uses
  unspecified Framework Desktop config.
- **DCN 3.5.1 stability mitigations**: ubatch=512 gives idle windows to the
  display engine. This is a deliberate tradeoff for system stability.
- **Bandwidth ceiling**: ~256 GB/s LPDDR5X is the hard limit. The 35B MoE
  model (~3B active params) is bandwidth-bound; ROCmFP4 quants don't change
  the fundamental constraint.
- **Unified memory latency**: CPU+GPU share LPDDR5X. No PCIe round-trip
  penalty (vs discrete GPU), but higher latency than dedicated VRAM.
  Model weights in GTT via `GGML_HIP_ENABLE_UNIFIED_MEMORY=1`.

**Memory layout (measured during inference):**

- Process VmRSS: 45.5 GB (model weights + working memory in system RAM)
- Model file size: 17.73 GiB
- GPU-visible VRAM: 4 GB carve-out (essentially unused)
- Actual memory used: ~25 GB via unified memory (GTT path)
- The 4 GB hardware "VRAM" partition on Strix Halo is unused; unified memory
  is doing the work via `GGML_HIP_ENABLE_UNIFIED_MEMORY=1`

### Vulkan baseline before ROCmFP4 (measured, for comparison)

For reference, the stock Vulkan llama.cpp baseline goldenball ran with the
same model architecture (UD-Q4_K_XL via Vulkan, b9190 + MTP n-max=2,
`--reasoning off`, no ROCm path):

| Test                      | Tok/s         |
| ------------------------- | ------------- |
| Decode, short prompt      | 45 (with MTP) |
| Decode, real chat replies | 22-28         |
| Prompt prefill, fresh     | 88-360        |
| MTP draft acceptance      | 86%           |

**ROCmFP4 measured uplift on goldenball:**

- Decode (short): 45 → 70 tok/s = **1.55×**
- Decode (sustained): 22-28 → 50-53 tok/s = **~2×**
- Prefill (long): 360 → 681 tok/s = **1.9×**

### Build pipeline (Nix-native, on goldenball)

The fork is built as a flake-output package (`pkgs/rocmfp4-llama/package.nix`)
and selected via `mine.llama-cpp.rocmfp4 = true` in the host config. Both HIP
and Vulkan backends are compiled into the same binary so runtime can fall back
to Vulkan via `-dev Vulkan0` if HIP misbehaves.

```fish
# 1. nixos-rebuild builds the package automatically (~15-30 min first time,
#    cached afterwards). On a fresh switch:
sudo nixos-rebuild switch --flake .#goldenball

# 2. Quantize the BF16 source into a ROCmFP4 GGUF (one-time, ~30-60 min).
#    Downloads 71 GB BF16 from ggml-org; writes 19-21 GB GGUF to
#    /var/lib/llama-cpp-models/. Auto-deletes BF16 unless --keep-bf16.
./scripts/quantize-rocmfp4-strix.fish --profile lean
# Optionally also do:
./scripts/quantize-rocmfp4-strix.fish --profile strix --keep-bf16

# 3. Set the active model and rebuild + restart.
#    Edit hosts/goldenball/llm-config.nix:
#      activeModel = models.qwen3-6-35b-a3b-rocmfp4-lean;
sudo nixos-rebuild switch --flake .#goldenball
systemctl restart llama-cpp

# 4. Confirm the right binary + model loaded:
systemctl status llama-cpp --no-pager
curl -s http://127.0.0.1:8080/v1/models | jq '.data[].id'
# Expect: "qwen3.6-35b-a3b-mtp-rocmfp4-lean"
```

### Available presets in `llm-config.nix`

| Preset                                  | Profile    | Quant size | Backend | Expected decode              |
| --------------------------------------- | ---------- | ---------- | ------- | ---------------------------- |
| `qwen3-6-35b-a3b-rocmfp4-lean`          | STRIX_LEAN | ~19 GB     | ROCm0   | 50-71 tok/s (measured)       |
| `qwen3-6-35b-a3b-rocmfp4-strix`         | STRIX      | ~21 GB     | ROCm0   | 5-10% slower, higher quality |
| `qwen3-6-35b-a3b-mtp` (Vulkan baseline) | UD-Q4_K_XL | 23 GB      | Vulkan0 | 22-45 tok/s (measured)       |

To compare ROCmFP4 vs Vulkan, switch `activeModel` in `llm-config.nix` AND
flip `rocmfp4 = true` ↔ `vulkan = true` in `configuration.nix`. Both are
mutex.

### MTP recipe (tested fork-published values)

Goldenball's `qwen3-6-35b-a3b-rocmfp4-{lean,strix}` presets ship with the
fork's recommended draft-MTP config:

- `--spec-type draft-mtp`
- `--spec-draft-n-max 3` (sustained-best for reasoning-on)
- `--spec-draft-n-min 0`
- `--spec-draft-p-min 0.0`
- `--spec-draft-p-split 0.10`
- `--spec-draft-type-k q4_0` / `--spec-draft-type-v q4_0`
- `--reasoning on`
- `--cache-type-k q8_0` / `--cache-type-v q8_0` (main KV)

Why these values: per the fork's reasoning-on n-max sweep, `n-max=3` gave
80.1 tok/s sustained / 104.3 burst — the same row as the published headline
numbers. `n-max=2` gave very similar sustained (80.6) with smaller bursts.

### Caveats

- **Experimental research build.** Do not treat numbers as upstream claims.
- Pinned to commit `1faa48eef…` of `mtp-rocmfp4-strix`. Bump `rev` + `hash`
  in `pkgs/rocmfp4-llama/package.nix` to track the branch.
- Build closure is ~3-5 GB (HIP runtime, hipblas, rocblas, plus Vulkan
  shaders).
- Quantized GGUFs in `/var/lib/llama-cpp-models/` are NOT in
  `/nix/store`. They survive `nix-collect-garbage` but must be re-quantized
  on a fresh disk. The directory is provisioned by `systemd.tmpfiles.rules`
  in `hosts/goldenball/configuration.nix` (owned by `r6t:users` mode 0755
  so the user can write quants and the DynamicUser service can read them).
  The quantization script is idempotent.
- The required `HSA_OVERRIDE_GFX_VERSION=11.5.1` and
  `GGML_HIP_ENABLE_UNIFIED_MEMORY=1` env vars are set automatically by the
  llama-cpp module when `rocmfp4 = true`.

---

## MLX Engine ROCm on Strix Halo

### What is it?

MLX Engine (Apple's MLX framework) ported to AMD ROCm. Pure C++ static
binary — no Python, no Torch, no Triton JIT. Latest release: b1037-stable
(Jun 5, 2026).

### Benchmarks on Strix Halo 395+ / 128 GB unified

| Model           | MLX tok/s | vLLM tok/s | Vulkan llama.cpp |
| --------------- | --------- | ---------- | ---------------- |
| Qwen3-0.6B 4bit | **151.2** | 116.7      | 82.5             |
| Qwen3-4B 4bit   | **46.9**  | 25.4       | —                |
| Qwen3-8B 4bit   | **21.7**  | 12.3       | —                |
| Phi-4-mini 4bit | **38.3**  | 25.1       | —                |

### Key features

- 50+ LLM architectures (Llama, Qwen, Gemma, Phi, DeepSeek, Mistral, etc.)
- 12 VLM architectures (Qwen2-VL, Gemma3, Pixtral, etc.)
- HuggingFace native — auto-downloads models, no GGUF conversion
- OpenAI-compatible API server on configurable port
- KV cache quantization (`--kv-bits 4/8`)
- Cold start in seconds (vs minutes for vLLM)

### How to use (standalone)

```bash
# Interactive chat
./chat mlx-community/Qwen3-4B-4bit --system-prompt "You are a coding assistant"

# API server (auto-load mode)
./server --host 0.0.0.0 --port 9090 --max-loaded 3

# Server with pre-loaded model
./server mlx-community/Qwen3.5-0.8B-4bit --no-think --kv-bits 4
```

### OpenAI API compatibility

```bash
curl http://localhost:9090/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "mlx-community/Qwen3-4B-4bit",
       "messages": [{"role": "user", "content": "Hello!"}]}'
```

### NPU usage (bonus)

MLX can also run models on the Strix Halo NPU (XDNA 2, 25 TOPS)
concurrently with the GPU:

| Model            | NPU tok/s |
| ---------------- | --------- |
| Qwen3-0.6B-FLM   | 94.4      |
| Llama-3.2-1B-FLM | 61.7      |
| Qwen3-8B-FLM     | 10.8      |

This is unique to MLX — you can run always-on small models on the NPU
while the GPU handles large models.

### Integration status

- Standalone binary: **working** (lemon-mlx-engine repo)
- Lemonade backend: PR #1646 **closed as abandoned**
- NixOS packaging: **not available** — manual install required
- Worth watching — could be the simplest path for goldenball

---

## MTP speculative decoding

MTP (Multi-Token Prediction) is a speculative decoding technique specific
to models that have MTP head layers baked into the GGUF (currently Qwen3.6
family and Qwen3.5 122B-A10B). It predicts N draft tokens per step, the main
model verifies them in parallel, and accepts the ones that match — yielding
1.5-1.9× decode speedup at ~75% acceptance rate with 3 draft tokens.

### Status on crown (RTX 5060 Ti, CUDA)

llama.cpp CUDA support for MTP on hybrid GDN models is **untested on this
hardware** — no benchmarks exist. The RTX 5060 Ti is Blackwell (sm_120),
which is newer than the cards MTP was validated on. CUDA path should be
preferred if MTP works; the lack of hybrid GDN Vulkan support on Strix Halo
makes CUDA even more valuable if available.

### Status on goldenball (Strix Halo)

MTP GGUFs exist for `ggml-org/Qwen3.6-35B-A3B-MTP-GGUF`. Vulkan support for
the underlying PR [#22400](https://github.com/ggml-org/llama.cpp/pull/22400)
(required for hybrid GDN partial seq removal) was incomplete at PR open time
— an early Strix Halo tester reported garbage output. **Lemonade v10.6.0
(May 21, 2026) has built-in MTP support** (merged PR #1944) and ships
llama.cpp b9253.

ROCmFP4 path with MTP on Strix Halo is deployed and active. Measured
**50-71 tok/s decode** (vs ~25 tok/s Vulkan baseline), but ~50% below the
fork's published 80-104 tok/s targets. See the [ROCmFP4 measured results](#rocmfp4-on-strix-halo)
section for the full gap analysis.

### MTP on both platforms

For interactive chat, MTP n=2 is the sweet spot: meaningful decode speedup
without excessive prefill regression. MTP adds ~2.5 GB VRAM overhead for the
draft head context.

On Strix Halo, n-max=3 with reasoning ON is the published fork optimum for
sustained decode. n-max=2 is optimal for reasoning OFF. Goldenball runs
n-max=3 reasoning ON.

---

## vLLM on Strix Halo

Lemonade v10.4+ ships experimental vLLM ROCm backend for gfx1151.

### What it does

vLLM's continuous batching and PagedAttention can improve throughput on
prefill-heavy workloads compared to llama.cpp's single-request mode.

### Status

- Lemonade v10.4+ (May 2026): experimental vLLM ROCm backend available
- Issue [#1912](https://github.com/lemonade-sdk/lemonade/issues/1912): `-sc` argument parsing bug (fixed May 18, PR #1919)
- AMD GAIA benchmark effort: [#1140](https://github.com/amd/gaia/issues/1140) — controlled comparison of vLLM vs llama.cpp on Strix Halo, results not yet published
- Known risks: tool-call shape compatibility (GAIA wraps tool-calls in a
  `__tool_calls__` JSON sentinel; vLLM may return deltas differently)

### When to use

- Prefill-heavy workloads (RAG with long context) — vLLM's batched prefill shines
- High concurrency scenarios — continuous batching helps
- Not yet recommended for tool-calling workloads until compatibility is verified

---

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

# 4. Wait ~30s for the new model to load. Watch progress:
incus exec llm -- journalctl -u llama-cpp --no-pager -f
# Look for "main: model loaded" then Ctrl+C
```

The full round-trip is ~30-60 seconds end-to-end on a model that's already
cached locally. If the GGUF isn't cached, llama-server auto-fetches from
HuggingFace on first start (`--hf-repo`, `--hf-file`). 20+ GB GGUF download
over your home connection adds ~5-15 minutes.

**On goldenball:** ROCmFP4 35B-MTP is the active model, running as a
systemd service (`systemctl start|stop llama-cpp`). Start takes ~15s to
load the model; the service is NOT auto-started at boot.

---

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

**Current recommendation**: single-active model is simpler and matches how
you actually use this. If/when toggling becomes annoying, switch to router
mode.

---

## llama-server tuning flags

### Baseline (always emitted)

```
-ngl 99                       # full GPU offload (all layers)
--flash-attn auto             # KHR_coopmat on RADV / FA3 on CUDA
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

# ROCmFP4 + MTP — spec-decoding flags per fork's recipe
extraFlags = [
  "--jinja"
  "--no-mmproj"
  "--reasoning" "on"
  "--spec-type" "draft-mtp"
  "--spec-draft-n-max" "3"
  "--spec-draft-n-min" "0"
  "--spec-draft-p-min" "0.0"
  "--spec-draft-p-split" "0.10"
  "--spec-draft-type-k" "q4_0"
  "--spec-draft-type-v" "q4_0"
  "-dev" "ROCm0"
];

# Gemma 4 — needs --swa-full for cache reuse to work
extraFlags = [
  "--jinja"
  "--no-mmproj"
  "--swa-full"        # REQUIRED for SWA cache reuse (llama.cpp ≥ b8819)
  "--reasoning" "off"
];

# Qwen3 14B — standard transformer, minimal flags
extraFlags = [ "--jinja" ];
# (standard transformer = KV cache reuse works, no --swa-full needed)

# Qwen3-Coder — no special flags, defaults are fine
extraFlags = [ "--jinja" ];
```

### Flags to never use on crown (NVIDIA)

- **`--no-host`** — has been linked to 94% slowdowns on AMDVLK (not our
  driver, but adjacent). Don't try it on CUDA.
- **`-sm row` or `-sm tensor`** — split modes for multi-GPU. Single-GPU
  setup, irrelevant.

### Flags to never use on goldenball (AMD Vulkan)

- **`--spec-type ngram-mod`** — silently rejected by hybrid-attention models
  (Qwen3.6). Even when accepted, incompatible with hybrid.
- **`GGML_VK_DISABLE_FUSION`** — catastrophic (-18.5% MoE, -5% dense) on
  RADV. Don't disable Vulkan graph fusion.

---

## KV cache quantization

K and V cache tensors store the model's attention state for the current
context. Quantizing them saves significant VRAM, enabling larger context
windows at the cost of some attention precision at long range.

| KV quant | VRAM vs f16 | Quality impact                                                                | Use when                            |
| -------- | ----------- | ----------------------------------------------------------------------------- | ----------------------------------- |
| `f16`    | 1×          | None (reference)                                                              | Never — wastes VRAM                 |
| `q8_0`   | 0.5×        | None measurable                                                               | Default for most models             |
| `q4_0`   | 0.25×       | Negligible at short/medium context; slight long-range retrieval fuzz at 100K+ | Primary when you need 128K+ context |

**Important**: `q4_0` KV does **not** make the model "dumber" — it does not
affect model weights. It reduces precision in how the model _attends to
earlier tokens_ at very long range. For opencode tool-call loops and typical
chat, the difference is unmeasurable.

The fused flash-attention kernel requires K and V to be the **same** type, so
the only valid choices are `f16/f16`, `q8_0/q8_0`, or `q4_0/q4_0`. Mixed
types disable the fused kernel and cost ~4-10% throughput.

---

## Cold-start vs warm performance

### 1. Container restart → first generation request

The Mesa shader pipeline cache might or might not be warm depending on
what pipeline shapes were exercised previously. With `MESA_SHADER_CACHE_DIR`
persistence pointing to `/var/cache/llama-cpp/mesa-shaders`, the cache
survives container relaunches.

The slowest path is **first prompt prefill at ubatch=2048 size** — Mesa
needs to compile that pipeline variant if it isn't cached. Measured at
~18 seconds for a ~20-token prompt on a fresh container relaunch.

Subsequent generations are warm: ~45 tok/s prefill, ~43 tok/s decode
(ROCmFP4) on Strix Halo at ubatch=512. The llama-bench results show
consistent throughput: pp512 at 45.7 tok/s, tg512 at 45.7 tok/s.

### 2. First model load

Loading a GGUF from NVMe into GPU memory takes ~15 seconds:

- ~10s to mmap+stream the file
- ~5s for llama.cpp's internal tensor placement and initial GPU buffer setup

On Strix Halo, the full process RSS settles at ~45 GB (model weights in
system RAM via GTT, not the 4 GB VRAM carve-out).

If the GGUF isn't cached locally (first time using a new preset), add
~5-15 minutes for the HuggingFace download.

### MLX Engine cold start

MLX Engine loads significantly faster than llama.cpp because it doesn't
need to compile shader pipelines:

- Cold start: **2-5 seconds** to serve the first request
- First model download + load: ~30-60 seconds (depends on model size)

---

## Multi-turn TTFT (the perceived-speed problem)

The "first feels fast, second turn feels slow" pattern comes from
**hybrid attention's full re-prefill on every turn**. See the
[model architecture trap](#the-model-architecture-trap-hybrid-vs-swa-vs-standard)
section above.

The fix has two parts:

1. **Run a model that supports partial KV sequence removal**. Standard
   transformers (Devstral, Qwen3-Coder, etc.) always do. SWA models (Gemma 4)
   do with the recent llama.cpp fix and `--swa-full`.
2. **For Gemma 4 specifically, ensure llama.cpp is build ≥ b8819** (PR
   [#22288](https://github.com/ggml-org/llama.cpp/pull/22288) merged
   2026-04-24). Latest Lemonade ships b9253 ✓.

### Crown (RTX 5060 Ti, CUDA)

Predicted performance (no measured data yet):

| Model               | Predicted decode tok/s | Notes                         |
| ------------------- | ---------------------- | ----------------------------- |
| Qwen3-8B            | ~80-120                | Near bandwidth ceiling for 8B |
| Qwen3-14B           | ~50-70                 | —                             |
| Qwen3-30B (if fits) | ~25-40                 | Tight on 16 GB VRAM           |

CUDA should be 1.5-2× faster than Vulkan for equivalent models on this
bandwidth class.

### Goldenball (Strix Halo, ROCmFP4 measured 2026-06-07)

Live measured numbers, ROCmFP4 STRIX_LEAN + MTP n-max=3 + reasoning-on,
compared against the prior Vulkan baseline measured on the same hardware:

| Workload                        | Vulkan baseline | ROCmFP4 (measured) | Uplift |
| ------------------------------- | --------------- | ------------------ | ------ |
| Decode, short prompt + MTP      | 45 tok/s        | **70 tok/s**       | 1.55×  |
| Decode, sustained 1024 tok      | 22-28 tok/s     | **48-50 tok/s**    | ~2×    |
| Prompt prefill, long (~500 tok) | 88-360 tok/s    | **681 tok/s**      | 1.9×   |
| MTP draft acceptance (avg)      | 86%             | 56-80% (varies)    | —      |

The fork's own headline numbers (104.3 burst / 80.1 sustained) were not
fully reproduced — see the [ROCmFP4 measured results](#measured-results-on-goldenball-2026-06-07)
section for the gap analysis. Even the lower numbers we hit are a 1.5-2×
real improvement over the Vulkan baseline that previously ran on this same
machine, which is the bar that matters for daily use.

### Goldenball: where the speed actually went up

The most user-visible change was prompt prefill, not decode:

- A 500-token prompt used to take ~5-6 seconds before the first generated
  token (Vulkan, 88-360 t/s prefill). It now takes <1s (ROCmFP4, 681 t/s).
- For tool-use loops in opencode where each turn re-prefills 500-2000 tokens
  of conversation, this matters more than the headline decode number.
- Decode improvement is real but smaller (1.5-2×) and most apparent on
  short interactive replies where the burst kernel paths shine.

---

## Open WebUI integration

See `docs/OPENWEBUI.md` for the full Open WebUI recipes (thinking toggle via
custom_params, web search setup, etc.). Key points for the LLM hosting side:

- Open WebUI runs in the same `llm` LXC as llama-server (crown). Talks to
  `http://localhost:8080/v1` (no network hop, no TLS).
- Per-conversation model switching works **within whatever models llama-server
  exposes via `/v1/models`**, which is currently the one active preset.
- Workspace > Models lets you build custom presets (system prompt + custom
  params) on top of the active base model.
- Open WebUI's web search is **RAG-style retrieval**, not tool-calling. It
  fetches pages, optionally embeds them, and injects as context **before**
  the model generates.

---

## opencode integration

See `modules/home/nixvim/default.nix` for the `opencode-llamacpp` home-manager
module. Currently enabled on mountainball, points at `https://llm.r6t.io/v1`.

The integration registers the active model as a provider in
`~/.config/opencode/opencode.json`. Per-model `variants` let you toggle
thinking on/off without changing the active model on the server side
(thinking is per-request via `chat_template_kwargs`, same mechanism as the
Open WebUI workspace preset).

Reality check: no open-weights model under 100B parameters breaks 50% on
Aider polyglot. The 60-70% range is 600B+ models (DeepSeek V3.2, Kimi K2).
**Local coding is for fast iteration on bounded tasks** — single file
refactors, lint fixes, test additions, boilerplate. Cross-file architecture
work still wants Claude / GPT-5.

---

## Quick reference

### Check what's running

```fish
# crown (LXC)
incus exec llm -- systemctl status llama-cpp --no-pager
incus exec llm -- journalctl -u llama-cpp --no-pager -f
incus exec llm -- bash -c 'curl -s http://127.0.0.1:8080/v1/models | head'

# goldenball (bare metal)
systemctl status llama-cpp --no-pager
ps -o rss= -p $(pgrep llama-server) | awk '{printf "RSS: %.1f GB\n", $1/1024/1024}'
curl -s http://127.0.0.1:8080/v1/models | jq '.data[].id'
```

### Measure performance

```fish
# crown
ssh crown 'incus exec llm -- bash -c "curl -s -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H \"Content-Type: application/json\" \
  -d \"{\\\"messages\\\":[{\\\"role\\\":\\\"user\\\",\\\"content\\\":\\\"Reply with one word: ok\\\"}],\\\"max_tokens\\\":50}\""' \
  | python3 -c "import json,sys; t=json.load(sys.stdin)['timings']; \
    print(f'prompt {t[\"prompt_per_second\"]:.0f} tok/s, gen {t[\"predicted_per_second\"]:.1f} tok/s')"

# goldenball
curl -s -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3.6-35b-a3b-mtp-rocmfp4-lean",
       "messages":[{"role":"user","content":"Reply with one word: ok"}],
       "max_tokens":50,"temperature":0.1}' \
  | python3 -c "import json,sys; t=json.load(sys.stdin)['timings']; \
    print(f'prompt {t[\"prompt_per_second\"]:.0f} tok/s, gen {t[\"predicted_per_second\"]:.1f} tok/s'); \
    print(f'draft: {t[\"draft_n\"]} gen, {t[\"draft_n_accepted\"]} accepted ({t[\"draft_n_accepted\"]/t[\"draft_n\"]*100:.0f}%)')
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
- `vk::DeviceLostError` or `Pageflip timed out` → Vulkan driver crash on
  Strix Halo (see [llama.cpp #20515](https://github.com/ggml-org/llama.cpp/issues/20515));
  try ubatch=512 or switch to ROCmFP4 backend.

---

## Related docs

- `docs/GOLDENBALL_FREEZES.md` — Strix Halo freeze troubleshooting
- `docs/INCUS.md` — LXC architecture, networking, GPU passthrough
- `docs/OPENWEBUI.md` — Open WebUI recipes (thinking, web search)
- `containers/` — LXC image definitions (llm container not yet created)
- `modules/nixos/llama-cpp/default.nix` — module options, baseline flags
- `modules/home/nixvim/default.nix` — opencode integration
