# Generate a legacy home-manager module that installs packages behind an enable option.
#
# Usage in modules/default.nix:
#   (mkHomePackageModule { name = "mpv"; configModule = import ./config.nix; })
#
# This replaces ~11-line boilerplate files that only add packages.
{ name
, packages ? null # function: pkgs -> [ derivation ]
, configModule ? ({ pkgs, userConfig, ... }: {
    home-manager.users.${userConfig.username}.home.packages = packages pkgs;
  })
, optionsModule ? null
, description ? "enable ${name} in home-manager"
}:

{ lib, config, pkgs, userConfig, ... }: {
  imports = lib.optionals (optionsModule != null) [ optionsModule ];

  options = lib.optionalAttrs (optionsModule == null) {
    mine.home.${name}.enable = lib.mkEnableOption description;
  };

  config = lib.mkIf config.mine.home.${name}.enable (configModule { inherit pkgs userConfig; });
}
