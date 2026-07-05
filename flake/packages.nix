{ inputs, self, ... }:

let
  inherit (import ./common.nix) linuxSystem userConfig;
  inherit (self) outputs;

  # Custom packages (rocmfp4-llama, etc.) — explicit attribute set.
  # Built per-system via callPackage with the matching pkgs instance.
  pkgs = import inputs.nixpkgs {
    system = linuxSystem;
    config.allowUnfree = true;
  };

  customPackages = {
    rocmfp4-llama = pkgs.callPackage ../pkgs/rocmfp4-llama/package.nix { };
  };

  # Auto-generated container images from containers/*.nix.
  # Each file produces two outputs: {name} (rootfs) and {name}-metadata.
  containerDir = ../containers;
  containerFiles = builtins.filter
    (f: inputs.nixpkgs.lib.hasSuffix ".nix" f)
    (builtins.attrNames (builtins.readDir containerDir));

  mkImage = file:
    let
      name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
      module = containerDir + "/${file}";
    in
    [
      {
        inherit name;
        value = inputs.nixos-generators.nixosGenerate {
          system = linuxSystem;
          format = "lxc";
          modules = [ module ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
      }
      {
        name = "${name}-metadata";
        value = inputs.nixos-generators.nixosGenerate {
          system = linuxSystem;
          format = "lxc-metadata";
          modules = [ module ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
      }
    ];

  containerPackages = builtins.listToAttrs
    (builtins.concatMap mkImage containerFiles);
in
{
  # Container images and custom packages — exposed at flake-level because they
  # depend on `outputs` (cycle would form if put in perSystem). x86_64-linux only.
  # Build with: nix build .#<name>  or  nix build .#<name>-metadata
  flake.packages.${linuxSystem} = customPackages // containerPackages;
}
