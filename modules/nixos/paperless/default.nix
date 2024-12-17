{ lib, config, pkgs, ... }: { 

    options = {
      mine.paperless.enable =
        lib.mkEnableOption "enable paperless-ngx server with local postgres backend";
    };

    config = lib.mkIf config.mine.paperless.enable { 

      # PostgreSQL database
      services.postgresql = {
        enable = true;
        package = pkgs.postgresql_14;
        dataDir = "/var/lib/postgresql/paperless";
        authentication = pkgs.lib.mkOverride 10 ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            trust
          host    all             all             ::1/128                 trust
          host    all             all             192.168.6.0/24          trust
          host    all             all             172.17.0.0/16           trust
          host    all             all             172.18.0.0/16           trust
          host    all             all             172.19.0.0/16           trust
          host    all             all             172.20.0.0/16           trust
          host    all             all             172.21.0.0/16           trust
          host    all             all             172.22.0.0/16           trust
          host    all             all             172.23.0.0/16           trust
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
        dataDir = "/var/lib/paperless/data";
        consumptionDir = "/var/lib/paperless/consume";
        mediaDir = "/var/lib/paperless/media";
        passwordFile = "/plcred";
        settings = {
          PAPERLESS_ALLOWED_HOSTS = "100.64.0.5,fd7a:115c:a1e0::5,saguaro,saguaro.magic.internal";
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
        createPostgresDir = ''
          mkdir -p /var/lib/postgresql/paperless
          chown -R postgres:postgres /var/lib/postgresql/paperless
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
      users.users.r6t.extraGroups = [ "paperless" ];

      # Open firewall
      networking.firewall.allowedTCPPorts = [ 28981 ];

    };
}
