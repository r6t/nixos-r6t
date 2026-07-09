let
  hosts = [
    "barrel"
    "crown"
    "goldenball"
    "mountainball"
    "saguaro"
  ];

  homeModules = [
    "alacritty"
    "atuin"
    "fish"
    "git"
    "nixvim"
    "zellij"
  ];

  profiles = [
    "booted-host"
    "cgrouped-nix-builds"
    "gaming-host"
    "incus-host"
    "infra-host"
    "infra-networkd-journal"
    "kde-workstation"
    "laptop-workstation"
    "monitoring-agent"
    "nfs-photos-client"
    "nfs-pictures-export"
    "nix-build-throttle"
    "nvidia-container-host"
    "office-desk"
    "r6t-base"
    "r6t-home-core"
    "r6t-home-shell"
    "r6t-system-core"
    "router"
    "sops-host"
    "static-lan-host"
    "sync-host"
    "tailnet-host"
    "thunderbolt-host"
    "zfs-host"
  ];
in
{
  imports =
    (map (name: ../hosts/${name}/flake-module.nix) hosts)
    ++ [ ../modules/flake-module.nix ]
    ++ (map (name: ../modules/home/${name}/flake-module.nix) homeModules)
    ++ (map (name: ../modules/profiles/${name}/flake-module.nix) profiles);
}
