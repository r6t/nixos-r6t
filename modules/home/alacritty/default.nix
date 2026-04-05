{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.alacritty;
  wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };
  c = (import ../../lib/palette.nix).hex;

  # Shared alacritty configuration
  alacrittyConfig = {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          # macOS handles decorations differently
          decorations = if pkgs.stdenv.isDarwin then "buttonless" else "none";
        };
        terminal.shell =
          if pkgs.stdenv.isDarwin then {
            program = "${pkgs.zellij}/bin/zellij";
          } else {
            # Wrap in systemd scope so zellij server survives alacritty exit
            program = "${pkgs.systemd}/bin/systemd-run";
            args = [ "--scope" "--user" "${pkgs.zellij}/bin/zellij" ];
          };
        colors = {
          primary = {
            background = c.base00;
            foreground = "#ffffff";
          };
          search = {
            matches = {
              foreground = "CellBackground";
              background = c.pink;
            };
          };
          normal = {
            inherit (c) green cyan yellow;
            black = c.base01;
            red = c.pink;
            blue = c.lightblue33;
            magenta = c.lightpink;
            white = c.base04;
          };
          bright = {
            inherit (c) green cyan yellow;
            black = c.base02;
            red = c.pink;
            blue = c.lightblue33;
            magenta = c.lightpink;
            white = "#ffffff";
          };
        };
        font = {
          size = 13.0;
        };
        selection = {
          save_to_clipboard = true;
        };
      };
    };
  };

in
{
  options.mine.home.alacritty.enable =
    lib.mkEnableOption "enable alacritty in home-manager";

  config = lib.mkIf cfg.enable (wrapHome alacrittyConfig);
}
