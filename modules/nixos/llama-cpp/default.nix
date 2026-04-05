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
        # Re-test with "auto" or "on" after llama.cpp updates; the ~5-10% generation
        # speed gain is worth reclaiming once the kernel bug is fixed.
        "--flash-attn"
        "off"
        # KV cache quantization: q8_0 halves KV memory vs f16 with negligible
        # quality loss. Frees VRAM headroom for larger context or bigger models.
        # For even more aggressive savings, try q4_0 (quarter size, slight quality cost).
        "--cache-type-k"
        "q8_0"
        "--cache-type-v"
        "q8_0"
        # Context window: 16384 tokens (~12K words). Fits the q8_0 KV cache (~340 MiB)
        # in VRAM alongside a 14B Q8_0 model (~15 GiB) on 16 GiB VRAM, avoiding any
        # PCIe round-trips. For heavier context needs, bump to 32768 but KV will spill
        # to system RAM (~8 GB/s on this PCIe x4 link = slower generation).
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
