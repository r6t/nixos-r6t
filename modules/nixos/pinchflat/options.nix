{ lib, ... }:

{
  options.mine.pinchflat = {
    enable = lib.mkEnableOption "enable pinchflat";

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/thunderbay/8TB-D/storage/plex/youtube";
      description = "Directory where Pinchflat downloads media.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8945;
      description = "Port for the Pinchflat web interface.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "r6t";
      description = "User account that runs Pinchflat.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group that runs Pinchflat.";
    };

    selfhosted = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Use Pinchflat's selfhosted run context instead of requiring a secrets file.";
    };

    secretsFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional runtime environment file for Pinchflat secrets outside the Nix store.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf (lib.types.nullOr (lib.types.oneOf [
        lib.types.bool
        lib.types.int
        lib.types.str
      ]));
      default = { };
      description = "Additional Pinchflat environment configuration.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the Pinchflat web interface port in the local firewall.";
    };

    startAtBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether pinchflat.service should be wanted by multi-user.target.";
    };

    cookieFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional mutable Netscape-format YouTube cookie file. When readable at
        service start, it is linked to Pinchflat's runtime cookies.txt path.
      '';
    };

    ytDlpBaseConfigFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional mutable yt-dlp base config file. When readable at service
        start, it is linked to Pinchflat's base-config.txt path.
      '';
    };
  };
}
