{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:



{
  # Set dotfiles

  home.packages = with pkgs; [
    brightnessctl # display brightness
    dconf # hyprland support
    gnome.gnome-font-viewer
    pamixer # pulseaudio controls
    playerctl # media keys
    xdg-utils # for opening default programs when clicking links
    waybar
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wdisplays # wayland display config
    wlogout # wayland logout shortcuts
  ];


}
