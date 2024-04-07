{ inputs, lib, config, ... }: 

let
  inherit (inputs) ssh-keys;
in

{ 

    options = {
      mine.nixpkgs.enable =
        lib.mkEnableOption "enable my user account";
    };

    config = lib.mkIf config.mine.nixpkgs.enable { 
      users.users = {
        r6t = {
          isNormalUser = true;
          openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
          # input group reqd for waybar
          extraGroups = [ "docker" "input" "networkmanager" "wheel"];
          shell = pkgs.zsh;
        };
      };
    };
}