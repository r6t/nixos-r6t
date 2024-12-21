{ lib, config, pkgs, userConfig, ... }: {

  options.mine.paperless.enable =
    lib.mkEnableOption "enable paperless-ngx server with local postgres backend";

  config = lib.mkIf config.mine.paperless.enable {
    services = {
      postgresql = {
        enable = true;
        package = pkgs.postgresql_14;
        dataDir = "/mnt/thunderbay/2TB-E/data/paperless";
        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            trust
          host    all             all             ::1/128                 trust
          host    all             all             100.64.0.0/10           trust
        '';
        initialScript = pkgs.writeText "paperless-init.sql" ''
          CREATE DATABASE paperless;
          CREATE USER paperless WITH PASSWORD 'paperless';
          GRANT ALL PRIVILEGES ON DATABASE paperless TO paperless;
        '';
      };

      paperless = {
        enable = true;
        address = "0.0.0.0";
        dataDir = "/mnt/thunderbay/2TB-E/app-storage/paperless/data";
        consumptionDir = "/mnt/thunderbay/2TB-E/app-storage/paperless/consume";
        mediaDir = "/mnt/thunderbay/2TB-E/app-storage/paperless/media";
        passwordFile = "/plcred";
        settings = {
          PAPERLESS_ALLOWED_HOSTS = "saguaro,saguaro.magic.internal";
          PAPERLESS_DBHOST = "/var/run/postgresql";
          PAPERLESS_DBNAME = "paperless";
          PAPERLESS_DBUSER = "paperless";
          PAPERLESS_DBPASS = "paperless";
          PAPERLESS_OCR_LANGUAGE = "eng";
          PAPERLESS_TIME_ZONE = "America/Los_Angeles";
        };
      };
    };

    system.activationScripts = {
      postgresPermission = ''
        chown -R postgres:postgres /mnt/thunderbay/2TB-E/data/paperless
      '';
      immichPermission = ''
        chown -R paperless:paperless /mnt/thunderbay/2TB-E/app-storage/paperless
      '';
    };

    systemd.services = {
      postgresql = {
        after = [ "thunderbay.service" ];
        requires = [ "thunderbay.service" ];
      };
      paperless-scheduler.after = [ "postgresql.service" ];
      paperless-task-queue.after = [ "postgresql.service" ];
      paperless-web.after = [ "postgresql.service" ];
    };

    users.users.${userConfig.username}.extraGroups = [ "paperless" ];

    networking.firewall.allowedTCPPorts = [ 28981 ];
  };
}

