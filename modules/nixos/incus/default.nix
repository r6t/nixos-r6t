{ lib, config, ... }:
let
  cfg = config.mine.incus;
  svc = "incus";
in
{
  options.mine.incus = {
    enable = lib.mkEnableOption "virtualization.incus module";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.${svc} = {
      enable = true;
      preseed = { };
    };
    networking.nftables.enable = true;
  };
}
