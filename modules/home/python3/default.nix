{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.python3.enable =
        lib.mkEnableOption "enable python3 and my common packages in home-manager";
    };

    config = lib.mkIf config.mine.home.python3.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ 
        python3
        python311Packages.boto3
        python311Packages.pip
        python311Packages.troposphere
        python311Packages.jq
        python311Packages.yq
      ];
    };
}