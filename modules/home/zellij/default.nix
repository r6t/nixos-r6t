{ lib, config, ... }: {

  options = {
    mine.home.zellij.enable =
      lib.mkEnableOption "enable zellij in home-manager";
  };

  config = lib.mkIf config.mine.home.zellij.enable {
    home-manager.users.r6t.programs.zellij = {
      enable = true;
      enableFishIntegration = true;
      settings = {
	simplified_ui = false;
	default_shell = "fish";
	pane_frames = false;
        copy_command = "wl-copy";
	scrollback_editor = "nvim";
	theme = "oxocarbon";
	themes.oxocarbon = {
          fg = "#ffffff";
          bg = "#161616";
          black = "#262626";
          red = "#ee5396";
          green = "#42be65";
          yellow = "#ffe97b";
          blue = "#33b1ff";
          magenta = "#ff7eb6";
          cyan = "#3ddbd9";
          white = "#dde1e6";
          bright_black = "#393939";
          bright_red = "#ee5396";
          bright_green = "#42be65";
          bright_yellow = "#ffe97b";
          bright_blue = "#33b1ff";
          bright_magenta = "#ff7eb6";
          bright_cyan = "#3ddbd9";
          bright_white = "#ffffff";
	  orange = "#ffdab9"; # zellij threw an error requiring orange, this isn't part of oxocarbon
        };
      };
    };
  };
}

