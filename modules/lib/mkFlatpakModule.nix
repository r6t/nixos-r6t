# Generate a flatpak module that installs an app behind an enable option.
#
# Usage in modules/default.nix:
#   (mkFlatpakModule { name = "zoom"; appId = "us.zoom.Zoom"; })
#
# This replaces ~14-line boilerplate files that only declare a flatpak package.
{ name
, appId ? null
, configModule ? null
, description ? "enable ${name} via flatpak"
}:

{ lib, config, ... }:
let
  moduleConfig =
    if configModule != null then
      configModule
    else
      {
        services.flatpak.packages = [
          { inherit appId; origin = "flathub"; }
        ];
      };
in
{

  options.mine.flatpak.${name}.enable =
    lib.mkEnableOption description;

  config = lib.mkIf config.mine.flatpak.${name}.enable moduleConfig;
}
