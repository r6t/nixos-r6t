{
  flake.modules.nixos.r6t-base = { lib, ... }: {
    imports = [
      ./ssh-hardening.nix
      ./system-packages.nix
      ./system-shell.nix
    ];

    mine = {
      bootloader.enable = lib.mkDefault true;
      fwupd.enable = lib.mkDefault true;
      fzf.enable = lib.mkDefault true;
      iperf.enable = lib.mkDefault true;
      localization.enable = lib.mkDefault true;
      nix.enable = lib.mkDefault true;
      ssh.enable = lib.mkDefault true;
      tailscale.enable = lib.mkDefault true;
      user.enable = lib.mkDefault true;
    };
  };
}
