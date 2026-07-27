{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/docker/default.nix
  ];

  networking = {
    hostName = "stirlingpdf";
    firewall = {
      allowedTCPPorts = [ 89 ];
      extraCommands = ''
        iptables -I INPUT 1 -i br-+ -p udp --dport 53 -j ACCEPT
        iptables -I INPUT 1 -i br-+ -p tcp --dport 53 -j ACCEPT
      '';
    };
  };

  mine.docker.enable = true;

  # Docker bridge networks and some containerized services expect this.
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  virtualisation.oci-containers = {
    backend = "docker";
    containers.stirlingpdf = {
      image = "stirlingtools/stirling-pdf:latest";
      pull = "always";
      ports = [ "89:8080" ];
      volumes = [
        "/var/lib/stirlingpdf/tessdata:/usr/share/tessdata:rw"
        "/var/lib/stirlingpdf/configs:/configs:rw"
        "/var/log/stirlingpdf:/logs:rw"
      ];
      environment = {
        DOCKER_ENABLE_SECURITY = "false";
        LANGS = "en_GB,en_US,ar_AR,de_DE,fr_FR,es_ES,zh_CN,zh_TW,ca_CA,it_IT,sv_SE,pl_PL,ro_RO,ko_KR,pt_BR,ru_RU,el_GR,hi_IN,hu_HU,tr_TR,id_ID";
        METRICS_ENABLED = "false";
        SECURITY_ENABLELOGIN = "false";
        SYSTEM_DEFAULTLOCALE = "en-US";
        SYSTEM_GOOGLEVISIBILITY = "false";
        SYSTEM_MAXFILESIZE = "100";
        UI_APPNAME = "Stirling-PDF";
        UI_APPNAMENAVBAR = "r6 Technology | Stirling-PDF";
        UI_HOMEDESCRIPTION = "r6 Technology | Stirling-PDF";
      };
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/stirlingpdf 0755 root root -"
    "d /var/lib/stirlingpdf/configs 0755 root root -"
    "d /var/lib/stirlingpdf/tessdata 0755 root root -"
    "d /var/log/stirlingpdf 0755 root root -"
  ];
}
