{ inputs, lib, config, pkgs, ... }:

let
  inherit (inputs) ssh-keys;
in

{
  options = {
    mine.user.enable =
      lib.mkEnableOption "enable my user account";
  };

  config = lib.mkIf config.mine.user.enable {
    users.users = {
      r6t = {
        isNormalUser = true;
        openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
        extraGroups = [ "docker" "input" "incus" "networkmanager" "wheel" ];
        shell = pkgs.fish;
      };
      root = {
        openssh.authorizedKeys.keyFiles = lib.mkForce [ ssh-keys.outPath ];
        shell = pkgs.fish;
      };
    };
  };
}
