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
  flake.modules = {
    homeManager = {
      alacritty = import ../modules/home/alacritty/default.nix;
      atuin = import ../modules/home/atuin/default.nix;
      fish = import ../modules/home/fish/default.nix;
      git = import ../modules/home/git/default.nix;
      nixvim = import ../modules/home/nixvim/default.nix;
      zellij = import ../modules/home/zellij/default.nix;
    };

    nixos = {
      default = import ../modules/default.nix;

      # Host modules wrap the existing host files so nixosConfigurations can
      # consume named registry entries without changing host internals yet.
      barrel = {
        imports = [ ../hosts/barrel/configuration.nix ];
      };

      crown = {
        imports = [ ../hosts/crown/configuration.nix ];
      };

      mountainball = {
        imports = [
          ../hosts/mountainball/configuration.nix
          allowUnfreeWithTemporaryElectronInsecure
        ];
      };

      goldenball = {
        imports = [
          ../hosts/goldenball/configuration.nix
          allowUnfreeWithTemporaryElectronInsecure
        ];
      };

      hedgehog = {
        imports = [
          ../hosts/hedgehog/configuration.nix
          {
            nixpkgs.config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          }
        ];
      };

      saguaro = {
        imports = [ ../hosts/saguaro/configuration.nix ];
      };
    };
  };
}
