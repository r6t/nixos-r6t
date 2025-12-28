{ lib, config, pkgs, ... }:
let
  # Gamescope wrapper profiles for Z13 with optional AOC U27G3X external display
  #
  # Hardware:
  #   - Z13 internal: 2560x1600 @ 180Hz (16:10)
  #   - AOC U27G3X:   3840x2160 @ 160Hz (16:9, 4K)
  #
  # All wrappers use:
  #   --rt: Realtime scheduling (enabled via PAM limits, not capabilities)
  #   --adaptive-sync: VRR/FreeSync for smooth frame pacing
  #   --fullscreen: Dedicated fullscreen mode
  #   --force-grab-cursor: Keep cursor inside game window
  #   --mangoapp: MangoHud overlay support

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

  # Common flags used by all profiles
  commonFlags = ''
    --rt \
    --adaptive-sync \
    --fullscreen \
    --force-grab-cursor \
    --mangoapp'';

  # =============================================================================
  # gamescope - General purpose auto-detecting wrapper
  # =============================================================================
  # AOC present: 2560x1440 render @ 160Hz (good balance of perf/quality on 4K panel)
  # Z13 only:    2560x1600 native @ 180Hz
  gamescope-wrapper = pkgs.writeShellScriptBin "gamescope" ''
    ${detectAoc}

    if [ "$AOC_FOUND" -eq 1 ]; then
      exec ${pkgs.gamescope}/bin/gamescope \
        -w 2560 -h 1440 \
        -W 2560 -H 1440 -r 160 \
        ${commonFlags} \
        -- "$@"
    else
      exec ${pkgs.gamescope}/bin/gamescope \
        -W 2560 -H 1600 -r 180 \
        ${commonFlags} \
        -- "$@"
    fi
  '';

  # =============================================================================
  # gamescope-1080fsr - Max performance profile with FSR upscaling
  # =============================================================================
  # AOC present: 1920x1080 render → FSR → 2560x1440 output @ 160Hz
  # Z13 only:    1920x1200 render → FSR → 2560x1600 output @ 180Hz
  gamescope-1080fsr = pkgs.writeShellScriptBin "gamescope-1080fsr" ''
    ${detectAoc}

    if [ "$AOC_FOUND" -eq 1 ]; then
      exec ${pkgs.gamescope}/bin/gamescope \
        -w 1920 -h 1080 \
        -W 2560 -H 1440 -r 160 \
        -F fsr \
        ${commonFlags} \
        -- "$@"
    else
      exec ${pkgs.gamescope}/bin/gamescope \
        -w 1920 -h 1200 \
        -W 2560 -H 1600 -r 180 \
        -F fsr \
        ${commonFlags} \
        -- "$@"
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
      # Gamescope profiles (gamescope-wrapper shadows the base 'gamescope' command)
      gamescope-wrapper # Auto-detect: 1440p@160 (AOC) or native@180 (Z13)
      gamescope-1080fsr # Auto-detect: 1080p FSR upscale for max performance
      mangohud # Performance overlay
      gamemode # System optimization daemon
      protonup-qt # Proton version manager
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
