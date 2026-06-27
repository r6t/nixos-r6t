{ pkgs, ... }:

let
  signalCliDaemon = pkgs.writeShellScript "signal-cli-hermes-daemon" ''
    set -eu

    if [ -z "''${SIGNAL_ACCOUNT:-}" ]; then
      echo "SIGNAL_ACCOUNT is not set; signal-cli daemon is idle."
      exec ${pkgs.coreutils}/bin/sleep infinity
    fi

    exec ${pkgs.signal-cli}/bin/signal-cli \
      --config /var/lib/hermes/signal-cli \
      --account "$SIGNAL_ACCOUNT" \
      daemon \
      --http 127.0.0.1:8080
  '';
in
{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/docker/default.nix
  ];

  networking = {
    hostName = "hermes";
    firewall = {
      allowedTCPPorts = [ 8642 9119 ];
      extraCommands = ''
        iptables -I INPUT 1 -i br-+ -p udp --dport 53 -j ACCEPT
        iptables -I INPUT 1 -i br-+ -p tcp --dport 53 -j ACCEPT
      '';
    };
  };

  mine.docker.enable = true;

  # Docker bridge networks and some containerized services expect this.
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  users.groups.hermes.gid = 10000;
  users.users.hermes = {
    isSystemUser = true;
    group = "hermes";
    uid = 10000;
    home = "/var/lib/hermes";
  };

  environment.systemPackages = with pkgs; [
    jq
    signal-cli
  ];

  virtualisation.oci-containers = {
    backend = "docker";
    containers.hermes = {
      image = "nousresearch/hermes-agent:latest";
      pull = "always";
      cmd = [ "gateway" "run" ];
      volumes = [
        "/var/lib/hermes:/opt/data"
        "/mnt/git:/mnt/git"
      ];
      environment = {
        HERMES_UID = "10000";
        HERMES_GID = "10000";
        HERMES_DASHBOARD = "1";
        HERMES_DASHBOARD_PUBLIC_URL = "https://hermes.r6t.io";
        API_SERVER_ENABLED = "true";
        API_SERVER_HOST = "0.0.0.0";
        API_SERVER_PORT = "8642";
        SIGNAL_HTTP_URL = "http://127.0.0.1:8080";
      };
      networks = [ "host" ];
      extraOptions = [ "--shm-size=1g" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root -"
    "d /mnt/git 0755 root root -"
    "d /var/lib/hermes 0750 hermes hermes -"
    "d /var/lib/hermes/signal-cli 0700 hermes hermes -"
  ];

  systemd.services = {
    docker-hermes = {
      wants = [ "signal-cli.service" ];
      after = [ "signal-cli.service" ];
    };

    signal-cli = {
      description = "Signal CLI daemon for Hermes Agent";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      path = [ pkgs.signal-cli ];

      serviceConfig = {
        User = "hermes";
        Group = "hermes";
        WorkingDirectory = "/var/lib/hermes";
        EnvironmentFile = [ "-/var/lib/hermes/.env" ];
        ExecStart = signalCliDaemon;
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
