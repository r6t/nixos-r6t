{ lib, config, pkgs, ... }:

let
  cfg = config.mine.stable-diffusion-cpp;
in
{

  options.mine.stable-diffusion-cpp = {
    enable = lib.mkEnableOption "stable-diffusion.cpp inference server (sd-server)";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "IP address for sd-server to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 1234;
      description = "Port for sd-server to listen on (default: 1234).";
    };

    modelFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to the image generation model file (.gguf or .safetensors).
        Passed as --model to sd-server. Use this for single-file models
        (e.g. SDXL, SD1.5). For multi-component models (FLUX, SD3) with
        separate diffusion model + VAE + text encoders, use extraFlags instead.
      '';
      example = "/var/lib/stable-diffusion-cpp/models/flux1-schnell-q8_0.gguf";
    };

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Directory containing model files. Used for persistent storage.";
    };

    cuda = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the CUDA backend (pkgs.stable-diffusion-cpp-cuda) for GPU-accelerated
        image generation. Requires nixpkgs.config.cudaSupport = true (set by
        mine.nvidia-cuda). Also disables MemoryDenyWriteExecute for CUDA JIT.
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional CLI flags passed to sd-server.
        Use for multi-component model specification (FLUX, SD3) or tuning options.
        Flash attention: --diffusion-fa
        Quantization type: --type q8_0
        FLUX.1-schnell example:
          [ "--diffusion-model" "/path/flux1-schnell-q8_0.gguf"
            "--vae" "/path/ae.sft"
            "--clip_l" "/path/clip_l.safetensors"
            "--t5xxl" "/path/t5xxl_fp8_e4m3fn.safetensors"
            "--diffusion-fa" ]
      '';
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to start sd-server automatically at boot (WantedBy multi-user.target).
        Set to false for on-demand use — the service is defined but not started
        automatically. Start manually with: systemctl start stable-diffusion-cpp
        Useful on gaming HTPCs where image generation runs only when games are stopped.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # sd-server systemd service.
    # When autoStart = false, the service is defined but not started at boot.
    # Conflicts with llama-cpp.service so that GPU VRAM is not double-allocated.
    # Starting sd-server automatically stops the LLM; stopping sd-server restarts it.
    systemd.services.stable-diffusion-cpp = {
      description = "stable-diffusion.cpp image generation server (sd-server)";
      after = [ "network.target" ];
      wantedBy = lib.mkIf cfg.autoStart [ "multi-user.target" ];

      # Mutual exclusion with the LLM — they share 16 GiB VRAM.
      # systemd will stop llama-cpp when sd-server is started.
      conflicts = [ "llama-cpp.service" ];

      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "10s";

        # State directory for model storage (DynamicUser-compatible private path)
        StateDirectory = "stable-diffusion-cpp";
        CacheDirectory = "stable-diffusion-cpp";
        WorkingDirectory = "/var/lib/stable-diffusion-cpp";

        ExecStart =
          let
            pkg = if cfg.cuda then pkgs.stable-diffusion-cpp-cuda else pkgs.stable-diffusion-cpp;
            args =
              [ "--listen-ip" cfg.host "--listen-port" (toString cfg.port) ] ++
              lib.optionals (cfg.modelFile != null) [ "--model" cfg.modelFile ] ++
              lib.optionals (cfg.modelsDir != null) [ "--lora-model-dir" cfg.modelsDir ] ++
              cfg.extraFlags;
          in
          "${pkg}/bin/sd-server ${lib.escapeShellArgs args}";

        # GPU access (CUDA requires /dev/nvidia* and /dev/dri/renderD*)
        PrivateDevices = false;

        # CUDA PTX JIT requires W+X memory pages
        MemoryDenyWriteExecute = lib.mkIf cfg.cuda false;

        # Allow GPU device access for DynamicUser
        SupplementaryGroups = lib.mkIf cfg.cuda [ "render" "video" ];

        # Hardening — relaxed for GPU access
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/stable-diffusion-cpp" "/var/cache/stable-diffusion-cpp" ];
      };
    };
  };
}
