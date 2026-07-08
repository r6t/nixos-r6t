{ lib, config, pkgs, ... }:

{
  options.mine.docker.enable =
    lib.mkEnableOption "enable standard docker: used inside LXC w no gpu or rootless";

  config = lib.mkIf config.mine.docker.enable (import ./config.nix { inherit pkgs; });
}
