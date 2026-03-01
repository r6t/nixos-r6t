{ lib, config, pkgs, userConfig, ... }:
let
  cfg = config.mine.home.gnome-apps;
in
{

  options = {
    mine.home.gnome-apps.enable =
      lib.mkEnableOption "enable GNOME dconf settings and apps in home-manager";
    mine.home.gnome-apps.tablet =
      lib.mkEnableOption "tablet/touchscreen support (on-screen keyboard, accessibility menu)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home-manager.users.${userConfig.username} = {
        home.packages = with pkgs; [
          gnome-calculator
          gnome-system-monitor
          loupe # GNOME image viewer
          nautilus # GNOME file manager
          snapshot # GNOME camera
        ];

        dconf = {
          enable = true;
          settings = {
            # Appearance, clock, battery indicator
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "Adwaita-dark";
              cursor-theme = "Adwaita";
              icon-theme = "Adwaita";
              clock-format = "24h";
              clock-show-weekday = true;
              show-battery-percentage = true;
            };

            # Terminal preference
            "org/gnome/desktop/applications/terminal" = {
              exec = "alacritty";
              exec-arg = "-e";
            };

            # Night light (scheduled color temperature shift)
            "org/gnome/settings-daemon/plugins/color" = {
              night-light-enabled = true;
              night-light-schedule-automatic = false;
              night-light-schedule-from = 20.0;
              night-light-schedule-to = 6.0;
              night-light-temperature = lib.gvariant.mkUint32 3500;
            };

            # Touchpad: natural scrolling + tap-to-click
            "org/gnome/desktop/peripherals/touchpad" = {
              natural-scroll = true;
              tap-to-click = true;
              two-finger-scrolling-enabled = true;
            };

            # Mutter: fractional scaling + VRR
            "org/gnome/mutter" = {
              experimental-features = [
                "scale-monitor-framebuffer"
                "variable-refresh-rate"
                "xwayland-native-scaling"
              ];
            };

            # Dock favorites (order matters — Meta+1 through Meta+5 launch these)
            "org/gnome/shell" = {
              favorite-apps = [
                "org.gnome.Nautilus.desktop" # Meta+1
                "Alacritty.desktop" # Meta+2
                "firefox.desktop" # Meta+3
                "obsidian.desktop" # Meta+4
                "me.proton.Mail.desktop" # Meta+5
              ];
              # Enable appindicator (system tray) extension
              disable-user-extensions = false;
              enabled-extensions = [
                "appindicatorsupport@rgcjonas.gmail.com"
              ];
            };

            # Meta+N launches/focuses the Nth dock favorite (like KDE task manager)
            "org/gnome/shell/keybindings" = {
              switch-to-application-1 = [ "<Super>1" ];
              switch-to-application-2 = [ "<Super>2" ];
              switch-to-application-3 = [ "<Super>3" ];
              switch-to-application-4 = [ "<Super>4" ];
              switch-to-application-5 = [ "<Super>5" ];

              # Screenshot shortcuts (match customized KDE, macOS pattern)
              screenshot = [ "<Super><Shift>3" ];
              show-screenshot-ui = [ "<Super><Shift>4" ];
              show-screen-recording-ui = [ "<Super><Shift>5" ];
            };

            # Power: suspend on battery idle, nothing on AC
            "org/gnome/settings-daemon/plugins/power" = {
              sleep-inactive-ac-type = "nothing";
              sleep-inactive-battery-type = "suspend";
              sleep-inactive-battery-timeout = 600;
            };

            # Window management: add minimize/maximize buttons
            "org/gnome/desktop/wm/preferences" = {
              button-layout = "appmenu:minimize,maximize,close";
            };

            # Location services (for night light if switching to automatic later)
            "org/gnome/system/location" = {
              enabled = true;
            };

            # Disable GNOME donation nags (notifications + Settings About panel)
            "org/gnome/settings-daemon/plugins/housekeeping" = {
              donation-reminder-enabled = false;
            };
            "org/gnome/software" = {
              donation-reminder-enabled = false;
            };

            # Workspace navigation: swap PgUp/PgDown for horizontal layout
            # Meta+PgUp = right (next workspace), Meta+PgDown = left (previous)
            "org/gnome/desktop/wm/keybindings" = {
              switch-to-workspace-right = [ "<Super>Page_Up" ];
              switch-to-workspace-left = [ "<Super>Page_Down" ];
              switch-to-workspace-up = [ "disabled" ];
              switch-to-workspace-down = [ "disabled" ];
            };
          };
        };
      };
    })

    # Tablet/touchscreen: enable on-screen keyboard and accessibility menu
    (lib.mkIf (cfg.enable && cfg.tablet) {
      home-manager.users.${userConfig.username}.dconf.settings = {
        "org/gnome/desktop/a11y/applications" = {
          screen-keyboard-enabled = true;
        };
        "org/gnome/desktop/a11y" = {
          always-show-universal-access-status = true;
        };
      };
    })
  ];
}
