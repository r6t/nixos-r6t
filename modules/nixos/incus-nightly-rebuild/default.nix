{ lib, config, pkgs, ... }:

let
  cfg = config.mine.incus-nightly-rebuild;
in
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

  config = lib.mkIf cfg.enable {
    systemd.services.incus-nightly-rebuild = {
      description = "Nightly nix build for running incus container images";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 ${cfg.flakePath}/containers/build.py --nightly";
        WorkingDirectory = cfg.flakePath;
        Nice = 19;
        IOSchedulingClass = "idle";
      };
      path = [ pkgs.nix pkgs.git ];
    };

    systemd.timers.incus-nightly-rebuild = {
      description = "Timer for nightly incus container image builds";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.time;
        Persistent = true;
        RandomizedDelaySec = "15m";
      };
    };
  };
}
