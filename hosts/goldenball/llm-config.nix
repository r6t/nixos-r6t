# Plain Nix value file — no NixOS module machinery.
# Imported by hosts/goldenball/configuration.nix for both the local
# llama-server service config and the opencode provider model limits.
#
# Hardware: AMD Radeon 8060S (RDNA 3.5 / gfx1151), Strix Halo unified RAM.
# GPU-accessible RAM: ~104 GB (ttm.pages_limit=27262976, leaves 24 GB for OS).
# Backend: Vulkan (RADV) — ROCm HIP segfaults on gfx1151.
# Bandwidth: ~256 GB/s LPDDR5X (memory clock fixed at 1000 MHz = 8000 MT/s).
# ubatch: 1024 (RADV-tuned optimum for gfx1151 per lhl/strix-halo-testing).
#
# VRAM budget: weights + KV(q8_0) + compute ≤ ~100 GB (llama.cpp sees 102400 MiB)
#
# Decode speed reference at ~256 GB/s bandwidth (70% efficiency measured):
#   Qwen3.6-35B-A3B UD-Q4_K_M (~23 GB, ~3B active, MTP-2): ~40–60 tok/s est.
#   Qwen3.6-35B-A3B UD-Q4_K_M (~23 GB, ~3B active, no MTP): ~25–35 tok/s est.
#   Qwen3.6-27B Q6_K           (~21 GB, 27B dense):          ~8–9 tok/s measured
#   Qwen3-57B-A14B Q6_K        (~47 GB, ~14B active):        ~25–35 tok/s est.
#   Qwen3-32B Q8_0             (~34 GB, 32B dense):          ~12–15 tok/s est.
#
# MTP (Multi-Token Prediction): Qwen3.6-35B-A3B has MTP draft heads baked into
# the MTP-GGUF. Enable with --spec-type draft-mtp --spec-draft-n-max 2.
# Unsloth claims 1.5-2× decode speedup. Community data on gfx1151 via ROCm
# shows ~1.4× confirmed; Vulkan MTP not yet independently benchmarked on this
# chip but uses the same llama.cpp MTP code path (PR #22673, merged 2026-05-16).
#
# Hybrid GDN attention note: both Qwen3.6 models use GatedDeltaNet hybrid
# attention (3 GDN layers per 1 standard attention layer). llama.cpp cannot do
# partial KV sequence removal, so full re-prefill happens every turn.
# cacheRamMiB=0 is mandatory — the disk cache writes 150-200 MiB per turn and
# never reads back (pure overhead). --cache-reuse is silently ignored for these
# models by llama.cpp regardless of flag value.

let
  models = {
    # ── Primary: Qwen3.6-35B-A3B MTP ────────────────────────────────────────
    # MoE (3B active / 35B total) with MTP draft heads for speculative decoding.
    # Best agentic coding benchmark scores of any Qwen3.6 variant — evaluated
    # via OpenCode specifically on SkillsBench (28.7 avg5) and Terminal-Bench
    # 2.0 (51.5). MTP-2 expected to deliver ~1.5-2× decode speedup over the
    # non-MTP UD-Q4_K_M.
    # Full 262K native context: only 10 standard attention layers → KV cache is
    # tiny (~1.5 GB at q8_0, 262K ctx) despite the large context window.
    # cacheRamMiB=0: hybrid GDN prevents KV reuse; disk cache is pure overhead.
    qwen3-6-35b-a3b-mtp = {
      hfRepo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
      hfFile = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf"; # 22.9 GB
      contextSize = 262144; # 256K native — ~1.5 GB KV q8_0; weights ~23 GB; total ~30 GB
      cacheRamMiB = 0; # hybrid GDN: cache writes but never reads — pure overhead
      extraFlags = [
        "--jinja"
        "--no-mmproj"
        "--reasoning"
        "off"
        "--spec-type"
        "draft-mtp"
        "--spec-draft-n-max"
        "2"
        # Reduce micro-batch from module default (1024) to limit peak GPU burst
        # duration per MTP verification cycle. Shorter bursts give the DCN 3.5.1
        # display engine more frequent idle windows between compute passes,
        # reducing the probability of a flip_done timeout after inference.
        "-ub"
        "512"
      ];
    };

    # ── Fallback: Qwen3.6-27B dense ─────────────────────────────────────────
    # Dense 27B model. Slower decode than 35B-A3B (~8-9 tok/s measured at 256
    # GB/s bandwidth-limited) but slightly higher quant precision at Q6_K.
    # Useful if MTP causes issues or for comparison testing.
    # Also uses hybrid GDN — same full re-prefill penalty per turn.
    qwen3-6-27b = {
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf"; # 22.5 GB
      contextSize = 262144; # 256K native — ~4.3 GB KV q8_0; weights ~21 GB; total ~30 GB
      cacheRamMiB = 0; # hybrid GDN: cache writes but never reads — pure overhead
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ── High quality MoE: Qwen3-57B-A14B (standard transformer) ─────────────
    # Standard MoE transformer — full KV cache reuse between turns (snappy
    # multi-turn, unlike the Qwen3.6 hybrid GDN models). 14B active params.
    # Fits at 104 GB with generous context headroom.
    qwen3-57b-a14b = {
      hfRepo = "unsloth/Qwen3-57B-A14B-GGUF";
      hfFile = "Qwen3-57B-A14B-Q6_K.gguf";
      contextSize = 131072; # 128K — ~3 GB KV q8_0; weights ~47 GB; total ~52 GB
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ── Dense high-quality: 32B at Q8_0 — deterministic, no MoE variance ─────
    qwen3-32b = {
      hfRepo = "bartowski/Qwen3-32B-GGUF";
      hfFile = "Qwen3-32B-Q8_0.gguf";
      contextSize = 65536; # 64K — ~4 GB KV q8_0; weights ~34 GB; total ~40 GB
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ── Coding: Devstral dense standard transformer ───────────────────────────
    devstral-small-2-24b = {
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 131072; # 128K — ~4 GB KV q8_0; weights ~20 GB; total ~26 GB
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };
  };

  # ─────────────────────────────────────────────────────────────────────────────
  # Change this one line to switch the active model.
  # hosts/goldenball/configuration.nix reads activeModel for both the
  # llama-server service flags and the opencode provider context limit.
  # ─────────────────────────────────────────────────────────────────────────────
  activeModel = models.qwen3-6-35b-a3b-mtp;
in
{
  inherit models activeModel;
}
