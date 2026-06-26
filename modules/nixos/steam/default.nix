{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.steam;
  goldenballSteamProfile = pkgs.writeShellApplication {
    name = "goldenball-steam-profile";
    runtimeInputs = with pkgs; [
      gamemode
      gamescope
      mangohud
    ];
    text = ''
      set -euo pipefail

      usage() {
        cat <<'EOF'
      Usage: goldenball-steam-profile [--dry-run] <profile> -- <steam command...>

      Profiles:
        native-16x10-1920x1200     GameMode + MangoHud, appends -resx/-resy
        native-16x9-1920x1080      GameMode + MangoHud, appends -resx/-resy
        gamescope-16x10-1920x1200  Windowed Gamescope, game sees 1920x1200
        gamescope-16x9-1920x1080   Windowed Gamescope, game sees 1920x1080

      Steam launch option example:
        goldenball-steam-profile native-16x10-1920x1200 -- %command%
      EOF
      }

      dry_run=0
      if [ "''${1:-}" = "--dry-run" ]; then
        dry_run=1
        shift
      fi

      profile="''${1:-}"
      strategy=""
      aspect=""
      game_width=""
      game_height=""

      case "$profile" in
        native-16x10-1920x1200)
          strategy="native"
          aspect="16:10"
          game_width=1920
          game_height=1200
          ;;
        native-16x9-1920x1080)
          strategy="native"
          aspect="16:9"
          game_width=1920
          game_height=1080
          ;;
        gamescope-16x10-1920x1200)
          strategy="gamescope"
          aspect="16:10"
          game_width=1920
          game_height=1200
          ;;
        gamescope-16x9-1920x1080)
          strategy="gamescope"
          aspect="16:9"
          game_width=1920
          game_height=1080
          ;;
        *)
          printf 'Unknown profile: %s\n' "$profile" >&2
          usage >&2
          exit 2
          ;;
      esac
      shift

      if [ "''${1:-}" != "--" ]; then
        usage >&2
        exit 2
      fi
      shift

      if [ "$#" -eq 0 ]; then
        printf 'No Steam command supplied. Use %%command%% after -- in Steam launch options.\n' >&2
        exit 2
      fi

      if [ "$strategy" = "native" ]; then
        launch_command=(gamemoderun mangohud "$@" "-resx=$game_width" "-resy=$game_height")
      else
        gamescope_args=(
          --backend wayland
          --output-width "$game_width"
          --output-height "$game_height"
          --nested-width "$game_width"
          --nested-height "$game_height"
          --scaler fit
          --mangoapp
          --force-windows-fullscreen
        )
        launch_command=(gamemoderun gamescope "''${gamescope_args[@]}" -- "$@")
      fi

      if [ "$dry_run" -eq 1 ]; then
        printf 'profile=%s\n' "$profile"
        printf 'strategy=%s\n' "$strategy"
        printf 'aspect=%s\n' "$aspect"
        printf 'resolution=%sx%s\n' "$game_width" "$game_height"
        printf 'command:'
        printf ' %q' "''${launch_command[@]}"
        printf '\n'
        exit 0
      fi

      exec "''${launch_command[@]}"
    '';
  };
in
{

  options.mine.steam = {
    enable = lib.mkEnableOption "enable nixos gaming with moonlight client and sandboxed steam";

    goldenballGameLauncher.enable = lib.mkEnableOption "goldenball-specific Steam game launcher profiles";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = (with pkgs; [
      steam-devices-udev-rules
      steam-run # Run non-Steam games/tools with Steam runtime
      moonlight-qt # Sunshine/Moonlight streaming client
    ]) ++ lib.optional cfg.goldenballGameLauncher.enable goldenballSteamProfile;

    # Enable Gamemode (System-level optimization)
    programs.gamemode.enable = true;

    programs.steam = {
      enable = true;

      # Inject packages into the Steam FHS environment (64-bit targetPkgs)
      # These are visible inside the bubblewrap sandbox at /usr/bin and /usr/lib
      extraPackages = (with pkgs; [
        mangohud
        gamemode
        gamescope
      ]) ++ lib.optional cfg.goldenballGameLauncher.enable goldenballSteamProfile;

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
