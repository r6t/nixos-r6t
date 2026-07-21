{ userConfig, ... }:

{
  home-manager.users.${userConfig.username}.fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      serif = [ "Noto Serif" "DejaVu Serif" ];
      sansSerif = [ "Noto Sans" "DejaVu Sans" ];
      monospace = [ "Hack Nerd Font Mono" "Hack" "DejaVu Sans Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
