{ lib, ... }:

let
  # ---------------------------------------------------------------------------
  # Model catalogue (32 GiB Radeon AI Pro R9700, RDNA 4 / GFX1201, Vulkan).
  # All models accumulate on persistent storage at:
  #   crown host:    /mnt/crownstore/app-storage/llama-cpp/models/
  #   container:     /var/lib/llama-cpp/models/
  # Pre-download: drop the GGUF into the host path above.
  # On first start, llama-server auto-downloads from HF if not present.
  #
  # Role: text-only general-purpose chat for open-webui + agentic coding
  # backend for opencode. Vision deliberately disabled (--no-mmproj) to free
  # VRAM for context length and quality; web search is a tool the agent calls
  # and returns text, so vision is not needed for it.
  #
  # Quant selection on 32 GiB at Q6_K (deep-dive May 2026):
  #   Q8_0    KLD 0.0038, ~28.6 GB weights — leaves <4 GB for KV+graph, no headroom
  #   Q6_K    KLD 0.0072, ~22.5 GB weights — best quality/headroom balance
  #   Q5_K_M  KLD 0.0108, ~19.7 GB weights — only if pushing 256K+ context
  #   Q4_K_M  KLD 0.025+,             ~17 GB weights — quality starts to bite
  # Q6_K only doubles Q8's quantization error in absolute terms (still tiny on
  # 27B-class models per MagicQuant v2.0 KLD data) while freeing ~6 GB for
  # KV cache + compute graph. That headroom buys us a real 128K context window.
  #
  # To switch models, change `activeModel` to one of the keys below.
  # ---------------------------------------------------------------------------
  models = {
    # PRIMARY: best opencode-harness number of any model that fits 32 GiB.
    # Dense 27B, hybrid GatedDeltaNet + gated attention (only 16/64 layers
    # carry traditional KV cache, so KV grows much more slowly with context
    # than a vanilla transformer). Native 256K context. Default thinking mode.
    # Qwen card's SkillsBench (evaluated *via OpenCode on 78 tasks*) reports
    # 48.2 vs 28.7 for the 35B-A3B MoE — dense beats MoE for opencode's
    # tool-calling loop reliability. unsloth's GGUF includes the "Developer
    # Role Support so Qwen3.6 can work in Codex, OpenCode and more" template
    # fix and "Tool calling improvements: Makes parsing nested objects to
    # make tool calling succeed more" — important for opencode.
    # --jinja: required for correct Qwen3 tool-use prompt formatting.
    # --no-mmproj: text-only, free the vision encoder VRAM.
    # Sampler: Qwen's "precise coding" preset (temp 0.6, top_p 0.95, top_k 20).
    qwen3-6-27b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-27B-Q6_K.gguf";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf";
      contextSize = 131072; # 128K — comfortable headroom at Q6 + q8 KV.
      extraFlags = [
        "--jinja"
        # Disable the multimodal projector entirely (text-only inference).
        # Frees ~1 GiB VRAM that would otherwise hold the vision encoder.
        "--no-mmproj"
        # Qwen3 "precise coding" sampler (per official model card recommendations).
        # For chattier creative use via open-webui, override per-request.
        "--temp"
        "0.6"
        "--top-p"
        "0.95"
        "--top-k"
        "20"
        "--min-p"
        "0.0"
        "--repeat-penalty"
        "1.0"
      ];
    };

    # ALTERNATIVE: purpose-built coding-agent variant. MoE 30.5B total /
    # 3.3B active, no thinking (faster turns), "specially designed function
    # call format" per model card. In real opencode head-to-heads on a single
    # codebase (r/LocalLLaMA u/yes_i_tried_google, May 2026) it outperformed
    # Qwen3.6-27B as a *builder* role while losing as an *orchestrator* —
    # use this when you want fast non-thinking code generation rather than
    # multi-step planning. Q4 is reportedly unreliable for agentic loops on
    # MoE; UD-Q6_K_XL is the right floor.
    qwen3-coder-30b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
      hfFile = "Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
      contextSize = 65536;
      extraFlags = [
        "--jinja"
        # Qwen3-Coder sampler (per official model card).
        "--temp"
        "0.7"
        "--top-p"
        "0.8"
        "--top-k"
        "20"
        "--repeat-penalty"
        "1.05"
      ];
    };
  };

  # Change this one line to switch models:
  # qwen3-6-27b (primary orchestrator) | qwen3-coder-30b-a3b (fast builder)
  activeModel = models.qwen3-6-27b;

in
{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  # open-webui has a non-OSI source-available license (Open WebUI License) that
  # nixpkgs flags as unfree. Allow it (and only it) for this container build.
  # The flake-level `allowUnfree = true` set on host nixosConfigurations does
  # not propagate to container builds, which evaluate nixpkgs separately.
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "open-webui" ];

  networking.hostName = "llm";

  # Precreate private state dirs (root-owned. systemd will manage perms for DynamicUser)
  # These appear in the rootfs so Incus can bind-mount to them before systemd starts.
  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
    "d /var/lib/private/open-webui 0700 root root -"
    "d /var/lib/private/llama-cpp 0700 root root -"
    "d /var/cache/private 0700 root root -"
    "d /var/cache/private/llama-cpp 0700 root root -"
  ];

  mine = {
    llama-cpp = {
      enable = true;
      host = "0.0.0.0";
      modelsDir = "/var/lib/llama-cpp/models";
      inherit (activeModel) modelFile hfRepo hfFile contextSize extraFlags;
      # q8_0 KV quantization: halves KV cache VRAM vs f16, near-zero quality
      # loss, and preserves the fused flash attention kernel (symmetric K/V).
      kvCacheQuant = "q8_0";
      # Default ubatch (2048) — 32 GiB R9700 has plenty of room for the
      # compute graph at this size, and prefill throughput benefits significantly.
      ubatchSize = 2048;
      # Flash attention: confirmed real gains on RDNA 4 (GFX1201 / KHR_coopmat).
      # +4-11% prefill, +4% generation throughput vs no-FA.
      flashAttn = "auto";
      # Vulkan backend (pkgs.llama-cpp-vulkan). On RDNA 4 / gfx1201 every
      # public R9700 + llama.cpp benchmark in 2025-2026 uses Vulkan rather
      # than ROCm/HIP — Vulkan is more stable and frequently faster on this
      # generation. The Phoenix iGPU is excluded from the container by the
      # incus profile's vendorid/productid filter (1002:7551 = Navi 48 only),
      # so the GPU backend only sees the R9700. Vulkan does not need /dev/kfd
      # (only renderD*), so the kfd unix-char device in the profile is
      # harmless dead weight but kept in case we swap back to ROCm for testing.
      vulkan = true;
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrls = [
        # Local llama-server (no key required)
        "http://localhost:8080/v1"
        # OpenRouter — full model catalogue available in the UI picker.
        "https://openrouter.ai/api/v1"
      ];
      # Secrets and OAuth config injected at runtime via environmentFile.
      # Bind-mounted from host at /mnt/crownstore/Sync/app-config/open-webui/oi.env
      # Contains: OPENAI_API_KEYS, OAuth/OIDC config (Pocket ID), etc.
      environmentFile = "/etc/oi.env";
    };
  };
}
