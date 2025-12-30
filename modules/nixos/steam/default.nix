{ lib, config, pkgs, ... }:

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
      mangohud
      gamemode
      gamescope # Isolated compositor for local gaming
      protonup-qt
      moonlight-qt # Sunshine/Moonlight streaming client
    ];

    # Enable Gamemode (System-level optimization)
    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;

      # "Black Box" Sandbox Override
      # Binds ~/steam-sandbox to /home/user inside the steam namespace.
      # Steam sees this as home; it cannot access real files.
      package = pkgs.steam.override {
        extraBwrapArgs = [
          "--bind"
          "/home/r6t/steam-sandbox"
          "/home/r6t"
        ];
      };

      extest.enable = true; # Controller compatibility
    };

    # Realtime scheduling permissions for games
    # Required because Steam runs in bubblewrap sandbox where capabilities don't work
    security.pam.loginLimits = [
      { domain = "@gamemode"; item = "nice"; type = "-"; value = "-20"; }
      { domain = "r6t"; item = "rtprio"; type = "-"; value = "98"; }
      { domain = "r6t"; item = "nice"; type = "-"; value = "-20"; }
      { domain = "r6t"; item = "memlock"; type = "-"; value = "unlimited"; }
    ];
  };
}
