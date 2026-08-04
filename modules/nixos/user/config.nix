{ config, inputs, lib, pkgs, ... }:

let
  cfg = config.mine.user;
  inherit (inputs) ssh-keys;
in
{
  users.users = {
    ${cfg.name} = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf cfg.authorizedKeysFromGithub [ ssh-keys.outPath ];
      inherit (cfg) extraGroups;
      shell = pkgs.fish;
    };
    root = {
      openssh.authorizedKeys.keyFiles = lib.mkIf cfg.authorizeRootKeys (lib.mkForce [ ssh-keys.outPath ]);
    };
  };

  # Defense-in-depth: deny root login regardless of whether mine.ssh is enabled.
  services.openssh.settings.PermitRootLogin = lib.mkDefault "no";
}
