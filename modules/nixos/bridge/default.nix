{ lib, config, ... }: {

  options = {
    mine.bridge.enable =
      lib.mkEnableOption "enable moon network bridge";
  };

  config = lib.mkIf config.mine.bridge.enable {
    networking = {
      interfaces = {
        br0 = {
          useDHCP = true;
        };
      };
      bridges.br0.interfaces = [ "enp89s0" ];
    };
  };
}
