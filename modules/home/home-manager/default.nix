{ inputs, lib, config, userConfig, ... }: { 

    options = {
      mine.home.home-manager.enable =
        lib.mkEnableOption "enable home-manager core config";
    };

    config = lib.mkIf config.mine.home.home-manager.enable { 
      home-manager.backupFileExtension = "replacedbyhomemanager"; 
      home-manager.sharedModules = [
        inputs.nixvim.homeManagerModules.nixvim
        inputs.plasma-manager.homeManagerModules.plasma-manager
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      home-manager.users.${userConfig.username} = {
        home = {
          homeDirectory = userConfig.homeDirectory;
          stateVersion = "23.11";
          username = userConfig.username;
        };
        # Nicely reload system units when changing configs
        systemd.user.startServices = "sd-switch";
        xdg = {
          desktopEntries = {
	    focus-at-will = {
              name = "FocusAtWill web";
	      exec = "firefox --new-window https://focusatwill.com";
	      terminal = false;
	      icon = "internet-radio";
	      type = "Application";
	      categories = [ "Audio" "Music" ];
	    };
	  };
        };
      };
    };
}
