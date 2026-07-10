{ lib, config, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.fprintd.enable (import ./config.nix);
}
