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
        "qwen3-14b" = {
          hf-repo = "unsloth/Qwen3-14B-GGUF";
          hf-file = "Qwen3-14B-Q8_0.gguf";
          alias = "qwen3-14b";
        };
        # Gemma 4 26B MoE (4B active params). UD-IQ4_XS fits 16GB VRAM with
        # headroom for f16 KV cache at 32K context (~1.2 GB free after model load).
        # KV quantization (q8_0) requires flash_attn, which is disabled due to
        # an upstream CUDA bug on RTX 5060 Ti (see llama-cpp module extraFlags).
        "gemma4-26b" = {
          hf-repo = "unsloth/gemma-4-26B-A4B-it-GGUF";
          hf-file = "gemma-4-26B-A4B-it-UD-IQ4_XS.gguf";
          alias = "gemma4-26b";
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
