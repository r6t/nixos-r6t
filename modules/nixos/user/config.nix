{ inputs, lib, pkgs, ... }:

let
  inherit (inputs) ssh-keys;
in
{
  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
      extraGroups = [ "docker" "input" "incus" "networkmanager" "wheel" ];
      shell = pkgs.fish;
    };
    root = {
      openssh.authorizedKeys.keyFiles = lib.mkForce [ ssh-keys.outPath ];
    };
  };

  # Defense-in-depth: deny root login regardless of whether mine.ssh is enabled.
  services.openssh.settings.PermitRootLogin = lib.mkDefault "no";
}
