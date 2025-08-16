{ config, lib, pkgs, ... }:

let
  cfg = config.mine.caddy;
  caddyCredsPath = "/run/caddy-credentials";
  caddyCredsFile = "${caddyCredsPath}/route53.env";

  # The definitive solution: A self-contained, but "impure" derivation
  # that bypasses the sandbox network issues to build Caddy with xcaddy.
  caddy-with-route53-plugin = pkgs.stdenv.mkDerivation rec {
    pname = "caddy-with-route53";
    version = "2.9.1"; # Using the known compatible version of Caddy

    src = pkgs.fetchFromGitHub {
      owner = "caddyserver";
      repo = "caddy";
      rev = "v${version}";
      # This is the correct, verified hash for Caddy v2.9.1
      sha256 = "sha256-hzDd2BNTZzjwqhc/STbSAHnNlP7g1cFuMehqU1LumQE=";
    };

    # We need Go and xcaddy in the build environment.
    nativeBuildInputs = [ pkgs.go pkgs.xcaddy ];

    # THIS IS THE FINAL FIX:
    # 1. This flag disables the network sandbox, allowing the build
    #    to use the host's real network connection.
    __impure = true;

    # The build process uses xcaddy to compile Caddy with the Route53 plugin.
    # Because the build is impure, xcaddy can successfully download modules.
    buildPhase = ''
      runHook preBuild
      # xcaddy and go both need a writable HOME directory.
      export HOME=$TMPDIR
      # Build Caddy v2.9.1 with the compatible Route53 plugin v1.5.1
      xcaddy build v${version} \
        --with github.com/caddy-dns/route53@v1.5.1
      runHook postBuild
    '';

    # Install the compiled Caddy binary into the package's output path.
    installPhase = ''
      runHook preInstall
      install -Dm755 caddy $out/bin/caddy
      runHook postInstall
    '';

    meta = with lib; {
      description = "An impure build of Caddy v${version} with the Route53 DNS plugin";
      homepage = "https://caddyserver.com";
      license = licenses.asl20;
      mainProgram = "caddy";
      platforms = platforms.linux;
    };
  };

in
{
  options.mine.caddy = {
    enable = lib.mkEnableOption "Enable Caddy with Route53 DNS challenges";
    domain = lib.mkOption { type = lib.types.str; default = "r6t.io"; };
    email = lib.mkOption { type = lib.types.str; default = "domains@r6t.io"; };
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          extraConfig = lib.mkOption { type = lib.types.lines; default = ""; };
          reverseProxy = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
          redirect = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
          respond = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
        };
      });
      default = { };
      description = "Virtual hosts configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "d ${caddyCredsPath} 0750 root caddy -" ];
    systemd.services.write-caddy-route53-credentials = {
      description = "Write Route53 credentials for Caddy";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      before = [ "caddy.service" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        set -eu
        cat > "${caddyCredsFile}" << EOF
        AWS_ACCESS_KEY_ID=$(cat /run/secrets/aws_acm/crown/caddy/aws_access_key_id)
        AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/aws_acm/crown/caddy/aws_secret_access_key)
        AWS_REGION=$(cat /run/secrets/aws_acm/crown/caddy/aws_region)
        EOF
        chown root:caddy "${caddyCredsFile}"
        chmod 0640 "${caddyCredsFile}"
      '';
    };

    services.caddy = {
      enable = true;
      package = caddy-with-route53-plugin;
      environmentFile = caddyCredsFile;
      globalConfig = ''
        {
          email ${cfg.email}
          acme_dns route53
        }
      '';
      virtualHosts = lib.mapAttrs
        (name: hostCfg: {
          extraConfig =
            let
              reverseProxyConfig = lib.optionalString (hostCfg.reverseProxy != null) "reverse_proxy ${hostCfg.reverseProxy}";
              redirectConfig = lib.optionalString (hostCfg.redirect != null) "redir ${hostCfg.redirect}";
              respondConfig = lib.optionalString (hostCfg.respond != null) "respond \"${hostCfg.respond}\"";
              autoConfig = lib.concatStringsSep "\n" (lib.filter (s: s != "") [ reverseProxyConfig redirectConfig respondConfig ]);
            in
            if hostCfg.extraConfig != "" then hostCfg.extraConfig else autoConfig;
        })
        cfg.virtualHosts;
    };

    networking.firewall.allowedTCPPorts = [ 80 443 ];
    systemd.services.caddy = {
      wants = [ "write-caddy-route53-credentials.service" ];
      after = [ "write-caddy-route53-credentials.service" ];
    };
  };
}

