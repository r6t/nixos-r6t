# Private Wrapper Flake

This public repo is the reusable module/profile layer. A separate private flake
owns real hosts, hardware inventory, LAN/storage topology, Incus runtime state,
and private runbooks.

## Boundary

Keep private:

- `hosts/`
- Incus image definitions, runtime profiles, and seed files
- host-specific scripts and troubleshooting runbooks
- real MACs, PCI/USB IDs, static leases, LAN IPs, hostnames, storage UUIDs, and
  local paths
- local agent instructions that mention private infrastructure

Keep public:

- reusable NixOS/Home Manager modules
- reusable profiles under `modules/profiles/`
- generic packages under `pkgs/`
- devshells and formatting/check wiring

## Wrapper Shape

A private flake should import this repo and instantiate real hosts there:

```nix
{
  inputs = {
    nixos-r6t.url = "github:r6t/nixos-r6t";

    nixpkgs.follows = "nixos-r6t/nixpkgs";
    home-manager.follows = "nixos-r6t/home-manager";
    hardware.follows = "nixos-r6t/hardware";
    nix-flatpak.follows = "nixos-r6t/nix-flatpak";
    nixvim.follows = "nixos-r6t/nixvim";
    plasma-manager.follows = "nixos-r6t/plasma-manager";
    sops-nix.follows = "nixos-r6t/sops-nix";
  };

  outputs = inputs@{ self, nixos-r6t, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      userConfig = {
        username = "replace-me";
        homeDirectory = "/home/replace-me";
      };

      specialArgs = {
        inherit inputs userConfig;
        outputs = self;
        isNixOS = true;
      };

      mkHost = modules: nixpkgs.lib.nixosSystem {
        inherit system specialArgs modules;
      };
    in
    {
      packages.${system} = { };

      nixosConfigurations.example-host = mkHost [
        nixos-r6t.modules.nixos.r6t-base
        nixos-r6t.modules.nixos.r6t-home-core
        ./hosts/example-host/configuration.nix
      ];
    };
}
```

Copy each old `hosts/<host>/flake-module.nix` profile list into the matching
private `nixosConfigurations.<host>.modules` list, replacing
`inputs.self.modules.nixos.<profile>` with `nixos-r6t.modules.nixos.<profile>`.

## Migration Notes

This public repo ignores private paths so local copies can remain beside the
public module code during migration. Do not rely on ignored files as the only
copy long term; move them into the private flake checkout before cleaning the
workspace.
