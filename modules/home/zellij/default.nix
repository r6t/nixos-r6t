{ lib, config, userConfig, ... }: {

  options = {
    mine.home.zellij.enable =
      lib.mkEnableOption "enable zellij in home-manager";
  };

  config = lib.mkIf config.mine.home.zellij.enable {
    home-manager.users.${userConfig.username}.programs.zellij = {
      attachExistingSession = true;
      enable = true;
      enableFishIntegration = true;
      settings = {
        show_startup_tips = false;
        simplified_ui = true;
        default_shell = "fish";
        default_layout = "compact";
        pane_frames = false;
        copy_command = "wl-copy";
        scrollback_editor = "nvim";
        theme = "oxocarbon";
        keybinds = {
          unbind = [ "Ctrl g" "Ctrl p" "Ctrl n" "Ctrl t" "Ctrl s" "Ctrl o" "Ctrl m" ];
          normal = {
            "bind \"Super z\"" = { SwitchToMode = "locked"; };
            "bind \"Super p\"" = { SwitchToMode = "pane"; };
            "bind \"Super n\"" = { SwitchToMode = "resize"; };
            "bind \"Super t\"" = { SwitchToMode = "tab"; };
            "bind \"Super s\"" = { SwitchToMode = "scroll"; };
            "bind \"Super o\"" = { SwitchToMode = "session"; };
            "bind \"Super m\"" = { SwitchToMode = "move"; };
            "bind \"Alt n\"" = { NewPane = ""; };
            "bind \"Alt h\"" = { MoveFocus = "Left"; };
            "bind \"Alt l\"" = { MoveFocus = "Right"; };
            "bind \"Alt j\"" = { MoveFocus = "Down"; };
            "bind \"Alt k\"" = { MoveFocus = "Up"; };
          };
          locked = {
            "bind \"Super z\"" = { SwitchToMode = "normal"; };
          };
        };

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
          orange = "#ffdab9";
        };
      };
    };
  };
}

