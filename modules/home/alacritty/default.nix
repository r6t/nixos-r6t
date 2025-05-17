{ lib, config, userConfig, ... }: {

  options = {
    mine.home.alacritty.enable =
      lib.mkEnableOption "enable alacritty in home-manager";
  };

  config = lib.mkIf config.mine.home.alacritty.enable {
    home-manager.users.${userConfig.username}.programs.alacritty = {
      enable = true;
      settings = {
        window = {
          decorations = "none";
        };
        terminal.shell = {
          program = "zellij";
          args = [ "-l" "welcome" ];
        };
        colors = {
          primary = {
            background = "#161616";
            foreground = "#ffffff";
          };
          search = {
            matches = {
              foreground = "CellBackground";
              background = "#ee5396";
            };
            # footer_bar = {
            #   background = "#262626";
            #   foreground = "#ffffff";
            # };
          };
          normal = {
            black = "#262626";
            red = "#ee5396";
            green = "#42be65";
            yellow = "#ffe97b";
            blue = "#33b1ff";
            magenta = "#ff7eb6";
            cyan = "#3ddbd9";
            white = "#dde1e6";
          };
          bright = {
            black = "#393939";
            red = "#ee5396";
            green = "#42be65";
            yellow = "#ffe97b";
            blue = "#33b1ff";
            magenta = "#ff7eb6";
            cyan = "#3ddbd9";
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
}
