{ lib, config, isNixOS ? true, ... }:

let
  # Host identifier: first + last character of the hostname, the same shorthand
  # the fish prompt builds at runtime (modules/home/fish/config.nix,
  # fish_prompt). jumping-cholla -> ja, mountainball -> ml.
  slugOf = h:
    if builtins.stringLength h < 2
    then h
    else builtins.substring 0 1 h
      + builtins.substring (builtins.stringLength h - 1) 1 h;
in
{
  options.mine.home.zellij = {
    enable = lib.mkEnableOption "enable zellij in home-manager";

    sshzAddKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "~/.ssh/id_ecdsa" ];
      description = ''
        Key files `sshz` loads with `ssh-add` when the local agent holds no
        identities, so the agent it forwards is usable for git on the remote
        host. Empty means only warn. Keys listed here are offered to every
        host `sshz` connects to, so list only keys meant for those hosts. A
        passphrase-protected key will prompt.
      '';
    };

    hostSlug = lib.mkOption {
      type = lib.types.str;
      # NixOS hosts derive it: `hostname` there returns networking.hostName.
      # Standalone home-manager has no hostname to read, so those targets set
      # it themselves -- and must, since `hostname` can return an FQDN whose
      # slug is not guessable from the configuration.
      default = if isNixOS then slugOf config.networking.hostName else "";
      example = "ja";
      description = ''
        Short host identifier used in the zellij session name
        (`fish-main-<hostSlug>`), matching the fish prompt's host shorthand.
      '';
    };
  };
}
