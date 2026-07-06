{ inputs, self, ... }:

let
  inherit (import ../../flake/common.nix) linuxSystem userConfig;
  inherit (self) outputs;

  containerDir = ./..;
  containerFiles = builtins.filter
    (file: inputs.nixpkgs.lib.hasSuffix ".nix" file)
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
  # Auto-generated from containers/*.nix. Each container exposes .#<name> and
  # .#<name>-metadata; subdirectories such as containers/lib are ignored.
  flake.packages.${linuxSystem} = containerPackages;
}
