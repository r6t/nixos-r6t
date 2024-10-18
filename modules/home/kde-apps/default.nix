{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.kde-apps.enable =
        lib.mkEnableOption "enable plasma-manager and misc KDE software in home-manager";
    };

    config = lib.mkIf config.mine.home.kde-apps.enable { 
      home-manager.users.r6t = {
        home.packages = with pkgs; [
          kate # KDE text editor
          kdiff3 # KDE utility
          krename # KDE utility
          krusader # KDE file manager
          kdePackages.breeze # KDE Breeze theme
          kdePackages.breeze-gtk # KDE Breeze theme
          kdePackages.breeze-icons # KDE app icons
          kdePackages.elisa # KDE music player
          kdePackages.filelight # KDE disk utilization visualizer
          kdePackages.gwenview # KDE image viewer
          kdePackages.kdeconnect-kde # KDE Connect phone pairing
          kdePackages.kdialog # KDE app support
          kdePackages.kio-extras # KDE support
          kdePackages.krdc # KDE VNC + RDP client
          kdePackages.polkit-kde-agent-1 # KDE privlege escalation helper
          kdePackages.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
        ];

        programs.plasma = {
	  workspace.colorScheme = "BreezeDark";
	  enable = true;
	  overrideConfig = true;
	  panels = [
    	    {
    	      location = "bottom";
	      height = 44;
    	      widgets = [
    	        {
    	          kickoff = {
    	            sortAlphabetically = true;
    	            icon = "nix-snowflake-white";
    	          };
    	        }
    	        {
    	          pager = {};
    	        }
    	        {
    	          iconTasks = {
    	            launchers = [
    	              "applications:org.kde.krusader.desktop"
    	              "applications:Alacritty.desktop"
    	              "applications:firefox.desktop"
    	              "applications:super-productivity.desktop"
    	              "applications:io.github.dweymouth.supersonic.desktop"
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
	  shortcuts = {
            "kmix"."decrease_microphone_volume" = "Microphone Volume Down";
            "kmix"."decrease_volume" = "Volume Down";
            "kmix"."decrease_volume_small" = "Shift+Volume Down";
            "kmix"."increase_microphone_volume" = "Microphone Volume Up";
            "kmix"."increase_volume" = "Volume Up";
            "kmix"."increase_volume_small" = "Shift+Volume Up";
            "kmix"."mic_mute" = ["Microphone Mute" "Meta+Volume Mute,Microphone Mute" "Meta+Volume Mute,Mute Microphone"];
            "kmix"."mute" = "Volume Mute";
            "ksmserver"."Halt Without Confirmation" = "none,,Shut Down Without Confirmation";
            "ksmserver"."Lock Session" = ["Meta+L" "Screensaver,Meta+L" "Screensaver,Lock Session"];
            "ksmserver"."Log Out" = "Ctrl+Alt+Del";
            "ksmserver"."Log Out Without Confirmation" = "none,,Log Out Without Confirmation";
            "ksmserver"."LogOut" = "none,,Log Out";
            "ksmserver"."Reboot" = "none,,Reboot";
            "ksmserver"."Reboot Without Confirmation" = "none,,Reboot Without Confirmation";
            "ksmserver"."Shut Down" = "none,,Shut Down";
            "kwin"."Activate Window Demanding Attention" = "Meta+Ctrl+A";
            "kwin"."Overview" = "Meta+W";
            "kwin"."Show Desktop" = "Meta+D";
            "kwin"."Switch One Desktop Down" = "Meta+Ctrl+Down";
            "kwin"."Switch One Desktop Up" = "Meta+Ctrl+Up";
            "kwin"."Switch One Desktop to the Left" = "Meta+Ctrl+Left";
            "kwin"."Switch One Desktop to the Right" = "Meta+Ctrl+Right";
            "kwin"."Switch Window Down" = "Meta+Alt+Down";
            "kwin"."Switch Window Left" = "Meta+Alt+Left";
            "kwin"."Switch Window Right" = "Meta+Alt+Right";
            "kwin"."Switch Window Up" = "Meta+Alt+Up";
            "kwin"."Walk Through Windows" = "Alt+Tab";
            "kwin"."Walk Through Windows (Reverse)" = "Alt+Shift+Tab";
            "kwin"."Walk Through Windows of Current Application" = "Alt+`";
            "kwin"."Walk Through Windows of Current Application (Reverse)" = "Alt+~";
            "kwin"."Window Close" = "Alt+F4";
            "kwin"."Window Maximize" = "Meta+PgUp";
            "kwin"."Window Minimize" = "Meta+PgDown";
            "kwin"."Window One Desktop Down" = "Meta+Ctrl+Shift+Down";
            "kwin"."Window One Desktop Up" = "Meta+Ctrl+Shift+Up";
            "kwin"."Window One Desktop to the Left" = "Meta+Ctrl+Shift+Left";
            "kwin"."Window One Desktop to the Right" = "Meta+Ctrl+Shift+Right";
            "kwin"."Window Operations Menu" = "Alt+F3";
            "kwin"."Window Quick Tile Bottom" = "Meta+Down";
            "kwin"."Window Quick Tile Left" = "Meta+Left";
            "kwin"."Window Quick Tile Right" = "Meta+Right";
            "kwin"."Window Quick Tile Top" = "Meta+Up";
            "kwin"."Window to Next Screen" = "Meta+Shift+Right";
            "kwin"."Window to Previous Screen" = "Meta+Shift+Left";
            "mediacontrol"."mediavolumedown" = "none,,Media volume down";
            "mediacontrol"."mediavolumeup" = "none,,Media volume up";
            "mediacontrol"."nextmedia" = "Media Next";
            "mediacontrol"."pausemedia" = "Media Pause";
            "mediacontrol"."playmedia" = "none,,Play media playback";
            "mediacontrol"."playpausemedia" = "Media Play";
            "mediacontrol"."previousmedia" = "Media Previous";
            "mediacontrol"."stopmedia" = "Media Stop";
            "org_kde_powerdevil"."Decrease Keyboard Brightness" = "Keyboard Brightness Down";
            "org_kde_powerdevil"."Decrease Screen Brightness" = "Monitor Brightness Down";
            "org_kde_powerdevil"."Decrease Screen Brightness Small" = "Shift+Monitor Brightness Down";
            "org_kde_powerdevil"."Hibernate" = "Hibernate";
            "org_kde_powerdevil"."Increase Keyboard Brightness" = "Keyboard Brightness Up";
            "org_kde_powerdevil"."Increase Screen Brightness" = "Monitor Brightness Up";
            "org_kde_powerdevil"."Increase Screen Brightness Small" = "Shift+Monitor Brightness Up";
            "org_kde_powerdevil"."PowerDown" = "Power Down";
            "org_kde_powerdevil"."PowerOff" = "Power Off";
            "org_kde_powerdevil"."Sleep" = "Sleep";
            "org_kde_powerdevil"."Toggle Keyboard Backlight" = "Keyboard Light On/Off";
            "org_kde_powerdevil"."Turn Off Screen" = [ ];
            "org_kde_powerdevil"."powerProfile" = ["Battery" "Meta+B,Battery" "Meta+B,Switch Power Profile"];
            "plasmashell"."activate application launcher" = ["Meta" "Alt+F1,Activate Application Launcher"];
            "plasmashell"."activate task manager entry 1" = "Meta+1";
            "plasmashell"."activate task manager entry 2" = "Meta+2";
            "plasmashell"."activate task manager entry 3" = "Meta+3";
            "plasmashell"."activate task manager entry 4" = "Meta+4";
            "plasmashell"."activate task manager entry 5" = "Meta+5";
            "plasmashell"."activate task manager entry 6" = "Meta+6";
            "plasmashell"."activate task manager entry 7" = "Meta+7";
            "plasmashell"."activate task manager entry 8" = "Meta+8";
            "plasmashell"."activate task manager entry 9" = "Meta+9";
            "plasmashell"."activate task manager entry 10" = "Meta+0";
            "plasmashell"."clear-history" = "none,,Clear Clipboard History";
            "plasmashell"."clipboard_action" = "Meta+Ctrl+X";
            "plasmashell"."cycle-panels" = "Meta+Alt+P";
            "plasmashell"."manage activities" = "Meta+Q";
            "plasmashell"."stop current activity" = "Meta+S";
	  };
          configFile = {
	    # global plasma settings
            "plasmarc"."Theme"."name" = "breeze-dark";
            "baloofilerc"."General"."dbVersion" = 2;
            "baloofilerc"."General"."exclude filters" = "*~,*.part,*.o,*.la,*.lo,*.loT,*.moc,moc_*.cpp,qrc_*.cpp,ui_*.h,cmake_install.cmake,CMakeCache.txt,CTestTestfile.cmake,libtool,config.status,confdefs.h,autom4te,conftest,confstat,Makefile.am,*.gcode,.ninja_deps,.ninja_log,build.ninja,*.csproj,*.m4,*.rej,*.gmo,*.pc,*.omf,*.aux,*.tmp,*.po,*.vm*,*.nvram,*.rcore,*.swp,*.swap,lzo,litmain.sh,*.orig,.histfile.*,.xsession-errors*,*.map,*.so,*.a,*.db,*.qrc,*.ini,*.init,*.img,*.vdi,*.vbox*,vbox.log,*.qcow2,*.vmdk,*.vhd,*.vhdx,*.sql,*.sql.gz,*.ytdl,*.tfstate*,*.class,*.pyc,*.pyo,*.elc,*.qmlc,*.jsc,*.fastq,*.fq,*.gb,*.fasta,*.fna,*.gbff,*.faa,po,CVS,.svn,.git,_darcs,.bzr,.hg,CMakeFiles,CMakeTmp,CMakeTmpQmake,.moc,.obj,.pch,.uic,.npm,.yarn,.yarn-cache,__pycache__,node_modules,node_packages,nbproject,.terraform,.venv,venv,core-dumps,lost+found";
            "baloofilerc"."General"."exclude filters version" = 9;
            "kded5rc"."Module-browserintegrationreminder"."autoload" = false;
            "kded5rc"."Module-device_automounter"."autoload" = false;
            "kdeglobals"."DirSelect Dialog"."DirSelectDialog Size" = "640,480";
            "kdeglobals"."General"."AccentColor" = "146,110,228"; # purple
            "kdeglobals"."General"."LastUsedCustomAccentColor" = "146,110,228";
            "kdeglobals"."General"."TerminalApplication" = "alacritty";
            "kdeglobals"."General"."TerminalService" = "Alacritty.desktop";
            "kdeglobals"."KDE"."widgetStyle" = "BreezeDark";
            "kwinrc"."Desktops"."Number" = 2;
            "kwinrc"."Desktops"."Rows" = 1;
            "kwinrc"."NightColor"."Active" = true;
            "kwinrc"."NightColor"."LatitudeFixed" = 43.96946564885496;
            "kwinrc"."NightColor"."LongitudeFixed" = "-121.12781954887218";
            "kwinrc"."NightColor"."Mode" = "Location";
            "kwinrc"."Tiling"."padding" = 4;
            "kwinrc"."Windows"."DelayFocusInterval" = 200;
            "kwinrc"."Windows"."FocusPolicy" = "FocusFollowsMouse";
            "kwinrc"."Windows"."RollOverDesktops" = true;
            "kwinrc"."Xwayland"."Scale" = 2;
            "plasma-localerc"."Formats"."LANG" = "en_US.UTF-8";
	    # mountainball specific
            "kcminputrc"."Libinput/20547/23623/Ploopy Corporation Ploopy Adept Trackball Mouse"."NaturalScroll" = true;
            "kcminputrc"."Libinput/20547/23623/Ploopy Corporation Ploopy Adept Trackball Mouse"."PointerAcceleration" = "-0.600";
            "kcminputrc"."Libinput/2362/628/PIXA3854:00 093A:0274 Touchpad"."NaturalScroll" = true;
	  };
          dataFile = {
            "dolphin/view_properties/global/.directory"."Dolphin"."SortOrder" = 1;
            "dolphin/view_properties/global/.directory"."Dolphin"."SortRole" = "modificationtime";
            "dolphin/view_properties/global/.directory"."Dolphin"."ViewMode" = 2;
            "dolphin/view_properties/global/.directory"."Settings"."HiddenFilesShown" = true;
          };
        };
      };
    };
}
