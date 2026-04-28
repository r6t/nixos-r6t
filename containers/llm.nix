let
  gpu = import ../hosts/crown/gpu.nix;

  # ---------------------------------------------------------------------------
  # Model catalogue (16 GiB RTX 5060 Ti, verified April 2026).
  # All models accumulate on persistent storage at:
  #   crown host:    /mnt/crownstore/app-storage/llama-cpp/models/
  #   container:     /var/lib/llama-cpp/models/
  # Pre-download: drop the GGUF into the host path above.
  # On first start, llama-server auto-downloads from HF if not present.
  #
  # To switch models, change `activeModel` to one of the keys below.
  # ---------------------------------------------------------------------------
  models = {
    # Dense. Best all-rounder: coding, agentic tool calling, multi-turn chat.
    # Supports /think and /no_think per prompt. 64K ctx ~14.1 GiB total.
    qwen3-14b = {
      modelFile = /var/lib/llama-cpp/models/Qwen3-14B-Q6_K.gguf;
      hfRepo = "unsloth/Qwen3-14B-GGUF";
      hfFile = "Qwen3-14B-Q6_K.gguf";
      contextSize = 65536;
      extraFlags = [ ];
    };

    # Mistral's coding-specialized model. Agentic software dev tasks.
    # 32K ctx (not 64K) required for VRAM headroom. 32K ctx ~14.5 GiB total.
    devstral-small-2 = {
      modelFile = /var/lib/llama-cpp/models/Devstral-Small-2-24B-Instruct-2512-Q4_K_M.gguf;
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-Q4_K_M.gguf";
      contextSize = 32768;
      extraFlags = [ "--jinja" ];
    };

    # Dense 14B. Outperforms DeepSeek-R1-70B on math/coding benchmarks.
    # Best for hard algorithmic problems. English-only. 64K ctx ~14.0 GiB total.
    phi4-reasoning-plus = {
      modelFile = /var/lib/llama-cpp/models/Phi-4-reasoning-plus-Q6_K.gguf;
      hfRepo = "unsloth/Phi-4-reasoning-plus-GGUF";
      hfFile = "Phi-4-reasoning-plus-Q6_K.gguf";
      contextSize = 65536;
      extraFlags = [ "--jinja" ];
    };

    # MoE (4B active params). Newest model (Mar 2026). General chat, creative tasks.
    # Less proven for agentic coding vs Qwen3/Devstral. 64K ctx ~14.5 GiB total.
    gemma4-26b = {
      modelFile = /var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-IQ4_XS.gguf;
      hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      hfFile = "gemma-4-26B-A4B-it-UD-IQ4_XS.gguf";
      contextSize = 65536;
      extraFlags = [ ];
    };
  };

  # Change this one line to switch models:
  # qwen3-14b | devstral-small-2 | phi4-reasoning-plus | gemma4-26b
  activeModel = models.qwen3-14b;

in
{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

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
    nvidia-cuda = {
      enable = true;
      package = gpu.driverPackage;
      installCudaToolkit = false;
    };
    llama-cpp = {
      enable = true;
      host = "0.0.0.0";
      modelsDir = /var/lib/llama-cpp/models;
      inherit (activeModel) modelFile hfRepo hfFile contextSize extraFlags;
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrl = "http://localhost:8080/v1";
    };
  };
}
