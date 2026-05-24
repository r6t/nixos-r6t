{ ... }:

{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.graphics.enable = true;

  networking.hostName = "llm";

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
      cuda = true;
      host = "0.0.0.0";
      port = 8080;
      modelsDir = "/var/lib/llama-cpp/models";
      hfRepo = "unsloth/Qwen3-14B-GGUF";
      hfFile = "Qwen3-14B-Q6_K.gguf";
      contextSize = 65536; # 64K context
      cacheRamMiB = 8192; # Standard dense model supports full KV prefix reuse!
      kvCacheQuant = "q8_0";
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrls = [
        "http://localhost:8080/v1"
        "https://openrouter.ai/api/v1"
      ];
      environmentFile = "/etc/oi.env";
    };
  };
}
