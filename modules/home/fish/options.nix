{ lib, userConfig, ... }:

{
  options.mine.home.fish = {
    enable = lib.mkEnableOption "enable fish in home-manager";

    flakePath = lib.mkOption {
      type = lib.types.str;
      default = "${userConfig.homeDirectory}/git/nixos-r6t";
      description = "Default flake path used by fish helpers such as nd and nrs.";
    };
  };
}
