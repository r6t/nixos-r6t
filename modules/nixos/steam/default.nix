{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.steam;
in
{

  options.mine.steam = {
    enable = lib.mkEnableOption "enable nixos gaming with moonlight client and sandboxed steam";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      steam-devices-udev-rules
      steam-run # Run non-Steam games/tools with Steam runtime
      moonlight-qt # Sunshine/Moonlight streaming client
    ];

    # Enable Gamemode (System-level optimization)
    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;

      # Inject packages into the Steam FHS environment (64-bit targetPkgs)
      # These are visible inside the bubblewrap sandbox at /usr/bin and /usr/lib
      extraPackages = with pkgs; [
        mangohud
        gamemode
        gamescope
      ];

      # Bubblewrap sandbox hardening
      # The NixOS steam wrapper auto-mounts every top-level directory (except
      # /nix, /dev, /proc, /etc, /tmp) read-write into the namespace.
      # extraBwrapArgs are appended after auto_mounts, so later --bind/--tmpfs
      # directives override earlier ones for the same path.
      package = pkgs.steam.override {
        # Inject MangoHud into multiPkgs so both 32-bit and 64-bit Vulkan
        # layer libraries are available inside the FHS namespace
        extraLibraries = pkgs: [ pkgs.mangohud ];
        extraBwrapArgs = [
          # Redirect home to an isolated sandbox directory
          "--bind"
          "/home/${userConfig.username}/steam-sandbox"
          "/home/${userConfig.username}"
          # Hide everything behind /mnt (LUKS volumes, external drives, etc.)
          "--tmpfs"
          "/mnt"
        ];
      };

      extraCompatPackages = [
        pkgs.proton-ge-bin # Declarative Proton-GE via STEAM_EXTRA_COMPAT_TOOLS_PATHS
      ];

      extest.enable = true; # Controller compatibility
    };

    # Ensure the sandbox home directory exists with correct ownership
    systemd.tmpfiles.rules = [
      "d /home/${userConfig.username}/steam-sandbox 0755 ${userConfig.username} users -"
    ];

    # Realtime scheduling permissions for games
    # Required because Steam runs in bubblewrap sandbox where capabilities don't work
    security.pam.loginLimits = [
      { domain = "@gamemode"; item = "nice"; type = "-"; value = "-20"; }
      { domain = userConfig.username; item = "rtprio"; type = "-"; value = "98"; }
      { domain = userConfig.username; item = "nice"; type = "-"; value = "-20"; }
      { domain = userConfig.username; item = "memlock"; type = "-"; value = "unlimited"; }
    ];
  };
}
