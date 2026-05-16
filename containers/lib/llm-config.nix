# Plain Nix value file — no NixOS module machinery.
# Imported by both containers/llm.nix (container build) and
# hosts/mountainball/configuration.nix (opencode context window config)
# so the two stay in sync when activeModel changes.
let
  models = {
    qwen3-6-35b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
      hfRepo = "unsloth/Qwen3.6-35B-A3B-GGUF";
      hfFile = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
      # 256K native max. KV is tiny on hybrid GDN (only 5/64 layers use
      # traditional KV cache; the rest use recurrent GDN state). At q4_0 KV,
      # 256K costs only ~1.4 GB KV vs ~20 GB weights + ~2.9 GB compute graph
      # = ~24.3 GB total, well within 32 GB.
      contextSize = 262144;
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    qwen3-6-27b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-27B-Q6_K.gguf";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf";
      contextSize = 65536;
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    qwen3-30b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3-30B-A3B-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Qwen3-30B-A3B-GGUF";
      hfFile = "Qwen3-30B-A3B-UD-Q6_K_XL.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    devstral-small-2-24b = {
      modelFile = "/var/lib/llama-cpp/models/Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 98304;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };

    # gemma4-26b-a4b — commented out; uncomment to try fastest decode.
    # gemma4-26b-a4b = {
    #   modelFile = "/var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
    #   hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
    #   hfFile = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
    #   contextSize = 65536;
    #   cacheRamMiB = 8192;
    #   extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    # };
  };

  # ─────────────────────────────────────────────────────────────────────────
  # Change this one line to switch the active model.
  # containers/llm.nix reads activeModel for the server config.
  # hosts/mountainball/configuration.nix reads activeModel.contextSize
  # for the opencode provider limit, so both stay in sync automatically.
  # ─────────────────────────────────────────────────────────────────────────
  activeModel = models.qwen3-6-35b-a3b;
in
{
  inherit models activeModel;
}
