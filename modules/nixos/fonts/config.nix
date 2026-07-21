{ pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" "DejaVu Serif" ];
        sansSerif = [ "Noto Sans" "DejaVu Sans" ];
        monospace = [ "Hack Nerd Font Mono" "Hack" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      dejavu_fonts
      liberation_ttf
      font-awesome
      hack-font
      nerd-fonts.hack
      nerd-fonts.blex-mono
      source-sans-pro
    ];
  };
}
