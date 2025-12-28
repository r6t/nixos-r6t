{ lib, config, pkgs, ... }:
let
  # Gamescope wrapper profiles for Z13 with optional AOC U27G3X external display
  #
  # Hardware:
  #   - Z13 internal: 2560x1600 @ 180Hz (16:10)
  #   - AOC U27G3X:   3840x2160 @ 160Hz (16:9) - used at 1440p
  #
  # Profiles:
  #   - gamescope-auto: Native resolution (1440p@160 on AOC, 1600p@180 on Z13)
  #   - gamescope-fsr:  FSR upscaling (1080p→1440p on AOC, 1200p→1600p on Z13)
  #
  # All wrappers:
  #   - Detect if already inside gamescope (e.g., gamescopeSession) and pass
  #     through directly to avoid nested instances
  #   - Auto-detect display via EDID
  #   - Use: --rt, --adaptive-sync, --fullscreen, --force-grab-cursor, --mangoapp

  # Helper to detect if already running inside gamescope
  detectNestedGamescope = ''
    if [ -n "''${GAMESCOPE_WAYLAND_DISPLAY:-}" ]; then
      exec "$@"
    fi
  '';

  # Helper to detect AOC U27G3X via EDID
  detectAoc = ''
    AOC_FOUND=0
    for edid in /sys/class/drm/card*-DP-*/edid /sys/class/drm/card*-HDMI-*/edid; do
      if [ -f "$edid" ]; then
        if tr -cd '[:print:]' < "$edid" 2>/dev/null | grep -q "U27G3X"; then
          AOC_FOUND=1
          break
        fi
      fi
    done
  '';

  commonFlags = ''
    --rt \
    --adaptive-sync \
    --fullscreen \
    --force-grab-cursor \
    --mangoapp'';

  # gamescope-auto: Native resolution
  # AOC: 2560x1440 @ 160Hz | Z13: 2560x1600 @ 180Hz
  gamescope-auto = pkgs.writeShellScriptBin "gamescope-auto" ''
    ${detectNestedGamescope}
    ${detectAoc}

    if [ "$AOC_FOUND" -eq 1 ]; then
      exec ${pkgs.gamescope}/bin/gamescope \
        -w 2560 -h 1440 -W 2560 -H 1440 -r 160 \
        ${commonFlags} -- "$@"
    else
      exec ${pkgs.gamescope}/bin/gamescope \
        -W 2560 -H 1600 -r 180 \
        ${commonFlags} -- "$@"
    fi
  '';

  # gamescope-fsr: FSR upscaling from 1080p/1200p
  # AOC: 1920x1080 → FSR → 2560x1440 @ 160Hz | Z13: 1920x1200 → FSR → 2560x1600 @ 180Hz
  gamescope-fsr = pkgs.writeShellScriptBin "gamescope-fsr" ''
    ${detectNestedGamescope}
    ${detectAoc}

    if [ "$AOC_FOUND" -eq 1 ]; then
      exec ${pkgs.gamescope}/bin/gamescope \
        -w 1920 -h 1080 -W 2560 -H 1440 -r 160 -F fsr \
        ${commonFlags} -- "$@"
    else
      exec ${pkgs.gamescope}/bin/gamescope \
        -w 1920 -h 1200 -W 2560 -H 1600 -r 180 -F fsr \
        ${commonFlags} -- "$@"
    fi
  '';
in
{

  options = {
    mine.steam.enable =
      lib.mkEnableOption "enable sandboxed steam with performance optimizations";
  };

  config = lib.mkIf config.mine.steam.enable {
    environment.systemPackages = with pkgs; [
      steam-devices-udev-rules
      gamescope-auto
      gamescope-fsr
      mangohud
      gamemode
      protonup-qt
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

      gamescopeSession.enable = true; # Session entry for Steam+Gamescope
      extest.enable = true; # Controller compatibility
    };

    # Realtime scheduling permissions for gamescope --rt flag
    # (capabilities don't work inside Steam's bubblewrap sandbox)
    security.pam.loginLimits = [
      { domain = "@gamemode"; item = "nice"; type = "-"; value = "-20"; }
      { domain = "r6t"; item = "rtprio"; type = "-"; value = "98"; }
      { domain = "r6t"; item = "nice"; type = "-"; value = "-20"; }
      { domain = "r6t"; item = "memlock"; type = "-"; value = "unlimited"; }
    ];
  };
}
