{ lib, pkgs, cfg }:

let
  routerArgs = "${cfg.wanInterface} ${cfg.lanInterface} ${cfg.lanAddress}";
in
{
  diagnosticsScript = pkgs.writeShellScriptBin "router-diagnostics" ''
    exec ${pkgs.fish}/bin/fish ${./router-diagnostics.fish} ${routerArgs}
  '';

  healthCheckScript = pkgs.writeShellScriptBin "router-health-check" ''
    exec ${pkgs.fish}/bin/fish ${./router-health-check.fish} ${routerArgs}
  '';

  wanWatchdogScript = pkgs.writeShellScriptBin "wan-watchdog" ''
    exec ${pkgs.fish}/bin/fish ${./wan-watchdog.fish} ${cfg.wanInterface} ${toString cfg.wanWatchdog.failuresBeforeRestart} ${lib.concatStringsSep " " cfg.wanWatchdog.targets}
  '';

  nftPortSet = ports:
    if builtins.length ports == 1
    then toString (builtins.head ports)
    else "{ ${lib.concatStringsSep ", " (map toString ports)} }";
}
