{ lib, config, inputs, ... }: let
  # ad-hoc import nixpkgs-unstable to set config. I'd rather avoid the extra import but was having trouble getting it to work otherwise
  nixpkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
  netdataPackage = nixpkgs-unstable.netdataCloud;
in { 
    options = {
      mine.netdata.enable =
        lib.mkEnableOption "enable and configure netdata";
    };

    config = lib.mkIf config.mine.netdata.enable { 
      services.netdata = {
        enable = true;
        # token file gets deleted during activation, subsequent reloads fail
        # claimTokenFile = /var/lib/netdata/cloud.d/token;
        package = netdataPackage;
      };

      systemd.services = {
        netdata.unitConfig = {
          Requires = [ "generate-netdata-claim.service" ];
          After = [ "generate-netdata-claim.service" ];
        };
        "generate-netdata-claim" = {
          enable = true;
          script = builtins.readFile ./generate-netdata-claim.sh;
          wantedBy = [ "multi-user.target" ];
          unitConfig = {
            PartOf = [ "netdata.service" ];
            Before = [ "netdata.service" ];
          };
        };
      };
    };
}
