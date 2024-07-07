{ lib, config, pkgs, ... }:

let
  cfg = config.mine.home.darktable;
in
{
  options.mine.home.darktable = {
    enable = lib.mkEnableOption "enable darktable in home-manager";
    useInMemoryDatabase = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use in-memory database for Darktable";
    };
    syncDatabaseFile = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Sync Darktable database file between workstations";
    };
    syncPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to the synced Darktable folder";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.r6t = {
      home.packages = with pkgs; [ darktable ];

      # launcher/wrapper script
      home.file.".local/bin/darktable-wrapper" = {
        executable = true;
        text = ''
          #!/bin/sh
          ${lib.optionalString cfg.useInMemoryDatabase "DARKTABLE_OPTS=\"--library :memory:\""}
          ${lib.optionalString cfg.syncDatabaseFile "DARKTABLE_OPTS=\"--configdir ${cfg.syncPath}/.config/darktable\""}
          exec ${pkgs.darktable}/bin/darktable $DARKTABLE_OPTS "$@"
        '';
      };
      home.sessionPath = [ "$HOME/.local/bin" ];

    #   # Configure Darktable to look for updated XMP files at startup
    #   xdg.configFile."darktable/darktablerc".text = ''
    #     plugins/lighttable/export/force_lcms2=FALSE
    #     plugins/lighttable/export/iccintent=0
    #     plugins/lighttable/export/iccprofile=
    #     plugins/lighttable/export/style=
    #     plugins/lighttable/export/style_append=FALSE
    #     plugins/lighttable/select/win_path=
    #     session/use_xmp_sidecar_files=TRUE
    #     session/look_for_updated_xmp_files=TRUE
    #   '';
    };
  };
}
