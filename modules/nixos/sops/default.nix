{ inputs, pkgs, lib, config, ... }: { 

    options = {
      mine.sops.enable =
        lib.mkEnableOption "set up my sops";
    };

    config = lib.mkIf config.mine.sops.enable { 
      sops.defaultSopsFile = "/home/r6t/git/sops-ryan/secrets.yaml";
      sops.defaultSopsFormat = "yaml";
      # sops.age.sshKeyPaths = [ "/home/r6t/.ssh/id_ed25519" ];
      sops.age.keyFile = "/home/r6t/.config/sops/age/keys.txt";
      sops.secrets."test_variable" = { };
      # sops.secrets."syncthing/machine_id/mailmac" = { };
      # sops.secrets."syncthing/machine_id/mountainball" = { };
      # sops.secrets."syncthing/machine_id/photolab" = { };
      # sops.secrets."syncthing/machine_id/silvertorch" = { };
      # sops.secrets."syncthing/machine_id/saguaro" = { };
      sops.validateSopsFiles = false;
      environment.systemPackages = with pkgs; [ age sops ];
    };
}