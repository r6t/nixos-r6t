{ inputs, ... }:

{
  flake.modules.nixos.r6t-home-core = { ... }: {
    imports = [
      inputs.self.modules.nixos.home-core
      ../../home/ssh/options.nix
      ../../home/ssh/config.nix
    ];
  };
}
