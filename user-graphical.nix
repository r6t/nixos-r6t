{ config, pkgs, ... }:
{
  home-manager.users.r6t = { pkgs, ...}: {
    home.file.".config/hypr/hyprland.conf".source = config/hypr/hyprland.conf;
    home.file.".config/waybar/config".source = config/waybar/config;
    home.packages = with pkgs; [
      betaflight-configurator
      bitwarden
      brave
      brightnessctl # display brightness
      dconf # hyprland support
      firefox-wayland
      freecad
      freerdp
      grim # screenshot functionality
      kate # KDE text editor
      kdiff3 # KDE utility
      krename # KDE utility
      krusader # KDE file manager
      libsForQt5.breeze-gtk # KDE Breeze theme
      libsForQt5.breeze-icons # KDE app icons
      libsForQt5.elisa # KDE music player
      libsForQt5.kio-extras # KDE support
      libsForQt5.polkit-kde-agent # KDE privlege escalation helper
      libsForQt5.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      libsForQt5.qt5ct # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      libnotify # reqd for mako
      mako # notification system developed by swaywm maintainer
      protonmail-bridge
      librewolf
      pamixer # pulseaudio controls
      playerctl # media keys
      remmina
      rofi-wayland
      slurp # screenshot functionality
      ungoogled-chromium
      virt-manager
      virt-viewer
      vlc
      webcord # Discord client
      xdg-utils # for opening default programs when clicking links
      waybar
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      wdisplays # wayland display config
      wlogout
      wlr-randr # wayland
      youtube-dl
    ];
    programs.alacritty = {
      enable = true;
      settings = {
      font = {
        size = 14.0;
      };
      selection = {
        save_to_clipboard = true;
      };
      };
    };
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird;
      profiles.r6t = {
        isDefault = true;
      };
    };
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
        # continue.continue # https://github.com/NixOS/nixpkgs/pull/289289
        dracula-theme.theme-dracula
	      ms-azuretools.vscode-docker
        ms-python.isort
        ms-python.python
	      ms-python.vscode-pylance # unfree
	      redhat.vscode-yaml
        vscodevim.vim
        yzhang.markdown-all-in-one
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
              {
                name = "boto3-ide";
                publisher = "Boto3typed";
                version = "0.5.4";
                sha256 = "dXK/R3ynLBF/QWxXL88pg7h1TZHRsE/Wo/vfS6faHqA=";
              }
            ] ++ (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
          mktplcRef = {
            name = "continue";
            publisher = "Continue";
            version = "0.9.65";
            sha256 = "92zkLJpaMwAwPhczvgBgkLIVqN60vJ7K0wuYrtqrh5E=";
            arch = "linux-x64";
          };
          nativeBuildInputs = [
            pkgs.autoPatchelfHook
          ];
          buildInputs = [ pkgs.stdenv.cc.cc.lib ];
        })
      userSettings = {
        "window.titleBarStyle" = "custom";
      };
    };
    home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
      	XDG_CURRENT_SESSION = "hyprland";
        QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
	      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;

        # XDG_SESSION_TYPE = "wayland";
        # WAYLAND_DISPLAY="wayland-1";
        # GDK_BACKEND="wayland";
        # XDG_DATA_DIRS=/path/to/data_dirs:${XDG_DATA_DIRS};
        # XDG_CONFIG_DIRS=/path/to/config_dirs:${XDG_CONFIG_DIRS};
    };
  };
}
