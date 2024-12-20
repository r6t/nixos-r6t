{ lib, config, pkgs, userConfig, ... }: { 

    options = {
      mine.paperless.enable =
        lib.mkEnableOption "enable paperless-ngx server with local postgres backend";
    };

    config = lib.mkIf config.mine.paperless.enable { 

      # PostgreSQL database
      services.postgresql = {
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

      # Paperless-ngx
      services.paperless = {
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

      # Activation scripts to set storage permissions
      system.activationScripts = {
        postgresPermission = ''
          chown -R postgres:postgres /mnt/thunderbay/2TB-E/data/paperless
        '';
        immichPermission = ''
          chown -R paperless:paperless /mnt/thunderbay/2TB-E/app-storage/paperless
        '';
      };

      # Service launch sequence including dependency on storage availability (thunderbay)
      systemd.services.postgresql = {
        after = [ "thunderbay.service" ];
        requires = [ "thunderbay.service" ];
      };
      systemd.services.paperless-scheduler.after = [ "postgresql.service" ];
      systemd.services.paperless-task-queue.after = [ "postgresql.service" ];
      systemd.services.paperless-web.after = [ "postgresql.service" ];

      # Add me to paperless group
      # TODO: make the user dynamic
      users.users.${userConfig.username}.extraGroups = [ "paperless" ];

      # Open firewall
      networking.firewall.allowedTCPPorts = [ 28981 ];
    };
}
