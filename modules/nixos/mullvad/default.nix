{ lib, config, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.mullvad.enable (import ./config.nix);
}
