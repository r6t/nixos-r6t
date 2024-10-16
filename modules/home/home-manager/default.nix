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
      };
    };
}
