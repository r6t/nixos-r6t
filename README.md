[Flake](https://www.youtube.com/watch?v=JCeYq72Sko0) for managing personal [NixOS](https://nixos.org/) systems 💻

#### Use:
I typically generate NixOS and home-manager config in the same step, and then upgrade into the latest with:
`nixos-rebuild switch --flake .#hostname`

#### Structure:
```
├── flake.nix               # Inputs (sources) and outputs (system configurations)
├── hosts                   # System/host definitions
├── modules                 # Used by host definitions
│   ├── default.nix         # Modules must be listed here
│   ├── flatpak             # Flatpak modules
│   ├── home                # User level home-manager modules
│   └── nixos               # System level modules
```
