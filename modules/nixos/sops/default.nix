{ inputs, pkgs, lib, config, userConfig, ... }: { 

    options = {
      mine.sops.enable =
        lib.mkEnableOption "set up my sops";
    };

    config = lib.mkIf config.mine.sops.enable { 
      environment.systemPackages = with pkgs; [ age sops ];
      sops.defaultSopsFile = "/home/${userConfig.username}/git/sops-ryan/secrets.yaml";
      sops.defaultSopsFormat = "yaml";
      sops.age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";
      sops.secrets."firefox_sync" = {
        owner = config.users.users.${userConfig.username}.name;
      };
      sops.secrets."netdata/cloud/claim_token" = {
        owner = config.users.users.${userConfig.username}.name;
      };
      sops.secrets."netdata/cloud/claim_rooms" = {
        owner = config.users.users.${userConfig.username}.name;
      };
      sops.secrets."ollama/apiBase" = { 
        owner = config.users.users.${userConfig.username}.name;
      };
      sops.secrets."openai/platform_key" = { 
        owner = config.users.users.${userConfig.username}.name;
      };
      sops.secrets."syncthing/password" = {
        owner = config.users.users.${userConfig.username}.name;
       };
      sops.secrets."syncthing/machine_id/mailmac" = {
        owner = config.users.users.${userConfig.username}.name;
       };
      sops.secrets."syncthing/machine_id/mountainball" = {
        owner = config.users.users.${userConfig.username}.name;
       };
      sops.secrets."syncthing/machine_id/starfish" = {
        owner = config.users.users.${userConfig.username}.name;
       };
      sops.secrets."syncthing/machine_id/silvertorch" = {
        owner = config.users.users.${userConfig.username}.name;
       };
      sops.secrets."syncthing/machine_id/saguaro" = {
        owner = config.users.users.${userConfig.username}.name;
       };
      sops.validateSopsFiles = false;
    };


}
