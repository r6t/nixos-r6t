{
  flake.modules.nixos.r6t-system-core = { lib, ... }: {
    imports = [
      ../r6t-base/ssh-hardening.nix
      ../r6t-base/system-packages.nix
      ../r6t-base/system-shell.nix
      ../../nixos/fwupd/config.nix
      ../../nixos/fzf/config.nix
      ../../nixos/iperf/config.nix
      ../../nixos/localization/config.nix
      ../../nixos/nix/config.nix
      ../../nixos/ssh/config.nix
      ../../nixos/user/config.nix
    ];

    time.timeZone = lib.mkDefault "America/Los_Angeles";
  };
}
