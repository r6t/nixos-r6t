{ lib, config, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.adb.enable (import ./config.nix);
}
