{ inputs, lib, config, ... }: {

  options = {
    mine.nix.enable = lib.mkEnableOption "enable my usual nix config";
  };

  config = lib.mkIf config.mine.nix.enable {
    nix = {
      # This will add each flake input as a registry
      # To make nix3 commands consistent with your flake
      registry = lib.mapAttrs (_: flake: { inherit flake; })
        (lib.filterAttrs (_: lib.isType "flake") inputs);

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well, awesome!
      nixPath = [ "/etc/nix/path" ];

      # NixOS garbage collection
      gc = {
        automatic = true;
        dates = "monthly";
        options = "--delete-older-than-60d";
      };

      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" "cgroups" ];
        # optimize for 16 cores
        max-jobs = 16;
        substituters = [
          "https://cache.nixos.org/"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          #          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };

    environment.etc = lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;
  };
}

