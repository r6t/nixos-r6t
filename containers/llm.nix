let
  gpu = import ../hosts/crown/gpu.nix;
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
      modelsDir = "/var/lib/llama-cpp/models";
      modelsPreset = {
        # Qwen3-14B Q6_K: ~12.1 GiB weights, fits comfortably on 16 GiB with
        # room for q8_0 KV cache at 64K context. Dense model, excellent for
        # coding and agentic use. Supports /think and /no_think mode switching.
        "qwen3-14b" = {
          hf-repo = "unsloth/Qwen3-14B-GGUF";
          hf-file = "Qwen3-14B-Q6_K.gguf";
          alias = "qwen3-14b";
        };
      };
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrl = "http://localhost:8080/v1";
    };
  };
}
