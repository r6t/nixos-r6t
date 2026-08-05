{ lib, ... }:

{
  options.mine.incus-nightly-rebuild = {
    enable = lib.mkEnableOption "nightly nix builds for running incus containers";

    flakePath = lib.mkOption {
      type = lib.types.str;
      description = "Absolute path to the nixos-r6t flake directory";
    };

    time = lib.mkOption {
      type = lib.types.str;
      default = "03:00";
      description = "Time to run nightly rebuild (systemd OnCalendar format)";
    };
  };
}
