{ lib, config, pkgs, ... }: {
  options = {
    mine.home.hyprland.enable = lib.mkEnableOption "enable hyprland with native config and ecosystem";
  };

  config = lib.mkIf config.mine.home.hyprland.enable {
    home-manager.users.r6t = {
      # Main Hyprland config
      wayland.windowManager.hyprland = {
        enable = true;
        settings = {
          env = [ "XCURSOR_THEME,Adwaita" ];

          # host-specific stuff like this should be parameterized and set in host declaration
          monitor = [
            "desc:AOC U27G3X WGKP7HA002471,3840x2160@160.00,1404x0,1.5"
            "desc:BOE NE135A1M-NY1,2880x1920@120.000,1973x1440,2.0"
          ];

          input = {
            kb_layout = "us";
            follow_mouse = 1;
            touchpad.natural_scroll = true;
            sensitivity = 0;
          };

          general = {
            gaps_in = 5;
            gaps_out = 10;
            border_size = 2;
            "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
            "col.inactive_border" = "rgba(595959aa)";
            layout = "dwindle";
            allow_tearing = false;
          };

          decoration = {
            rounding = 10;
            blur = {
              enabled = true;
              size = 3;
              passes = 1;
            };
          };

          # animations = {
          #   enabled = true;
          #   bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          #   animation = [
          #     "windows, 1, 7, myBezier"
          #     "windowsOut, 1, 7, default, popin 80%"
          #     "border, 1, 10, default"
          #     "borderangle, 1, 8, default"
          #     "fade, 1, 7, default"
          #     "workspaces, 1, 6, default"
          #   ];
          # };

          # dwindle = {
          #   pseudotile = true;
          #   preserve_split = true;
          # };

          misc = {
            disable_splash_rendering = true;
            force_default_wallpaper = 0;
            disable_hyprland_logo = true;
          };

          "$mainMod" = "SUPER";
          "$altMod" = "ALT";
          "$ctrlMod" = "CONTROL";

          bind = [
            # Media keys
            ", XF86AudioRaiseVolume, exec, pamixer --increase 5"
            ", XF86AudioLowerVolume, exec, pamixer --decrease 5"
            ", XF86AudioMute, exec, pamixer --toggle-mute"
            ", XF86AudioPlay, exec, playerctl play-pause"
            ", XF86AudioNext, exec, playerctl next"
            ", XF86AudioPrev, exec, playerctl previous"
            ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
            ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

            # App shortcuts
            "$mainMod, return, exec, alacritty"
            "$mainMod, space, exec, rofi -show drun"
            "$mainMod, C, exec, rofi -show calc -modi calc -no-show-match -no-sort"
            "$ctrlMod, space, exec, rofimoji"
            "$mainMod, Q, killactive"
            "$mainMod, E, exec, rofi -modi emoji -show emoji -kb-custom-1 Ctrl+c"
            "$mainMod SHIFT, E, exit"
            "$mainMod SHIFT, R, exec, hyprctl reload"
            "$mainMod SHIFT, L, exec, hyprlock"
            "$mainMod SHIFT, T, exec, sudo shutdown now"
            "$mainMod SHIFT, 4, exec, sh -c 'f=~/screenshots/screenshot-$(date +%Y-%m-%d-%H%M%S).png; grim -g \"$(slurp)\" \"$f\" && wl-copy < \"$f\"'"
            "$mainMod, K, exec, krusader"
            "$mainMod, V, togglefloating"
            "$mainMod, P, pseudo"
            "$mainMod, J, togglesplit"

            # Focus
            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"

            # Workspaces
            "$mainMod, S, togglespecialworkspace, magic"
            "$mainMod SHIFT, S, movetoworkspace, special:magic"
          ] ++ (
            # Generate workspace binds
            builtins.concatLists (builtins.genList
              (i:
                let ws = toString (i + 0);
                in [
                  "$mainMod, ${ws}, workspace, ${ws}"
                  "$ctrlMod SHIFT, ${ws}, movetoworkspace, ${ws}"
                ]
              ) 9)
          );

          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          "exec-once" = [
            "blueman-applet"
            "hyprpaper"
            "pgrep -x waybar || waybar"
          ];
        };
      };


      programs = {
        # Hyprlock - screen locker
        hyprlock = {
          enable = true;
          settings = {
            background = [
              {
                monitor = "";
                color = "rgba(0, 0, 0, 1.0)";
                blur_passes = 0;
                blur_size = 7;
                noise = 0.0117;
                contrast = 0.8916;
                brightness = 0.8172;
                vibrancy = 0.1696;
                vibrancy_darkness = 0.0;
              }
            ];

            input-field = [
              {
                monitor = "";
                size = "200, 50";
                outline_thickness = 3;
                dots_size = 0.33;
                dots_spacing = 0.15;
                dots_center = false;
                dots_rounding = -1;
                outer_color = "rgb(151515)";
                inner_color = "rgb(200, 200, 200)";
                font_color = "rgb(10, 10, 10)";
                fade_on_empty = true;
                fade_timeout = 1000;
                placeholder_text = "<i>Input Password...</i>";
                hide_input = false;
                rounding = -1;
                check_color = "rgb(204, 136, 34)";
                fail_color = "rgb(204, 34, 34)";
                fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
                fail_transition = 300;
                capslock_color = -1;
                numlock_color = -1;
                bothlock_color = -1;
                invert_numlock = false;
                swap_font_color = false;
                position = "0, -20";
                halign = "center";
                valign = "center";
              }
            ];
          };
        };

        # Rofi - application launcher
        rofi = {
          enable = true;
          cycle = true;
          plugins = [
            pkgs.rofi-calc
            pkgs.rofi-emoji
          ];
          theme = "~/.local/share/rofi/themes/rounded-purple-dark.rasi";
        };

        # Waybar - status bar
        waybar = {
          enable = true;
          settings = {
            mainBar = {
              output = [ "eDP-1" ];
              layer = "top";
              position = "bottom";
              height = 36;

              modules-left = [
                "hyprland/workspaces"
                "hyprland/window"
                "custom/media"
                "mpd"
              ];
              modules-center = [
                "tray"
                "clock"
              ];
              modules-right = [
                "idle_inhibitor"
                "custom/bluetooth"
                "pulseaudio"
                "backlight"
                "custom/cpupower"
                "memory"
                "network"
                "battery"
              ];


              "hyprland/workspaces" = {
                format = "{icon}";
                format-icons = {
                  "1" = "1";
                  "2" = "2";
                  "3" = "3";
                  "4" = "4";
                  "5" = "5";
                  "6" = "6";
                  "7" = "7";
                  "8" = "8";
                  "9" = "9";
                  "10" = "10";
                  default = "1";
                };
                on-click = "activate";
                on-scroll-up = "hyprctl dispatch workspace e+1";
                on-scroll-down = "hyprctl dispatch workspace e-1";
                all-outputs = true;
                separate-outputs = true;
              };

              idle_inhibitor = {
                format = "{icon}";
                format-icons = {
                  activated = "🕶";
                  deactivated = "👓";
                };
                timeout = 120;
              };

              clock = {
                format = "{:%A, %B %d | %H:%M}";
                tooltip = false;
              };

              pulseaudio = {
                format = "{volume:2} 🔊";
                format-bluetooth = "{volume} 🎧";
                format-muted = "MUTE 🔇";
                scroll-step = 5;
                on-click = "pamixer -t";
                on-click-right = "pavucontrol";
              };

              backlight = {
                format = "{percent} 🔦";
                on-click = "~/.config/waybar/brightness-menu.sh";
              };

              "custom/bluetooth" = {
                exec = "~/.config/waybar/bluetooth.sh";
                interval = 5;
                format = "{}";
                on-click = "blueman-manager";
                return-type = "json";
                tooltip = false;
              };

              "custom/cpupower" = {
                exec = "~/.config/waybar/powerprofile.sh";
                interval = 5;
                format = "{}";
                on-click = "~/.config/waybar/powerprofile_cycle.sh";
                tooltip = true;
                return-type = "json";
              };

              memory = {
                format = "{used}G";
              };

              network = {
                format-wifi = "{essid} ({signalStrength}%) ";
                format-ethernet = "{ipaddr}/{cidr} ";
                tooltip-format = "{ifname} via {gwaddr} ";
                format-linked = "{ifname} (No IP) ";
                format-disconnected = "Disconnected ⚠";
                format-alt = "{ifname}: {ipaddr}/{cidr}";
              };

              battery = {
                states = {
                  warning = 30;
                  critical = 15;
                };
                format = "{capacity} {icon}";
                format-alt = "{time} {icon}";
                format-charging = "{capacity} "; # fa-bolt for charging
                format-plugged = "{capacity} "; # fa-battery-full for plugged in/full
                format-icons = [
                  "" # fa-battery-empty
                  "" # fa-battery-quarter
                  "" # fa-battery-half
                  "" # fa-battery-three-quarters
                  "" # fa-battery-full
                ];
                interval = 10;
              };

              tray = {
                icon-size = 20;
              };
            };
          };

          style = ''
                      * {}
            
                      window#waybar {
                        background: #222222;
                        color: #FFFFFF;
                      }


                      #battery {
                         background: #000;
                         color: #fff;
                         border-radius: 5px;
                         margin: 3px;
                         padding: 0 10px;
                         font-family: "Font Awesome 6 Free", "Font Awesome 5 Free", "Noto Sans", sans-serif;
                      } 

                      #custom-bluetooth,
                      #custom-bluetooth.bt-off,
                      #custom-bluetooth.bt-on,
                      #custom-bluetooth.bt-connected {
                        border-radius: 5px;
                        margin: 3px;
                        padding: 0 10px;
                      }
                      #custom-bluetooth.bt-off {
                        background: #000;
                        color: #b0b0b0;
                      }
                      #custom-bluetooth.bt-on {
                        background: #2563EB;
                        color: #fff;
                      }
                      #custom-bluetooth.bt-connected {
                        background: #16A34A;
                        color: #fff;
                      }

            	  #custom-cpupower,
                      #custom-cpupower.eco,
                      #custom-cpupower.balanced,
                      #custom-cpupower.performance {
                        border-radius: 5px;
                        margin: 3px;
                        padding: 0 10px;
                      }
                      #custom-cpupower.eco { background: #16A34A; }        /* oxocarbon green */
                      #custom-cpupower.balanced { background: #2563EB; }   /* oxocarbon blue */
                      #custom-cpupower.performance { background: #D72660; }/* oxocarbon pink */

                      #hyprland-workspaces, #clock, #idle_inhibitor, #pulseaudio,
                      #backlight, #cpu, #memory, #network, #battery, #tray {
                        background: #000000;
                        margin: 3px;
                        border-radius: 5px;
                        padding: 0 10px;
                      }
            
            	  #idle_inhibitor {
                        border-radius: 5px;
                        margin: 3px;
                        padding: 0 10px;
                        background: #000000; /* default: black (off) */
                      }
                      #idle_inhibitor.activated {
                        background: #D72660;  /* oxocarbon pink when on */
                      }
            
                      #workspaces button {
                        padding: 0 2px;
                        color: #FFFFFF;
                        background: #222222;
                      }
            
                      #workspaces button.active {
                        color: #000000;
                        background: #0FF0FC;
                      }
            
                      #workspaces button:hover {
                        box-shadow: inherit;
                        text-shadow: inherit;
                        background: #000080;
                        border: #0FF0FC;
                        padding: 0 3px;
                      }
            
                      #pulseaudio, #backlight, #cpu, #memory, #network, #battery {
                        color: #FFFFFF;
                      }
          '';
        };
      };

      services = {
        # Hyprpaper - wallpaper daemon
        hyprpaper = {
          enable = true;
          settings = {
            ipc = "off";
            splash = false;
            splash_offset = 2.0;

            preload = [
              "/home/r6t/Pictures/wallpaper/phx-outrun.png"
              "/home/r6t/Pictures/wallpaper/big-sur-mountains-night-dark-macos-6016.jpg"
            ];

            wallpaper = [
              "eDP-1,/home/r6t/Pictures/wallpaper/phx-outrun.png"
              "DP-10,/home/r6t/Pictures/wallpaper/phx-outrun.png"
              "DP-9,/home/r6t/Pictures/wallpaper/big-sur-mountains-night-dark-macos-6016.jpg"
            ];
          };
        };
        # Hypridle - idle management
        hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "pidof hyprlock || hyprlock";
              before_sleep_cmd = "loginctl lock-session";
              after_sleep_cmd = "hyprctl dispatch dpms on";
            };

            listener = [
              {
                timeout = 150;
                on-timeout = "brightnessctl -s set 10";
                on-resume = "brightnessctl -r";
              }
              {
                timeout = 150;
                on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0";
                on-resume = "brightnessctl -rd rgb:kbd_backlight";
              }
              {
                timeout = 300;
                on-timeout = "loginctl lock-session";
              }
              {
                timeout = 380;
                on-timeout = "hyprctl dispatch dpms off";
                on-resume = "hyprctl dispatch dpms on";
              }
              {
                timeout = 1800;
                on-timeout = "systemctl suspend";
              }
            ];
          };
        };
      };

      qt = {
        enable = true;
        platformTheme.name = "qtct"; # This actually enables BOTH qt5ct and qt6ct!
        style = {
          name = "breeze";
          package = pkgs.kdePackages.breeze;
        };
      };

      home = {
        file = {
          ".local/share/rofi/themes/rounded-common.rasi".source = ../../../dotfiles/rofi/themes/rounded-common.rasi;
          ".local/share/rofi/themes/rounded-purple-dark.rasi".source = ../../../dotfiles/rofi/themes/rounded-purple-dark.rasi;
        };
        # Session variables for Wayland/Hyprland
        sessionVariables = {
          MOZ_ENABLE_WAYLAND = 1;
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland";
          QT_QPA_PLATFORMTHEME = "qt5ct";
          # QT_STYLE_OVERRIDE = "Breeze-Dark";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          XDG_CURRENT_SESSION = "hyprland";
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
        };
      };
    };
  };
}

