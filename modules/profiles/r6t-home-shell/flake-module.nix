{ inputs, ... }:

{
  flake.modules.nixos.r6t-home-shell = {
    imports = [
      inputs.self.modules.nixos.r6t-home-core
      ../../home/zellij/config.nix
    ];
  };
}
