{ lib, config, ... }:

let
  cfg = config.mine.pinchflat;
  stateDir = "/var/lib/pinchflat";
  extrasDir = "${stateDir}/extras";
  ytDlpConfigDir = "${extrasDir}/yt-dlp-configs";

  linkRuntimeFile =
    { source, target, description }:
    ''
      if [ -r ${lib.escapeShellArg source} ]; then
        if [ -e ${lib.escapeShellArg target} ] && [ ! -L ${lib.escapeShellArg target} ]; then
          if [ -s ${lib.escapeShellArg target} ]; then
            echo "pinchflat: leaving existing non-empty ${description} in place"
          else
            rm -f ${lib.escapeShellArg target}
            ln -s ${lib.escapeShellArg source} ${lib.escapeShellArg target}
          fi
        else
          ln -sfn ${lib.escapeShellArg source} ${lib.escapeShellArg target}
        fi
      fi
    '';
in
{
  # 8945/tcp
  services.pinchflat = {
    enable = true;
    inherit (cfg)
      mediaDir
      port
      user
      group
      selfhosted
      secretsFile
      extraConfig
      openFirewall;
  };

  systemd.services.pinchflat = lib.mkMerge [
    {
      preStart = ''
        set -eu

        mkdir -p ${lib.escapeShellArg extrasDir} ${lib.escapeShellArg ytDlpConfigDir}
        chmod 0750 ${lib.escapeShellArg stateDir} ${lib.escapeShellArg extrasDir} ${lib.escapeShellArg ytDlpConfigDir}

        ${lib.optionalString (cfg.cookieFile != null) (linkRuntimeFile {
          source = cfg.cookieFile;
          target = "${extrasDir}/cookies.txt";
          description = "cookies.txt";
        })}

        ${lib.optionalString (cfg.ytDlpBaseConfigFile != null) (linkRuntimeFile {
          source = cfg.ytDlpBaseConfigFile;
          target = "${ytDlpConfigDir}/base-config.txt";
          description = "base-config.txt";
        })}
      '';

      serviceConfig = {
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = !(builtins.hasAttr "YT_DLP_COOKIES_FROM_BROWSER" cfg.extraConfig);
        ProtectSystem = "strict";
        ReadWritePaths = [ stateDir cfg.mediaDir ];
        RestrictSUIDSGID = true;
        StateDirectoryMode = "0750";
      };
    }

    # Default to manual/on-demand starts, preserving the old mountainball behavior.
    (lib.mkIf (!cfg.startAtBoot) {
      wantedBy = lib.mkForce [ ];
    })
  ];
}
