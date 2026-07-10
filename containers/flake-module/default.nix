{ inputs, self, ... }:

let
  inherit (import ../../flake/common.nix) linuxSystem userConfig;
  inherit (self) outputs;
  inherit (inputs.nixpkgs) lib;

  containerDir = ./..;
  containerFiles = builtins.filter
    (file: lib.hasSuffix ".nix" file)
    (builtins.attrNames (builtins.readDir containerDir));

  mkContainerSystem = module: lib.nixosSystem {
    system = linuxSystem;
    modules = [ module ];
    specialArgs = { inherit outputs userConfig inputs; };
  };

  mkImage = file:
    let
      name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
      module = containerDir + "/${file}";
      images = (mkContainerSystem module).config.system.build.images;
    in
    [
      {
        inherit name;
        value = images.lxc;
      }
      {
        name = "${name}-metadata";
        value = images.lxc-metadata;
      }
    ];

  containerPackages = builtins.listToAttrs
    (builtins.concatMap mkImage containerFiles);
in
{
  # Auto-generated from containers/*.nix. Each container exposes .#<name> and
  # .#<name>-metadata; subdirectories such as containers/lib are ignored.
  flake.packages.${linuxSystem} = containerPackages;
}
