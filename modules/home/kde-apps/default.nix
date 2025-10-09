{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.kde-apps.enable =
      lib.mkEnableOption "enable plasma-manager and misc KDE software in home-manager";
  };

  config = lib.mkIf config.mine.home.kde-apps.enable {
    home-manager.users.${userConfig.username} = {
      home = {
        packages = with pkgs; [
          arj # Krusader support
          dpkg # Krusader support
          findutils # Krusader support
          lhasa # Krusader support
          kdiff3 # KDE utility
          krename # KDE utility
          krusader # KDE file manager
          kdePackages.breeze # KDE Breeze theme
          kdePackages.breeze-gtk # KDE Breeze theme
          kdePackages.breeze-icons # KDE app icons
          kdePackages.elisa # KDE music player
          kdePackages.filelight # KDE disk utilization visualizer
          kdePackages.gwenview # KDE image viewer
          kdePackages.kalk # KDE Calculator, Kcalc alternative
          kdePackages.kdeconnect-kde # KDE Connect phone pairing
          kdePackages.kdialog # KDE app support
          kdePackages.kget # Krusader support
          kdePackages.kio-extras # KDE support
          kdePackages.polkit-kde-agent-1 # KDE privlege escalation helper
          kdePackages.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
          rar # Krusader support
        ];
      };



      programs = {
        elisa = {
          enable = true;
          appearance = {
            defaultFilesViewPath = "/home/r6t/music/sync";
            defaultView = "allAlbums";
          };
          indexer = {
            ratingsStyle = "favourites";
          };
        };

        kate = {
          enable = true;
          editor = {
            brackets = {
              automaticallyAddClosing = true;
              flashMatching = true;
              highlightMatching = true;
            };
            font = {
              family = "Hack Nerd";
              pointSize = 12;
            };
            indent.width = 2;
            tabWidth = 4;
          };
          ui.colorScheme = "Breeze Dark";
        };

        okular = {
          general = {
            mouseMode = "Browse";
            obeyDrm = false;
            openFileInTabs = true;
            showScrollbars = true;
            smoothScrolling = true;
            viewContinuous = true;
            zoomMode = "autoFit";
          };
          performance = {
            enableTransparencyEffects = true;
            memoryUsage = "Greedy";
          };
        };

        plasma = {
          enable = true;
          overrideConfig = true;
          krunner = {
            activateWhenTypingOnDesktop = true;
            historyBehavior = "enableSuggestions"; # or disabled or enableAutoComplete
            position = "center";
            shortcuts.launch = "Meta";
          };

          workspace = {
            colorScheme = "BreezeDark";
            theme = "breeze-dark";
            lookAndFeel = "org.kde.breezedark.desktop";
            wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images_dark/5120x2880.png";
          };

          kscreenlocker = {
            appearance = {
              wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images_dark/5120x2880.png";
            };
            passwordRequired = true;
            passwordRequiredDelay = 9;
          };

          panels = [
            {
              location = "bottom";
              height = 42;
              # Index reference: Plasma screen output 1 is screen 0 below.
              screen = 0;
              widgets = [
                {
                  kickoff = {
                    sortAlphabetically = true;
                    icon = "nix-snowflake-white";
                  };
                }
                {
                  pager = { };
                }
                {
                  iconTasks = {
                    launchers = [
                      "applications:org.kde.krusader.desktop" # 1
                      "applications:Alacritty.desktop" # 2
                      "applications:firefox.desktop" # 3
                      "applications:obsidian.desktop" # 4
                      "applications:me.proton.Mail.desktop" # 5
                    ];
                  };
                }
                "org.kde.plasma.marginsseparator"
                {
                  systemTray.items = {
                    shown = [
                      "org.kde.plasma.battery"
                      "org.kde.plasma.bluetooth"
                      "org.kde.plasma.networkmanagement"
                      "org.kde.plasma.volume"
                      "org.kde.plasma.clipboard"
                      "org.kde.plasma.notifications"
                    ];
                    hidden = [
                    ];
                  };
                }
                {
                  digitalClock = {
                    calendar.firstDayOfWeek = "sunday";
                    time.format = "24h";
                  };
                }
              ];
              # values: none, autohide, dodgewindows, normalpanel, windowsgobelow
              hiding = "none";
            }
          ];

          powerdevil = {
            AC = {
              autoSuspend.action = "nothing";
              powerButtonAction = "shutDown";
              turnOffDisplay.idleTimeout = 3600;
              whenSleepingEnter = "standby";
            };
          };
          session = {
            general.askForConfirmationOnLogout = false;
            sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
          };
          spectacle = {
            shortcuts = {
              # Meta + Shift + 234 window monitor region, 567 window monitor region
              captureActiveWindow = [ "Meta+@" ];
              captureCurrentMonitor = [ "Meta+#" ];
              captureRectangularRegion = [ "Meta+$" ];
              launchWithoutCapturing = [ "Meta+!" ];
              recordRegion = [ "Meta+&" ];
              recordScreen = [ "Meta+^" ];
              recordWindow = [ "Meta+%" ];
            };
          };

          # These are not reliable as of Oct 2025.
          # Leaving for later implementation.
          # ~/.config/kglobalshortcutsrc currently conflicts
          # shortcuts = {
          # # AUDIO
          # "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
          # "kmix"."decrease_volume" = "Volume Down";
          # "kmix"."decrease_volume_small" = "Shift+Volume Down";
          # "kmix"."increase_microphone_volume" = "Microphone Volume Up";
          # "kmix"."increase_volume" = "Volume Up";
          # "kmix"."increase_volume_small" = "Shift+Volume Up";
          # "kmix"."mic_mute" = [ "Microphone Mute" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone" ];
          # "kmix"."mute" = "Volume Mute";

          # # SESSION
          # "ksmserver"."Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
          # # Lock remapped with Ctrl too - stay out of Krohnkite default's way
          # "ksmserver"."Lock Session" = [ "Meta+Ctrl+L" "Screensaver,Meta+Ctrl+L" "Screensaver,Lock Session" ];
          # "ksmserver"."Log Out" = "Ctrl+Alt+Del";
          # "ksmserver"."Log Out Without Confirmation" = "none,,Log Out Without Confirmation";
          # "ksmserver"."LogOut" = "none,,Log Out";
          # "ksmserver"."Reboot" = "none,,Reboot";
          # "ksmserver"."Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
          # "ksmserver"."Shut Down" = "none,,Shut Down";

          # # KWIN + KROHNKITE
          # "kwin"."Grid View" = "Meta+E,Meta+G,Toggle Grid View";
          # "kwin"."KrohnkiteBTreeLayout" = ",none,Krohnkite: BTree Layout";
          # "kwin"."KrohnkiteColumnsLayout" = ",none,Krohnkite: Columns Layout";
          # "kwin"."KrohnkiteDecrease" = "Meta+D,none,Krohnkite: Decrease";
          # "kwin"."KrohnkiteFloatAll" = "Meta+Shift+F,none,Krohnkite: Toggle Float All";
          # "kwin"."KrohnkiteFloatingLayout" = "Meta+F,none,Krohnkite: Floating Layout";
          # "kwin"."KrohnkiteFocusDown" = "Meta+J,none,Krohnkite: Focus Down";
          # "kwin"."KrohnkiteFocusLeft" = "Meta+H,none,Krohnkite: Focus Left";
          # "kwin"."KrohnkiteFocusNext" = ",none,Krohnkite: Focus Next";
          # "kwin"."KrohnkiteFocusPrev" = ",none,Krohnkite: Focus Previous";
          # "kwin"."KrohnkiteFocusRight" = "Meta+L,none,Krohnkite: Focus Right";
          # "kwin"."KrohnkiteFocusUp" = "Meta+K,none,Krohnkite: Focus Up";
          # "kwin"."KrohnkiteGrowHeight" = "Meta+Ctrl+J,none,Krohnkite: Grow Height";
          # "kwin"."KrohnkiteIncrease" = "Meta+I,none,Krohnkite: Increase";
          # "kwin"."KrohnkiteMonocleLayout" = "Meta+M,none,Krohnkite: Monocle Layout";
          # "kwin"."KrohnkiteNextLayout" = ",none,Krohnkite: Next Layout";
          # "kwin"."KrohnkitePreviousLayout" = "Meta+|,none,Krohnkite: Previous Layout";
          # "kwin"."KrohnkiteQuarterLayout" = ",none,Krohnkite: Quarter Layout";
          # "kwin"."KrohnkiteRotate" = "Meta+R,none,Krohnkite: Rotate";
          # "kwin"."KrohnkiteRotatePart" = "Meta+Shift+R,none,Krohnkite: Rotate Part";
          # "kwin"."KrohnkiteSetMaster" = "Meta+Return,none,Krohnkite: Set master";
          # "kwin"."KrohnkiteShiftDown" = "Meta+Shift+J,none,Krohnkite: Move Down/Next";
          # "kwin"."KrohnkiteShiftLeft" = "Meta+Shift+H,none,Krohnkite: Move Left";
          # "kwin"."KrohnkiteShiftRight" = "Meta+Shift+L,none,Krohnkite: Move Right";
          # "kwin"."KrohnkiteShiftUp" = "Meta+Shift+K,none,Krohnkite: Move Up/Prev";
          # "kwin"."KrohnkiteShrinkHeight" = "Meta+Ctrl+K,none,Krohnkite: Shrink Height";
          # "kwin"."KrohnkiteShrinkWidth" = "Meta+Ctrl+H,none,Krohnkite: Shrink Width";
          # "kwin"."KrohnkiteSpiralLayout" = ",none,Krohnkite: Spiral Layout";
          # "kwin"."KrohnkiteSpreadLayout" = ",none,Krohnkite: Spread Layout";
          # "kwin"."KrohnkiteStackedLayout" = ",none,Krohnkite: Stacked Layout";
          # "kwin"."KrohnkiteStairLayout" = ",none,Krohnkite: Stair Layout";
          # "kwin"."KrohnkiteTileLayout" = "Meta+T,none,Krohnkite: Tile Layout";
          # "kwin"."KrohnkiteToggleFloat" = "Meta+F,none,Krohnkite: Toggle Float";
          # "kwin"."KrohnkiteTreeColumnLayout" = ",none,Krohnkite: Three Column Layout";
          # "kwin"."KrohnkitegrowWidth" = "Meta+Ctrl+L,none,Krohnkite: Grow Width";
          # "kwin"."KrohnkitetoggleDock" = ",none,Krohnkite: Toggle Dock";

          # # MEDIA
          # "mediacontrol"."mediavolumedown" = "none,,Media volume down";
          # "mediacontrol"."mediavolumeup" = "none,,Media volume up";
          # "mediacontrol"."nextmedia" = "Media Next";
          # "mediacontrol"."pausemedia" = "Media Pause";
          # "mediacontrol"."playmedia" = "none,,Play media playback";
          # "mediacontrol"."playpausemedia" = "Media Play";
          # "mediacontrol"."previousmedia" = "Media Previous";
          # "mediacontrol"."stopmedia" = "Media Stop";

          # # SYSTEM
          # "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
          # "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
          # "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
          # "org_kde_powerdevil"."Hibernate" = "Hibernate";
          # "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
          # "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
          # "org_kde_powerdevil"."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
          # "org_kde_powerdevil"."PowerDown" = "Power Down";
          # "org_kde_powerdevil"."PowerOff" = "Power Off";
          # "org_kde_powerdevil"."Sleep" = "Sleep";
          # "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
          # "org_kde_powerdevil"."Turn Off Screen" = [ ];
          # # Prob going to remove this
          # # "org_kde_powerdevil"."powerProfile" = [ "Battery" "Meta+B,Battery" "Meta+B,Switch Power Profile" ];

          # # PLASMASHELL
          # "plasmashell"."activate application launcher" = [ "Alt+F1,Activate Application Launcher" ];
          # "plasmashell"."activate task manager entry 1" = "Meta+1";
          # "plasmashell"."activate task manager entry 2" = "Meta+2";
          # "plasmashell"."activate task manager entry 3" = "Meta+3";
          # "plasmashell"."activate task manager entry 4" = "Meta+4";
          # "plasmashell"."activate task manager entry 5" = "Meta+5";
          # "plasmashell"."activate task manager entry 6" = "Meta+6";
          # "plasmashell"."activate task manager entry 7" = "Meta+7";
          # "plasmashell"."activate task manager entry 8" = "Meta+8";
          # "plasmashell"."activate task manager entry 9" = "Meta+9";
          # "plasmashell"."activate task manager entry 10" = "Meta+0";
          # "plasmashell"."clear-history" = "none,,Clear Clipboard History";
          # "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
          # "plasmashell"."cycle-panels" = "Meta+Alt+P";
          # "plasmashell"."manage activities" = "none";
          # "plasmashell"."stop current activity" = "none";
          # # Meta + D mapped to Krohnkite. OSD quickly available from Plasma menu bar
          # "services/org.kde.kscreen.desktop"."ShowOSD" = "none";
          # };
          configFile = {
            # global plasma settings
            "baloofilerc"."General"."dbVersion" = 2;
            "baloofilerc"."General"."exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
            "baloofilerc"."General"."exclude filters version" = 9;
            "bluedevilglobalrc"."Global"."launchState" = "enable";
            "kcminputrc"."Libinput/2362/628/PIXA3854:00 093A:0274 Touchpad"."ClickMethod" = 2;
            "kcminputrc"."Libinput/2362/628/PIXA3854:00 093A:0274 Touchpad"."NaturalScroll" = true;
            "kcminputrc"."Libinput/2362/628/PIXA3854:00 093A:0274 Touchpad"."TapToClick" = false;
            "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
            "kded5rc"."Module-device_automounter"."autoload" = false;
            "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "640,480";
            "kdeglobals"."General"."AccentColor" = "146,110,228"; # purple
            "kdeglobals"."General"."LastUsedCustomAccentColor" = "146,110,228";
            "kdeglobals"."General"."TerminalApplication" = "alacritty";
            "kdeglobals"."General"."TerminalService" = "Alacritty.desktop";
            "kdeglobals"."KDE"."widgetStyle" = "BreezeDark";
            "kwinrc"."Plugins"."krohnkiteEnabled" = true;
            "kwinrc"."Desktops"."Number" = 2;
            "kwinrc"."Desktops"."Rows" = 1;
            "kwinrc"."NightColor"."Active" = true;
            "kwinrc"."NightColor"."LatitudeFixed" = 43.969;
            "kwinrc"."NightColor"."LongitudeFixed" = "-121.127";
            "kwinrc"."NightColor"."Mode" = "Location";
            "kwinrc"."Windows"."DelayFocusInterval" = 0;
            "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
            "kwinrc"."Windows"."RollOverDesktops" = true;
            "kwinrc"."Xwayland"."Scale" = 2;
            "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
          };
          windows.allowWindowsToRememberPositions = true;
        };
      };
    };
  };
}
