{ inputs, lib, config, ... }: { 

    options = {
      mine.home.home-manager.enable =
        lib.mkEnableOption "enable home-manager core config";
    };

    config = lib.mkIf config.mine.home.home-manager.enable { 
      home-manager.backupFileExtension = "replacedbyhomemanager"; 
      home-manager.sharedModules = [
        inputs.nixvim.homeManagerModules.nixvim
        inputs.plasma-manager.homeManagerModules.plasma-manager
      ];
      home-manager.users.r6t = {
        home = {
          homeDirectory = "/home/r6t";
          stateVersion = "23.11";
          username = "r6t";
        };
        # Nicely reload system units when changing configs
        systemd.user.startServices = "sd-switch";
        xdg = {
          desktopEntries = {
	    focus-at-will = {
              name = "FocusAtWill web";
	      exec = "firefox https://focusatwill.com";
	      terminal = false;
	      icon = "internet-radio";
	      type = "Application";
	      categories = [ "Audio" "Music" ];
	    };
	    proton-mail = {
              name = "Protonmail web";
	      exec = "firefox https://mail.proton.me";
	      terminal = false;
	      icon = "internet-mail";
	      type = "Application";
	      categories = [ "Network" "Email" ];
	      mimeType = [ "x-scheme-handler/mailto" ];
	    };
	  };
        };
      };
    };
}
