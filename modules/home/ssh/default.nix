{ lib, config, userConfig, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.ssh.enable
    (import ./config.nix { inherit userConfig; });
}
