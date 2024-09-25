{ lib, config, inputs, ... }: let
  # ad-hoc import nixpkgs-unstable to set config. I'd rather avoid the extra import but was having trouble getting it to work otherwise
  nixpkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
  #  config = { allowUnfree = true; };
  };
  netdataPackage = nixpkgs-unstable.netdata;
in { 
    options = {
      mine.netdata.enable =
        lib.mkEnableOption "enable and configure netdata";
    };

    config = lib.mkIf config.mine.netdata.enable { 
      services.netdata = {
        enable = true;
        package = netdataPackage;
      };
    };
}
