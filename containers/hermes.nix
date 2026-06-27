{ inputs, lib, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  hermesPackage = inputs.hermes-agent.packages.${system}.default;

  hermesTools = with pkgs; [
    gh
    jq
    nodejs_22
    signal-cli
    uv
  ];

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
    inputs.hermes-agent.nixosModules.default
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking = {
    hostName = "hermes";
    firewall.allowedTCPPorts = [ 8642 9119 ];
  };

  environment.systemPackages = hermesTools;

  services.hermes-agent = {
    enable = true;
    package = hermesPackage;
    stateDir = "/var/lib/hermes";
    workingDirectory = "/var/lib/hermes/workspace";
    environmentFiles = [ "/var/lib/hermes/hermes.env" ];
    environment = {
      API_SERVER_ENABLED = "true";
      API_SERVER_HOST = "0.0.0.0";
      API_SERVER_PORT = "8642";
      HERMES_DASHBOARD_PUBLIC_URL = "https://hermes.r6t.io";
      SIGNAL_HTTP_URL = "http://127.0.0.1:8080";
    };
    addToSystemPackages = true;
    extraPackages = hermesTools;
    settings = {
      model.default = "anthropic/claude-sonnet-4";
      terminal = {
        backend = "local";
        timeout = 180;
        home_mode = "auto";
      };
      agent.max_turns = 60;
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
      tool_loop_guardrails = {
        warnings_enabled = true;
        hard_stop_enabled = true;
      };
      platform_toolsets.signal = [ "hermes-signal" ];
      platforms.signal.enabled = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root -"
    "d /var/lib/hermes/signal-cli 0700 hermes hermes -"
  ];

  systemd.services = {
    hermes-agent = {
      wants = [ "signal-cli.service" ];
      after = [ "signal-cli.service" ];
      serviceConfig.EnvironmentFile = "-/var/lib/hermes/hermes.env";
      serviceConfig.ReadWritePaths = lib.mkAfter [ "/mnt/git" ];
    };

    hermes-dashboard = {
      description = "Hermes Agent Dashboard";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "hermes-agent.service" ];
      wants = [ "network-online.target" ];

      environment = {
        HOME = "/var/lib/hermes";
        HERMES_HOME = "/var/lib/hermes/.hermes";
        HERMES_MANAGED = "true";
        MESSAGING_CWD = "/var/lib/hermes/workspace";
      };

      path = [ hermesPackage ] ++ hermesTools;

      serviceConfig = {
        User = "hermes";
        Group = "hermes";
        WorkingDirectory = "/var/lib/hermes/workspace";
        EnvironmentFile = [
          "/var/lib/hermes/.hermes/.env"
          "-/var/lib/hermes/hermes.env"
        ];
        ExecStart = "${hermesPackage}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open";
        Restart = "always";
        RestartSec = 5;
        UMask = "0007";
      };
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
        EnvironmentFile = [
          "-/var/lib/hermes/.hermes/.env"
          "-/var/lib/hermes/hermes.env"
        ];
        ExecStart = signalCliDaemon;
        Restart = "always";
        RestartSec = 10;
      };
    };
  };
}
