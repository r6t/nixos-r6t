
{ pkgs, ... }:

{
  # Users:
  home-manager.users.r6t = { pkgs, ...}: {
    home.packages = with pkgs; [
      libva # https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
    ];
  };
}