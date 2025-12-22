{ lib, config, pkgs, ... }: {

  options = {
    mine.steam.enable =
      lib.mkEnableOption "enable sandboxed steam with performance optimizations";
  };

  config = lib.mkIf config.mine.v4l-utils.enable {
    environment.systemPackages = with pkgs; [
      steam-devices-udev-rules
      gamescope # Micro-compositor for better frame pacing/latency
      mangohud # Overlay for performance monitoring
      gamemode # daemon to optimize system performance on demand
      protonup-qt
    ];
    # Enable Gamemode (System-level optimization)
    programs.gamemode.enable = true;
    programs.steam = {
      enable = true;

      # "Black Box" Sandbox Override
      # This binds your Sandbox folder to /home/user inside the steam namespace.
      # Steam sees this as your home; it cannot access your real files.
      package = pkgs.steam.override {
        extraBwrapArgs = [
          "--bind"
          "/home/r6t/steam-sandbox"
          "/home/r6t"
        ];
      };

      # 3. System-level optimizations
      gamescopeSession.enable = true; # Adds a session entry for Steam+Gamescope
      extest.enable = true; # Improves controller compatibility
    };


    # Fix gamemode priority warnings
    security.pam.loginLimits = [
      { domain = "@gamemode"; item = "nice"; type = "-"; value = "-20"; }
    ];
  };
}
