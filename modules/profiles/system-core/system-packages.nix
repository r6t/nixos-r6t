{ pkgs, ... }:

let
  commonPackages = import ../../lib/common-packages.nix pkgs;
in
{
  environment.systemPackages = commonPackages ++ (with pkgs; [
    bat
    cryptsetup
    ffmpeg
    home-manager
    inetutils
    python314
    sops
    tmux
    wireguard-tools
  ]);
}
