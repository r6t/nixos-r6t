# Plain Nix value file — no NixOS module machinery.
# Imported by hosts/goldenball/configuration.nix for both the local
# llama-server service config and the opencode provider model limits.
#
# Hardware: AMD Radeon 8060S (RDNA 3.5 / gfx1151), Strix Halo unified RAM.
# GPU-accessible RAM: ~104 GB (ttm.pages_limit=27262976, leaves 24 GB for OS).
# Bandwidth: ~256 GB/s LPDDR5X (memory clock fixed at 1000 MHz = 8000 MT/s).
# ubatch: 1024 (RADV-tuned optimum for gfx1151 per lhl/strix-halo-testing).
#
# Backends available (set in hosts/goldenball/configuration.nix):
#   - vulkan = true:  pkgs.llama-cpp-vulkan (RADV). Stable historical default.
#   - rocmfp4 = true: charlie12345/rocmfp4-llama fork (HIP+Vulkan combined
#                     binary with custom Q4_0_ROCMFP4 STRIX/STRIX_LEAN quants).
#                     Reports 80-104 tok/s decode on Qwen3.6-35B-A3B-MTP at
#                     262K context — ~2× faster than stock Vulkan llama.cpp.
#                     ROCm HIP on gfx1151 was historically unstable but the
#                     fork's HIP code path is now reported stable on Strix
#                     Halo as of 2026-05.
#
# VRAM budget: weights + KV(q8_0) + compute ≤ ~100 GB (llama.cpp sees 102400 MiB)
#
# Decode speed reference at ~256 GB/s bandwidth (70% efficiency measured):
#   Qwen3.6-35B-A3B UD-Q4_K_XL (~23 GB, ~3B active, MTP-2, Vulkan):  ~22-45 tok/s measured
#   Qwen3.6-35B-A3B ROCmFP4_STRIX_LEAN (~19 GB, MTP-3, ROCm0):       ~80-104 tok/s reported
#   Qwen3.6-35B-A3B ROCmFP4_STRIX      (~21 GB, MTP-3, ROCm0):       expected 5-10% slower than LEAN
#   Qwen3.6-27B Q6_K           (~21 GB, 27B dense, Vulkan):          ~8-9 tok/s measured
#   Qwen3-57B-A14B Q6_K        (~47 GB, ~14B active, Vulkan):        ~25-35 tok/s est.
#   Qwen3-32B Q8_0             (~34 GB, 32B dense, Vulkan):          ~12-15 tok/s est.
#
# MTP (Multi-Token Prediction): Qwen3.6-35B-A3B has MTP draft heads baked into
# the MTP-GGUF. Enable with --spec-type draft-mtp --spec-draft-n-max N.
# Per fork data on Strix Halo for the 35B model with reasoning ON, n-max=3
# is the sustained-decode optimum. n-max=2 is best for reasoning OFF.
#
# Hybrid GDN attention note: both Qwen3.6 models use GatedDeltaNet hybrid
# attention (3 GDN layers per 1 standard attention layer). llama.cpp cannot do
# partial KV sequence removal, so full re-prefill happens every turn.
# cacheRamMiB=0 is mandatory — the disk cache writes 150-200 MiB per turn and
# never reads back (pure overhead). --cache-reuse is silently ignored for these
# models by llama.cpp regardless of flag value.
#
# Per-preset fields:
#   modelId      — the string llama-server reports at /v1/models. Stable across
#                  ROCmFP4 quant variants by setting --alias explicitly. Used
#                  as the opencode provider key.
#   hfRepo/hfFile — auto-download from HuggingFace at server start (fork
#                   binaries support this). Mutually exclusive with modelFile.
#   modelFile    — absolute path to a local GGUF. Used for the ROCmFP4 quants
#                   produced by scripts/quantize-rocmfp4-strix.fish.
#   alias        — passed as --alias to llama-server. Required when modelFile
#                   is set; sets the model ID llama-server advertises.

