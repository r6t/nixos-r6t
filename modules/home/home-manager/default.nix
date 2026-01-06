{ inputs, lib, config, pkgs, userConfig, ... }: {

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
      ] ++ lib.optionals pkgs.stdenv.isLinux [
        inputs.plasma-manager.homeModules.plasma-manager
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      users.${userConfig.username} = {
        home = {
          inherit (userConfig) homeDirectory username;
          stateVersion = "23.11";
        };
        # Nicely reload system units when changing configs (Linux only)
        systemd.user.startServices = lib.mkIf pkgs.stdenv.isLinux "sd-switch";
      };
    };
  };
}

