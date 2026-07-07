{ pkgs, ... }:

{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts-color-emoji
      font-awesome
      hack-font
      nerd-fonts.hack
      nerd-fonts.blex-mono
      source-sans-pro
    ];
  };
}
