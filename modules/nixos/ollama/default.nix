let
  ollamaPort = 11434;
in

{ lib, config, pkgs, ... }:
let
  cfg = config.mine.ollama;
in
{

  options.mine.ollama = {
    enable =
      lib.mkEnableOption "enable ollama";

    acceleration = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "cuda" "rocm" "vulkan" ]);
      default = null;
      description = ''
        GPU acceleration backend.
        - cuda: NVIDIA GPUs (uses ollama-cuda package)
        - rocm: AMD GPUs (uses ollama-rocm package)
        - vulkan: Generic GPU acceleration (uses ollama-vulkan package).
          Works on AMD iGPUs where the ROCm HIP backend segfaults (e.g. gfx1151 Strix Halo).
        - null: CPU only (uses base ollama package)
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for ollama to listen on.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Models to preload on startup.";
    };

    environmentVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Extra environment variables passed to the ollama service.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package =
        if cfg.acceleration == "cuda" then pkgs.ollama-cuda
        else if cfg.acceleration == "rocm" then pkgs.ollama-rocm
        else if cfg.acceleration == "vulkan" then pkgs.ollama-vulkan
        else pkgs.ollama;
      host = cfg.host;
      port = ollamaPort;
      loadModels = cfg.models;
      environmentVariables = cfg.environmentVariables;
    };

    # ROCm's HIP runtime JIT-compiles GPU kernels, which requires W+X memory pages.
    # The upstream nixpkgs ollama module sets MemoryDenyWriteExecute=true, which
    # causes a SIGSEGV when the JIT returns null.
    systemd.services.ollama.serviceConfig = lib.mkIf (cfg.acceleration == "rocm") {
      MemoryDenyWriteExecute = lib.mkForce false;
    };
  };
}
