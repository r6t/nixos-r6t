{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.awscli.enable =
        lib.mkEnableOption "enable awscli in home-manager";
    };

    config = lib.mkIf config.mine.home.awscli.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [
			  awscli2
			  ssm-session-manager-plugin
			];
    };
}
