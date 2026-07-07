{ inputs, ... }:

{
  flake.modules.nixos.infra-host = {
    imports = [
      inputs.self.modules.nixos.cgrouped-nix-builds
      inputs.self.modules.nixos.infra-networkd-journal
      inputs.self.modules.nixos.nix-build-throttle
    ];
  };
}
