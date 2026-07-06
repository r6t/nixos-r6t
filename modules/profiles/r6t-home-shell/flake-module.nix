{
  flake.modules.nixos.r6t-home-shell = { lib, ... }: {
    mine.home = {
      atuin.enable = lib.mkDefault true;
      fish.enable = lib.mkDefault true;
      git.enable = lib.mkDefault true;
      home-manager.enable = lib.mkDefault true;
      nixvim.enable = lib.mkDefault true;
      ssh.enable = lib.mkDefault true;
      zellij.enable = lib.mkDefault true;
    };
  };
}
