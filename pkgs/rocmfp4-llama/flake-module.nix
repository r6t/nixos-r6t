{ inputs, ... }:

let
  inherit (import ../../flake/common.nix) linuxSystem;

  pkgs = import inputs.nixpkgs {
    system = linuxSystem;
    config.allowUnfree = true;
  };
in
{
  flake.packages.${linuxSystem}.rocmfp4-llama = pkgs.callPackage ./package.nix { };
}
