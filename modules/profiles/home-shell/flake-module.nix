{ inputs, ... }:

{
  flake.modules.nixos.home-shell = {
    imports = [
      inputs.self.modules.nixos.home-core
      ../../home/zellij/options.nix
      ../../home/zellij/config.nix
    ];
  };
}
