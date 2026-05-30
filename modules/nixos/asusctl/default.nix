{ lib, config, pkgs, ... }: {

  options = {
    mine.asusctl = {
      enable = lib.mkEnableOption "enable asusctl";

      auraConfigs = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = ''
          Per-device aura LED configs keyed by USB product ID (e.g. "1a30",
          "18c6"). Each value is the text content of
          /etc/asusd/aura_<id>.ron. Written as a read-only Nix store
          symlink so asusd cannot overwrite it at runtime.
        '';
      };
    };
  };

  config = lib.mkIf config.mine.asusctl.enable {
    environment.systemPackages = with pkgs; [ asusctl ];
    services.asusd = {
      enable = true;
      auraConfigs = lib.mapAttrs (_: text: { inherit text; }) config.mine.asusctl.auraConfigs;
    };
    # The upstream service file has no [Install] section and relies on D-Bus
    # activation, but no D-Bus .service activation file is shipped. Force it
    # to start at boot.
    systemd.services.asusd.wantedBy = [ "multi-user.target" ];
    # asusd.service uses ProtectSystem=strict + ReadWritePaths=/etc/asusd/
    # Systemd namespace setup fails with status=226/NAMESPACE if /etc/asusd
    # doesn't exist yet. The NixOS upstream module only creates files under
    # /etc/asusd when config options are set. Ensure the directory exists
    # before asusd starts so the sandbox can set up its bind-mount overlay.
    systemd.tmpfiles.rules = [ "d /etc/asusd 0755 root root -" ];
  };
}
