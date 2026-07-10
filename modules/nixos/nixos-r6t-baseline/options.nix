{ lib, ... }:

{
  options.mine.nixos-r6t-baseline.enable =
    lib.mkEnableOption "enable NixOS baseline system configuration";
}
