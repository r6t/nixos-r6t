{ ... }:

{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    ../modules/nixos/tailscale/default.nix
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "roon";
  mine.tailscale.enable = true;

  services = {
    dnsmasq = {
      settings = {
        address = [
          # specific overrides
          "/grafana.r6t.io/192.168.6.1"
          # wildcard so app LXCs hit router caddy
          "/r6t.io/192.168.6.10"
        ];
      };
    };

    roon-server = {
      enable = true;
      openFirewall = true;
    };
  };
}
