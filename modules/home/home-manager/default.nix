{ inputs, lib, config, userConfig, ... }: {

  options = {
    mine.home.home-manager.enable =
      lib.mkEnableOption "enable home-manager core config";
  };

  config = lib.mkIf config.mine.home.home-manager.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = { inherit userConfig; };
      backupFileExtension = "replacedbyhomemanager";
      sharedModules = [
        inputs.nixvim.homeModules.nixvim
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      users.${userConfig.username} = {
        home = {
          inherit (userConfig) homeDirectory username;
          stateVersion = "23.11";
        };
        # Nicely reload system units when changing configs
        systemd.user.startServices = "sd-switch";
        xdg.desktopEntries.focus-at-will = {
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
}

