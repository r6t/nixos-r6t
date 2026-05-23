# Plain Nix value file — no NixOS module machinery.
# Imported by hosts/goldenball/configuration.nix for both the local
# llama-server service config and the opencode provider model limits.
#
# Hardware: AMD Radeon 8060S (RDNA 3.5 / gfx1151), Strix Halo unified RAM.
# GPU-accessible RAM: ~96 GB (ttm.pages_limit=25165824).
# Backend: Vulkan (RADV) — ROCm HIP segfaults on gfx1151.
# Bandwidth: ~256 GB/s LPDDR5X (vs crown's 640 GB/s GDDR6).
#
# VRAM budget per model:
#   weights + KV_cache(q8_0) + compute_graph ≤ ~92 GB (leaving 4 GB for OS/Mesa)
#
# Decode speed reference at ~256 GB/s bandwidth (estimated):
#   Qwen3-57B-A14B Q6_K  (~47 GB, ~14B active): ~30–40 tok/s
#   Qwen3.6-35B-A3B Q4KM (~20 GB, ~3B active):  ~80–100 tok/s  (bandwidth-limited by weights)
#   Qwen3-32B Q8_0        (~34 GB, 32B dense):  ~45–55 tok/s

let
  models = {
    # ── Primary: largest quality model that fits comfortably ─────────────────
    # Standard MoE transformer — full KV cache reuse between turns (snappy
    # multi-turn). 14B active params vs the 35B hybrid's ~3B — noticeably
    # better reasoning and coding. Fits at 96 GB with generous context headroom.
    qwen3-57b-a14b = {
      hfRepo = "unsloth/Qwen3-57B-A14B-GGUF";
      hfFile = "Qwen3-57B-A14B-Q6_K.gguf";
      contextSize = 131072; # 128K — ~3 GB KV q8_0; weights ~47 GB; total ~52 GB
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ── Tuned 27B: GatedDeltaNet hybrid model (Z13 primary) ─────────────────
    # Fast dense model tuned for Strix Halo unified LPDDR5X memory.
    # Q6_K quant represents the optimal sweet spot for 27B-class quality.
    # cacheRamMiB=0: GatedDeltaNet hybrid attention prevents partial KV cache sequence removal,
    # making prompt caching pure overhead (re-prefill on every turn).
    qwen3-6-27b = {
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf";
      contextSize = 131072; # 128K context is very fast & highly capable on Z13's large RAM
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ── Fast: same model as crown — proven, hybrid GDN ───────────────────────
    # Faster decode than 57B (fewer active params, smaller weight footprint).
    # cacheRamMiB=0: hybrid GDN attention makes prompt cache pure overhead
    # (no partial KV sequence removal — full re-prefill every turn).
    qwen3-6-35b-a3b = {
      hfRepo = "unsloth/Qwen3.6-35B-A3B-GGUF";
      hfFile = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
      contextSize = 262144; # 256K — ~1.4 GB KV q4_0; weights ~20 GB; total ~24 GB
      cacheRamMiB = 0; # hybrid GDN: cache writes but never reads — pure overhead
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
  activeModel = models.qwen3-6-27b;
in
{
  inherit models activeModel;
}
