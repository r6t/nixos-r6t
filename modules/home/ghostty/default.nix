{ lib, config, pkgs, userConfig ? null, ... }:

let
  cfg = config.mine.home.ghostty;
  isNixOS = userConfig != null;

  # Shared ghostty configuration
  # On macOS, package is null (installed via Homebrew) but config is still managed
  ghosttyConfig = {
    programs.ghostty = {
      enable = true;
      # On macOS, we install via Homebrew for proper .app bundle
      # On Linux, use the nix package
      package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;

      enableFishIntegration = true;

      settings = {
        # Shell - use fish, then launch zellij from fish config or manually
        # On macOS, need full path since login shell may not have nix in PATH yet
        command =
          if pkgs.stdenv.isDarwin
          then "$HOME/.nix-profile/bin/fish"
          else "zellij -l welcome";

        # Window appearance
        window-decoration = if pkgs.stdenv.isDarwin then true else "server";
        background-opacity = 1.0;
        window-padding-x = 4;
        window-padding-y = 4;

        # Color rendering - use linear-corrected for consistent sRGB colors
        # macOS defaults to 'native' (Display P3) which can make colors look faded
        alpha-blending = "linear-corrected";

        # Font
        font-size = 13;

        # Clipboard
        copy-on-select = "clipboard";

        # Oxocarbon-inspired colorscheme (traditional ANSI mapping)
        background = "161616";
        foreground = "ffffff";
        selection-background = "525252";
        selection-foreground = "ffffff";
        cursor-color = "ffffff";

        # Normal colors
        palette = [
          "0=#262626"
          "1=#ee5396"
          "2=#42be65"
          "3=#ffe97b"
          "4=#33b1ff"
          "5=#ff7eb6"
          "6=#3ddbd9"
          "7=#dde1e6"
          # Bright colors
          "8=#393939"
          "9=#ee5396"
          "10=#42be65"
          "11=#ffe97b"
          "12=#33b1ff"
          "13=#ff7eb6"
          "14=#3ddbd9"
          "15=#ffffff"
        ];
      };
    };
  };

in
{
  options.mine.home.ghostty.enable =
    lib.mkEnableOption "enable ghostty in home-manager";

  config = lib.mkIf cfg.enable (
    if isNixOS then {
      # NixOS mode: configure via home-manager.users wrapper
      home-manager.users.${userConfig.username} = ghosttyConfig;
    } else
    # Standalone home-manager mode: configure directly
      ghosttyConfig
  );
}