let
  # Common chat-template flags for every Qwen3.6 preset.
  qwen36CommonFlags = [
    "--jinja"
    "--no-mmproj"
  ];

  # Spec-decoding flags for ROCmFP4 + MTP per fork's published recipe.
  # Reasoning-on, n-max=3, q4 draft KV — the published 80.1 sustained / 104.3
  # burst tok/s configuration on Qwen3.6-35B-A3B-MTP at 262K context.
  rocmfp4MtpFlags = [
    "--reasoning"
    "on"
    "--spec-type"
    "draft-mtp"
    "--spec-draft-n-max"
    "3"
    "--spec-draft-n-min"
    "0"
    "--spec-draft-p-min"
    "0.0"
    "--spec-draft-p-split"
    "0.10"
    "--spec-draft-type-k"
    "q4_0"
    "--spec-draft-type-v"
    "q4_0"
  ];

  models = {
    # ─── ROCmFP4 STRIX_LEAN: expected fastest, primary target ──────────────
    # Compact Strix profile (4.34 BPW) — speed-biased ROCmFP4 quant. The
    # published 89-104 tok/s decode numbers reference this exact preset.
    # Quantize from BF16 with: scripts/quantize-rocmfp4-strix.fish --profile lean
    # Uses q8 main KV + q4 draft KV per the fork's headline benchmark recipe.
    #
    # modelFile lives outside /var/cache/llama-cpp because that is systemd's
    # CacheDirectory under DynamicUser=true (mode 0700, dynamic UID), which
    # means r6t cannot write the quantized GGUF there. /var/lib/llama-cpp-models
    # is created by tmpfiles in hosts/goldenball/configuration.nix as
    # r6t:users 0755 — r6t can write quants, the dynamic-user service can read.
    qwen3-6-35b-a3b-rocmfp4-lean = {
      modelId = "qwen3.6-35b-a3b-mtp-rocmfp4-lean";
      modelFile = "/var/lib/llama-cpp-models/Qwen3.6-35B-A3B-MTP-ROCmFP4-STRIX_LEAN.gguf";
      alias = "qwen3.6-35b-a3b-mtp-rocmfp4-lean";
      contextSize = 262144;
      ubatchSize = 512;
      cacheRamMiB = 0; # hybrid GDN
      extraFlags = qwen36CommonFlags ++ rocmfp4MtpFlags ++ [ "-dev" "ROCm0" ];
    };

    # ─── ROCmFP4 STRIX: quality-biased variant ──────────────────────────────
    # Same fork, larger preset (~4.5+ BPW) holding more attention-sensitive
    # tensors at higher precision (Q5_K/Q6_K/Q8_0 mix). Expected 5-10% slower
    # decode than LEAN; closer to Q5_K quality.
    # Quantize from BF16 with: scripts/quantize-rocmfp4-strix.fish --profile strix
    qwen3-6-35b-a3b-rocmfp4-strix = {
      modelId = "qwen3.6-35b-a3b-mtp-rocmfp4-strix";
      modelFile = "/var/lib/llama-cpp-models/Qwen3.6-35B-A3B-MTP-ROCmFP4-STRIX.gguf";
      alias = "qwen3.6-35b-a3b-mtp-rocmfp4-strix";
      contextSize = 262144;
      ubatchSize = 512;
      cacheRamMiB = 0;
      extraFlags = qwen36CommonFlags ++ rocmfp4MtpFlags ++ [ "-dev" "ROCm0" ];
    };

    # ─── Vulkan baseline: Qwen3.6-35B-A3B MTP UD-Q4_K_XL ────────────────────
    # MoE (3B active / 35B total) with MTP draft heads.
    # Best agentic coding benchmark scores of any Qwen3.6 variant — evaluated
    # via OpenCode specifically on SkillsBench (28.7 avg5) and Terminal-Bench
    # 2.0 (51.5). MTP-2 measured ~22-45 tok/s decode on Vulkan/RADV.
    # Full 262K native context: only 10 standard attention layers → KV cache is
    # tiny (~1.5 GB at q8_0, 262K ctx) despite the large context window.
    # cacheRamMiB=0: hybrid GDN prevents KV reuse; disk cache is pure overhead.
    # Used when rocmfp4 = false in host config (flip to compare to ROCmFP4).
    qwen3-6-35b-a3b-mtp = {
      modelId = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
      hfRepo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
      hfFile = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"; # 22.9 GB
      contextSize = 262144;
      ubatchSize = 512; # reduce from 1024: shorter GPU bursts give DCN 3.5.1 more idle windows
      cacheRamMiB = 0;
      extraFlags = qwen36CommonFlags ++ [
        "--reasoning"
        "off"
        "--spec-type"
        "draft-mtp"
        "--spec-draft-n-max"
        "2"
      ];
    };

    # ── Fallback: Qwen3.6-27B dense ─────────────────────────────────────────
    # Dense 27B model. Slower decode than 35B-A3B (~8-9 tok/s measured at 256
    # GB/s bandwidth-limited) but slightly higher quant precision at Q6_K.
    # Useful if MTP causes issues or for comparison testing.
    # Also uses hybrid GDN — same full re-prefill penalty per turn.
    qwen3-6-27b = {
      modelId = "unsloth/Qwen3.6-27B-GGUF";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf"; # 22.5 GB
      contextSize = 262144;
      cacheRamMiB = 0;
      extraFlags = qwen36CommonFlags ++ [ "--reasoning" "off" ];
    };

    # ── High quality MoE: Qwen3-57B-A14B (standard transformer) ─────────────
    # Standard MoE transformer — full KV cache reuse between turns (snappy
    # multi-turn, unlike the Qwen3.6 hybrid GDN models). 14B active params.
    # Fits at 104 GB with generous context headroom.
    qwen3-57b-a14b = {
      modelId = "unsloth/Qwen3-57B-A14B-GGUF";
      hfRepo = "unsloth/Qwen3-57B-A14B-GGUF";
      hfFile = "Qwen3-57B-A14B-Q6_K.gguf";
      contextSize = 131072;
      cacheRamMiB = 8192;
      extraFlags = qwen36CommonFlags ++ [ "--reasoning" "off" ];
    };

    # ── Dense high-quality: 32B at Q8_0 — deterministic, no MoE variance ─────
    qwen3-32b = {
      modelId = "bartowski/Qwen3-32B-GGUF";
      hfRepo = "bartowski/Qwen3-32B-GGUF";
      hfFile = "Qwen3-32B-Q8_0.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = qwen36CommonFlags ++ [ "--reasoning" "off" ];
    };

    # ── Coding: Devstral dense standard transformer ───────────────────────────
    devstral-small-2-24b = {
      modelId = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 131072;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # Change this one line to switch the active model.
  # hosts/goldenball/configuration.nix reads activeModel for both the
  # llama-server service flags and the opencode provider context limit.
  #
  # Default: ROCmFP4 STRIX_LEAN (expected fastest). To run it you must first
  # quantize the model once (one-time setup):
  #
  #     ./scripts/quantize-rocmfp4-strix.fish --profile lean
  #
  # To compare against the Vulkan baseline, switch to qwen3-6-35b-a3b-mtp and
  # also flip mine.llama-cpp.rocmfp4 → vulkan in configuration.nix.
  # ─────────────────────────────────────────────────────────────────────────────
  activeModel = models.qwen3-6-35b-a3b-rocmfp4-lean;
in
{
  inherit models activeModel;
}
