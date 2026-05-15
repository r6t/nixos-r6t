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
  # MODEL ARCHITECTURE MATTERS MORE THAN QUALITY for perceived multi-turn UX
  # on llama.cpp as of May 2026:
  #   - Hybrid attention (Qwen3.6 GatedDeltaNet, Qwen3-Next, RWKV-style):
  #       partial KV sequence removal NOT supported → --cache-reuse silently
  #       disabled → every turn does a full re-prefill of the entire chat
  #       history → multi-turn TTFT is multi-second, "feels slow".
  #       See llama.cpp issue #22940 (patch exists but unmerged as of May 14).
  #   - Standard transformers (dense or pure-attention MoE):
  #       partial KV sequence removal works → --cache-reuse hits → turn-N
  #       prefill is sub-second once the prefix is cached. Feels like Ollama.
  #   - SWA + global attention (Gemma 4): cache reuse works only on
  #       llama.cpp build >= b8819 (PR #22288 merged 2026-04-24) AND only
  #       when --swa-full is passed. Older builds = same TTFT pain as hybrid.
  #
  # Quant selection on 32 GiB at Q6_K (deep-dive May 2026, Qwen3.6-27B-specific):
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
      # Hybrid GatedDeltaNet attention does not support partial KV sequence
      # removal, so --cache-reuse is silently disabled and the disk cache is
      # never read back. Production journal showed 150-200 MiB written per
      # turn taking 5-30s of dead time before prefill could begin. Disable.
      cacheRamMiB = 0;
      extraFlags = [
        "--jinja"
        # Disable the multimodal projector entirely (text-only inference).
        # Frees ~1 GiB VRAM that would otherwise hold the vision encoder.
        "--no-mmproj"
        # Disable thinking by default at the server level. Qwen3.6's official
        # model card states it "does not officially support the soft switch of
        # Qwen3, i.e., /think and /nothink" — the only way to control thinking
        # is the chat template's enable_thinking jinja kwarg. Default-on is bad
        # for open-webui chat: every response generates hundreds of invisible
        # <think> tokens (unbounded — `--reasoning-budget -1` is the default)
        # before any visible content streams. Clients that want reasoning can
        # opt in per-request via OpenAI extra_body:
        #   {"chat_template_kwargs": {"enable_thinking": true}}
        # opencode/Qwen-Agent set this when reasoning is desired.
        # NOTE: llama-server's `--chat-template-kwargs '{"enable_thinking":...}'`
        # is deprecated; `--reasoning on|off` is the supported equivalent.
        "--reasoning"
        "off"
        # Sampler flags intentionally NOT set here. Qwen recommends different
        # presets per mode (thinking-general / thinking-precise / instruct) and
        # clients should set what they need. open-webui has its own UI sliders;
        # opencode's config.json sets per-provider samplers. Leaving the server
        # at llama-server defaults (temp 0.8, top_p 0.95, top_k 40, min_p 0.05)
        # produces reasonable instruct-mode chat without coding the wrong
        # preset into every conversation.
        # NOTE on speculative decoding: --spec-type ngram-mod looked promising
        # in research but Qwen3.6's hybrid GatedDeltaNet attention does NOT
        # support partial KV sequence removal (the verification primitive that
        # spec decoding needs). llama-server logs at startup:
        #   common_speculative_is_compat: the target context does not support
        #     partial sequence removal
        #   srv load_model: speculative decoding not supported by this context
        # The same architecture limitation also forces full prompt re-processing
        # on every request and disables --cache-reuse. Nothing software-side can
        # work around this until upstream llama.cpp (or Qwen) ships a different
        # KV implementation for hybrid layers. Don't add --spec-type for this
        # model. (For non-hybrid models like Qwen3-Coder-30B-A3B it would work.)
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
      # Standard MoE transformer (not hybrid) — partial KV sequence removal
      # works and --cache-reuse provides real multi-turn speedup. Keep the
      # llama-server default disk cache at 8192 MiB.
      cacheRamMiB = 8192;
      extraFlags = [
        "--jinja"
        # Sampler flags intentionally NOT set — clients should set per-request.
        # Qwen3-Coder is non-thinking by design (no <think> blocks); thinking
        # toggle does not apply. Recommended sampler from the model card if a
        # client wants to set it: temp=0.7, top_p=0.8, top_k=20, repeat=1.05.
      ];
    };

    # FAST CHAT PRIMARY (recommended once llama.cpp >= b8819 is in nixpkgs):
    # Gemma 4 26B-A4B is a MoE (3.8B active / 26B total) using alternating
    # local SWA + global attention with Shared KV Cache. Crucially this is
    # NOT a hybrid GatedDeltaNet model — partial KV sequence removal works
    # via the upstream PR #22288 fix (merged 2026-04-24, llama.cpp build
    # b8819+), so multi-turn cache reuse actually delivers "Ollama-snappy"
    # follow-up turns on the R9700. Reporter measured ~13× warm prefill
    # speedup on Gemma 4 with --swa-full.
    #
    # Quality (per unsloth model card, May 2026): MMLU-Pro 82.6, LiveCodeBench
    # v6 77.1, GPQA Diamond 82.3, Tau2 (tool use, avg of 3) 68.2, AIME 2026
    # 88.3. LMArena ~1452 for the dense 31B sibling. Native tool calling.
    # Optional thinking via enable_thinking jinja kwarg (default off).
    #
    # Performance prediction on R9700 Vulkan: MoE with only 3.8B active
    # params streamed per token → 6-8× faster decode than Qwen3.6-27B Q6_K.
    # JohnTDI-cpu's Qwen3.5-35B-A3B benchmark hit 149-164 t/s decode on the
    # R9700; expect Gemma 4 26B-A4B in the 110-160 t/s range.
    #
    # PREREQUISITES before flipping activeModel here:
    #   1. nixpkgs llama-cpp-vulkan must be build b8819+ (currently b8770).
    #      Without the PR #22288 fix you get the SAME multi-turn re-prefill
    #      penalty that hurts on Qwen3.6. Bump nixpkgs or overlay-pin first.
    #   2. The `--swa-full` flag below is REQUIRED for cache reuse to work
    #      correctly on SWA models per PR #22288. Without it the SWA layers
    #      drop their KV state every turn.
    gemma4-26b-a4b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      hfFile = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      contextSize = 131072; # 128K — comfortable at 21.7 GB weights + q8 KV
      # Standard SWA+global attention (not hybrid DeltaNet): cache reuse
      # works, disk cache is beneficial for prefix reuse across sessions.
      cacheRamMiB = 8192;
      extraFlags = [
        "--jinja"
        # Text-only — Gemma 4 has a vision encoder we don't need.
        "--no-mmproj"
        # REQUIRED for proper cache reuse on SWA models per llama.cpp PR
        # #22288 (https://github.com/ggml-org/llama.cpp/pull/22288). Without
        # this the sliding-window layers force a re-prefill every turn for
        # the same reason Qwen3.6 hybrid attention does.
        "--swa-full"
        # Disable thinking by default at the server level. Clients can opt
        # in per-request via chat_template_kwargs.enable_thinking = true.
        # Same pattern as our Qwen3.6 preset.
        "--reasoning"
        "off"
      ];
    };

    # FALLBACK 1: Gemma 4 31B dense. Same SWA + global attention as the MoE
    # but pure dense — multi-turn cache reuse works the same way (via PR
    # #22288), prefill/decode is bandwidth-bound at the 24-26 t/s range
    # (similar to Qwen3.6 dense, but WITH working cache reuse so turn-N
    # TTFT is sub-second instead of multi-second).
    #
    # When to switch here: if Gemma 4 26B-A4B's MoE routing produces
    # inconsistent answers turn-to-turn and you want the determinism of a
    # dense model with proper Gemma 4 quality. Or if the MoE variant turns
    # out to hit a separate cache-reuse bug (#21831) that #22288 didn't
    # close. LMArena 1452.
    #
    # SAME PREREQUISITES as gemma4-26b-a4b: llama.cpp b8819+ and --swa-full.
    gemma4-31b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-31B-it-Q5_K_M.gguf";
      hfRepo = "unsloth/gemma-4-31B-it-GGUF";
      hfFile = "gemma-4-31B-it-Q5_K_M.gguf";
      contextSize = 65536; # 64K — 20 GB weights + q8 KV at 128K is tight
      cacheRamMiB = 8192;
      extraFlags = [
        "--jinja"
        "--no-mmproj"
        "--swa-full"
        "--reasoning"
        "off"
      ];
    };

    # FALLBACK 2: Mistral Devstral-Small-2 24B Dense (Dec 2025 / Feb 2026
    # update). Standard dense transformer — proper KV cache reuse, no SWA
    # quirks, "snappy multi-turn" without needing the b8819 upstream fix.
    # Pure coding-focused tuning (similar lineage to Codestral). Less
    # academic-benchmark-strong than Gemma 4 / Qwen3.6 on MMLU-Pro etc.,
    # but tight on real-world dev tasks. No public Aider polyglot result
    # for this exact build yet — bring your own A/B vs Qwen3-Coder.
    #
    # When to switch here: A/B testing Mistral vs Qwen coding-family on
    # your own opencode workflow, or when you want a dense (deterministic)
    # standard-transformer coding model that doesn't depend on the SWA fix.
    devstral-small-2-24b = {
      modelFile = "/var/lib/llama-cpp/models/Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 131072; # 128K native — dense KV at q8 leaves headroom.
      cacheRamMiB = 8192;
      extraFlags = [
        "--jinja"
        # Mistral's recommended sampler (per model card): temp=0.15 for
        # code, default 0.7 otherwise. Leaving samplers unset here lets
        # clients (opencode, open-webui) choose per-request.
      ];
    };
  };

  # Change this one line to switch models. Available presets:
  #   qwen3-6-27b           dense hybrid, slowest multi-turn TTFT,
  #                           highest single-shot quality
  #   qwen3-coder-30b-a3b   MoE standard, fast multi-turn, coding-tuned
  #                           non-thinking, snappy opencode backend
  #   gemma4-26b-a4b        MoE SWA, fastest decode (110-160 t/s expected
  #                           on R9700), needs llama.cpp b8819+ & --swa-full
  #   gemma4-31b            dense SWA, ~25 t/s decode but snappy turn-N
  #                           TTFT, deterministic fallback to MoE Gemma 4
  #   devstral-small-2-24b  dense Mistral coder, snappy multi-turn,
  #                           A/B alternative to qwen3-coder-30b-a3b
  activeModel = models.gemma4-26b-a4b;

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

  # Vulkan/Mesa userspace inside the container. The Vulkan loader (libvulkan)
  # needs ICD JSON files describing the available Vulkan implementations, and
  # the driver shared libraries those JSONs point at. On NixOS this is set up
  # by `hardware.graphics.enable = true`, which populates /run/opengl-driver/.
  # Without it, llama-cpp-vulkan starts cleanly but reports "no usable GPU
  # found" because the loader has no ICD to load — even though /dev/kfd and
  # /dev/dri/renderD* are passed through by the incus profile.
  # 32-bit support is not needed in a headless server container.
  hardware.graphics.enable = true;

  networking.hostName = "llm";

  # Precreate private state dirs (root-owned. systemd will manage perms for DynamicUser)
  # These appear in the rootfs so Incus can bind-mount to them before systemd starts.
  # Mesa shader cache subdir does NOT need to be precreated — systemd's
  # CacheDirectory= ensures /var/cache/llama-cpp is writable by the DynamicUser,
  # and Mesa creates the mesa-shaders/ subdir on first run.
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
      inherit (activeModel) modelFile hfRepo hfFile contextSize cacheRamMiB extraFlags;
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
      # so the GPU backend only sees the R9700. Vulkan needs only the GPU's
      # render node (already exposed by `gputype: physical`); /dev/kfd is not
      # required and is intentionally not passed through. To switch back to
      # ROCm: set `rocm = true; vulkan = false` here AND add a `kfd:` unix-char
      # device to the incus profile.
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
