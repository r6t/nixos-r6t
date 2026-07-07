{
  flake.modules.nixos.gaming-host = { lib, ... }: {
    imports = [
      ../../nixos/networkmanager/config.nix
      ../../nixos/sound/config.nix
    ];

    nixpkgs.config.allowUnfree = true;

    mine = {
      steam.enable = lib.mkDefault true;
    };
  };
}
