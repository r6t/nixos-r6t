{ inputs, ... }:

{
  flake.modules.nixos.sops-host = {
    imports = [
      inputs.sops-nix.nixosModules.sops
      ../../nixos/sops/options.nix
      ../../nixos/sops/config.nix
    ];
  };
}
