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
  flake.modules.nixos.goldenball = {
    imports = [
      ./configuration.nix
      allowUnfreeWithTemporaryElectronInsecure
    ];
  };
}
