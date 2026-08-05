{ lib, config, pkgs, ... }:

let
  cfg = config.mine.home-router;
  router = import ./scripts.nix { inherit lib pkgs cfg; };
in
lib.mkMerge [
  (import ./kernel.nix { inherit lib cfg; })
  (import ./network.nix {
    inherit lib pkgs cfg;
    inherit (router) diagnosticsScript;
  })
  (import ./firewall.nix {
    inherit lib cfg;
    inherit (router) nftPortSet;
  })
  (import ./dns-dhcp.nix { inherit lib cfg; })
  (import ./cake.nix { inherit lib pkgs cfg; })
  (import ./health-check.nix {
    inherit lib pkgs cfg;
    inherit (router) healthCheckScript;
  })
  (import ./wan-watchdog.nix {
    inherit lib pkgs cfg;
    inherit (router) wanWatchdogScript;
  })
]
