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
            hf-repo = "unsloth/Qwen3-14B-GGUF";
            hf-file = "Qwen3-14B-Q6_K.gguf";
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
        # Flash attention: enabled. Fix for CUDA buffer overlap crash on RTX 5060 Ti
        # (compute 12.0) landed in llama.cpp commit de1aa6fa, present in nixpkgs b8733+.
        "--flash-attn"
        "auto"
        # KV cache quantization: q8_0 halves KV cache VRAM vs f16.
        # Requires flash_attn (enabled above).
        "--cache-type-k"
        "q8_0"
        "--cache-type-v"
        "q8_0"
        # Context window: 65536 tokens (~48K words). Qwen3-14B Q6_K uses ~12.1 GiB
        # weights; q8_0 KV at 64K adds ~2 GiB — fits on 16 GiB with ~1.5 GiB headroom.
        "-c"
        "65536"
        # Parallel slots: 1 slot = all VRAM budget goes to one session.
        # Each additional slot reserves a full context window in the KV cache.
        "-np"
        "1"
      ];
      description = ''
        Extra CLI flags passed to llama-server.
        Defaults are tuned for a single-user coding workflow on a 16 GiB GPU:
        full GPU offload, q8_0 KV cache, 64K context, one parallel slot.
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
