{ lib, config, pkgs, userConfig, ... }:
let
  cfg = config.mine.home.signal-desktop;
in
{

  options = {
    mine.home.signal-desktop.enable =
      lib.mkEnableOption "enable signal-desktop in home-manager";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userConfig.username}.home.packages = [
      # Pin to kwallet6 backend so the encryption key is portable across DEs.
      # Electron auto-detects based on active DE, which breaks when switching.
      (pkgs.signal-desktop.override { commandLineArgs = "--password-store=kwallet6"; })
      pkgs.kdePackages.kwalletmanager
    ];

    # kwalletd6 daemon + D-Bus service files (auto-activates on first access)
    environment.systemPackages = [ pkgs.kdePackages.kwallet ];

    # Auto-unlock kwallet with login password at GDM
    security.pam.services.gdm-password.kwallet.enable = true;
  };
}
