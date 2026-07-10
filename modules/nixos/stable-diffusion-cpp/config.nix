{ lib, config, pkgs, ... }:

let
  cfg = config.mine.stable-diffusion-cpp;
in
{
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
            [ "--listen-ip" cfg.host "--listen-port" (toString cfg.port) ]
            ++ lib.optionals (cfg.modelFile != null) [ "--model" cfg.modelFile ]
            ++ lib.optionals (cfg.modelsDir != null) [ "--lora-model-dir" cfg.modelsDir ]
            ++ cfg.extraFlags;
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
}
