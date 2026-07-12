{ ... }:

{
  imports = [
    ../modules/nixos/docker/default.nix
    ../modules/nixos/llama-cpp/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
    nvidia.acceptLicense = true;
  };

  hardware.graphics.enable = true;

  mine.docker.enable = true;

  mine.llama-cpp = {
    enable = true;
    cuda = true;
    host = "0.0.0.0";
    port = 8080;
    hfRepo = "unsloth/Qwen3.6-35B-A3B-MTP-GGUF";
    hfFile = "Qwen3.6-35B-A3B-UD-Q4_K_XL.gguf";
    modelsDir = "/var/lib/llama-cpp/models";
    alias = "Qwen3.6-35B-A3B-MTP-UD-Q4_K_XL";
    contextSize = 131072;
    kvCacheQuant = "q8_0";
    batchSize = 1024;
    ubatchSize = 1024;
    cacheRamMiB = 0;
    extraFlags = [
      "--jinja"
      "--fit"
      "on"
      "--fit-target"
      "1536"
      "--n-cpu-moe"
      "12"
      "--no-mmproj"
      "--spec-type"
      "draft-mtp"
      "--spec-draft-n-max"
      "2"
      "--temp"
      "0.6"
      "--top-p"
      "0.95"
      "--top-k"
      "20"
      "--min-p"
      "0.0"
    ];
  };

  networking.hostName = "llm";

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
    "d /var/lib/private/open-webui 0700 root root -"
    "d /var/lib/llama-cpp 0755 root root -"
    "d /var/lib/llama-cpp/models 0755 root root -"
    "d /var/cache/private 0700 root root -"
    "d /var/cache/llama-cpp 0755 root root -"
  ];

  systemd.services.docker-open-webui = {
    after = [ "llama-cpp.service" ];
    wants = [ "llama-cpp.service" ];
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers."open-webui" = {
      image = "ghcr.io/open-webui/open-webui:main";
      pull = "always";
      environmentFiles = [ "/etc/oi.env" ];
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        HOST = "0.0.0.0";
        OPENAI_API_BASE_URLS = "http://localhost:8080/v1;https://openrouter.ai/api/v1";
        PORT = "8087";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_AUTH = "True";
      };
      volumes = [
        "/var/lib/private/open-webui:/app/backend/data"
      ];
      networks = [ "host" ];
    };
  };
}
