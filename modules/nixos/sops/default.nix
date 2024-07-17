{ inputs, pkgs, lib, config, ... }: { 

    options = {
      mine.sops.enable =
        lib.mkEnableOption "set up my sops";
    };

    config = lib.mkIf config.mine.sops.enable { 
      environment.systemPackages = with pkgs; [ age sops ];
      sops.defaultSopsFile = "/home/r6t/git/sops-ryan/secrets.yaml";
      sops.defaultSopsFormat = "yaml";
      sops.age.keyFile = "/home/r6t/.config/sops/age/keys.txt";
      sops.secrets."firefox_sync" = {
        owner = config.users.users.r6t.name;
      };
      sops.secrets."openai/platform_key" = { 
        owner = config.users.users.r6t.name;
      };
      sops.secrets."syncthing/machine_id/mailmac" = {
        owner = config.users.users.r6t.name;
       };
      sops.secrets."syncthing/machine_id/mountainball" = {
        owner = config.users.users.r6t.name;
       };
      sops.secrets."syncthing/machine_id/photolab" = {
        owner = config.users.users.r6t.name;
       };
      sops.secrets."syncthing/machine_id/silvertorch" = {
        owner = config.users.users.r6t.name;
       };
      sops.secrets."syncthing/machine_id/saguaro" = {
        owner = config.users.users.r6t.name;
       };
      sops.validateSopsFiles = false;
    };


}
