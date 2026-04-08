{ lib, config, ... }:
let
  cfg = config.mine.llama-cpp;
in
{

  options.mine.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp inference server (llama-server)";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for llama-server to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for llama-server to listen on.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Directory containing GGUF model files.
        When set, passed as --model-store to llama-server.
      '';
    };

    modelsPreset = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf (lib.types.attrsOf lib.types.str));
      default = null;
      description = ''
        Declarative model preset configuration for HuggingFace auto-download.
        Each key is a model alias, with attrs for hf-repo, hf-file, etc.
        Passed to services.llama-cpp.modelsPreset.
      '';
      example = lib.literalExpression ''
        {
          "qwen3-14b" = {
            hf-repo = "Qwen/Qwen3-14B-GGUF";
            hf-file = "qwen3-14b-q8_0.gguf";
            alias = "qwen3-14b";
          };
        }
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # GPU offload: push all transformer layers to VRAM
        "-ngl"
        "99"
        # Flash attention: disabled due to CUDA crashes on RTX 5060 Ti (compute 12.0).
        # Upstream bug: https://github.com/ggml-org/llama.cpp/issues/21289
        # Fix commit de1aa6fa is merged upstream but not yet in nixpkgs as of b8680.
        #
        # TODO: once nixpkgs llama-cpp reaches the build containing de1aa6fa (post-b8680):
        #   1. Change "--flash-attn" "off" -> "--flash-attn" "auto"
        #   2. Add "--cache-type-k" "q8_0" "--cache-type-v" "q8_0"
        #   3. Bump "-c" to "65536" (64K context fits comfortably with q8_0 KV on 16 GiB)
        #   4. Update llm.nix comment and opencode.json context limit
        # Benefits: ~5-10% generation speed, q8_0 KV halves cache VRAM, 64K context.
        "--flash-attn"
        "off"
        # Context window: 32768 tokens (~24K words). With flash_attn off, KV cache uses f16.
        # Gemma4's hybrid SWA architecture keeps the SWA portion fixed regardless of context,
        # so doubling from 16K to 32K only adds ~480 MiB VRAM (non-SWA KV scales linearly,
        # SWA stays at ~300 MiB). Total at 32K: ~14.6 GiB — fits on 16 GiB with ~1.2 GiB headroom.
        # With flash_attn + q8_0 KV, 64K would use ~14.8 GiB — upgrade when TODO above is done.
        "-c"
        "32768"
        # Parallel slots: 1 slot = all VRAM budget goes to one session.
        # Each additional slot reserves a full context window in the KV cache.
        "-np"
        "1"
      ];
      description = ''
        Extra CLI flags passed to llama-server.
        Defaults are tuned for a single-user coding workflow on a 16 GiB GPU:
        full GPU offload, quantized KV cache, 16K context, one parallel slot.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.llama-cpp = {
      enable = true;
      inherit (cfg) host port extraFlags modelsDir modelsPreset;
      openFirewall = true;
    };
  };
}
