# Generate a home-manager module that installs packages behind an enable option.
#
# Usage in modules/default.nix:
#   (mkHomePackageModule { name = "mpv"; packages = p: [ p.mpv-unwrapped ]; })
#
# This replaces ~11-line boilerplate files that only add packages.
{ name
, packages # function: pkgs -> [ derivation ]
, description ? "enable ${name} in home-manager"
}:

{ lib, config, pkgs, userConfig, ... }: {

  options.mine.home.${name}.enable =
    lib.mkEnableOption description;

  config = lib.mkIf config.mine.home.${name}.enable {
    home-manager.users.${userConfig.username}.home.packages = packages pkgs;
  };
}
