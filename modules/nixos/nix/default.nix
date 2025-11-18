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
        download-buffer-size = 524288000;
        experimental-features = [ "nix-command" "flakes" "cgroups" ];
        # optimize for 16 cores
        max-jobs = 16;
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

