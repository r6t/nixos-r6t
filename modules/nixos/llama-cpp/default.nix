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
        # Upstream bug: https://github.com/ggml-org/llama.cpp/issues/21289 (still open as of b8680).
        # Re-enable with "auto" once the bug is fixed — ~5-10% generation speed gain.
        # NOTE: gemma4 requires flash_attn for KV cache quantization; with flash_attn off,
        # KV cache quantization flags are omitted and gemma4 uses f16 KV (~1.3 GB more VRAM).
        "--flash-attn"
        "off"
        # Context window: 16384 tokens (~12K words). With flash_attn off, KV cache uses f16
        # (~680 MiB at 16K context) — fits alongside both qwen3-14b Q8_0 (~15 GiB) and
        # gemma4-26b IQ4_XS (~12.5 GiB) on 16 GiB VRAM with comfortable headroom.
        "-c"
        "16384"
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
