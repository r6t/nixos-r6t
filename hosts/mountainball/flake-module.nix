{ inputs, ... }:

let
  allowUnfreeWithTemporaryElectronInsecure = {
    nixpkgs.config = {
      allowUnfree = true;
      # temporary allow recent EOL
      permittedInsecurePackages = [ "electron-36.9.5" "electron-39.8.10" ];
    };
  };
in
{
  flake.modules.nixos.mountainball = {
    imports = [
      inputs.self.modules.nixos.r6t-base
      inputs.self.modules.nixos.r6t-home-shell
      ./configuration.nix
      allowUnfreeWithTemporaryElectronInsecure
    ];
  };
}
