{ inputs, lib, pkgs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
  hermesVersion = "0.17.0";
  hermesRevision = inputs.hermes-agent.rev or null;
  hermesUpstreamPackage = inputs.hermes-agent.packages.${system}.default;
  inherit (hermesUpstreamPackage) hermesVenv;
  hermesSource = inputs.hermes-agent;
  hermesNpmDeps = pkgs.importNpmLock.importNpmLock { npmRoot = hermesSource; };

  hermesNpmBuildAttrs = {
    src = hermesSource;
    npmDeps = hermesNpmDeps;
    npmConfigHook = pkgs.importNpmLock.npmConfigHook;
    npmRoot = ".";
    nodejs = pkgs.nodejs_22;
    npmFlags = [ "--ignore-scripts" ];
    npmInstallFlags = [ "--ignore-scripts" ];
    ESBUILD_BINARY_PATH = "${pkgs.esbuild}/bin/esbuild";
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    doCheck = false;
  };

  hermesTui = pkgs.buildNpmPackage (hermesNpmBuildAttrs // {
    pname = "hermes-tui";
    version = "0.0.1";

    buildPhase = ''
      runHook preBuild
      node ui-tui/scripts/build.mjs
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/hermes-tui
      cp -r ui-tui/dist $out/lib/hermes-tui/dist
      cp ui-tui/package.json $out/lib/hermes-tui/
      runHook postInstall
    '';
  });

  hermesWeb = pkgs.buildNpmPackage (hermesNpmBuildAttrs // {
    pname = "hermes-web";
    version = "0.0.0";

    buildPhase = ''
      runHook preBuild
      cd web
      node ../node_modules/typescript/bin/tsc -b
      node ../node_modules/vite/bin/vite.js build --outDir dist
      cd ..
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r web/dist $out
      runHook postInstall
    '';
  });

  hermesRuntimeDeps = with pkgs; [
    ffmpeg
    git
    nodejs_22
    openssh
    ripgrep
    tirith
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    wl-clipboard
    xclip
  ];

  hermesPackage = pkgs.stdenv.mkDerivation {
    pname = "hermes-agent";
    version = hermesVersion;

    dontUnpack = true;
    dontBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/hermes-agent $out/bin
      cp -r ${hermesSource}/skills $out/share/hermes-agent/skills
      cp -r ${hermesSource}/plugins $out/share/hermes-agent/plugins
      cp -r ${hermesSource}/locales $out/share/hermes-agent/locales
      cp -r ${hermesWeb} $out/share/hermes-agent/web_dist

      mkdir -p $out/ui-tui
      cp -r ${hermesTui}/lib/hermes-tui/* $out/ui-tui/

      for bin in hermes hermes-agent hermes-acp; do
        makeWrapper ${hermesVenv}/bin/$bin $out/bin/$bin \
          --suffix PATH : "${lib.makeBinPath hermesRuntimeDeps}" \
          --set HERMES_BUNDLED_SKILLS $out/share/hermes-agent/skills \
          --set HERMES_BUNDLED_PLUGINS $out/share/hermes-agent/plugins \
          --set HERMES_BUNDLED_LOCALES $out/share/hermes-agent/locales \
          --set HERMES_WEB_DIST $out/share/hermes-agent/web_dist \
          --set HERMES_TUI_DIR $out/ui-tui \
          --set HERMES_PYTHON ${hermesVenv}/bin/python3 \
          --set HERMES_NODE ${lib.getExe pkgs.nodejs_22} \
          ${lib.optionalString (hermesRevision != null) "--set HERMES_REVISION ${hermesRevision}"}
      done

      runHook postInstall
    '';
  };

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
