{ lib, config, ... }:

{

  options = {
    mine.ssh.enable =
      lib.mkEnableOption "enable and configure ssh, explicitly open 22/tcp";
  };

  config = lib.mkIf config.mine.ssh.enable (import ./config.nix);
}
