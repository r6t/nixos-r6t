# Generate a flatpak module that installs an app behind an enable option.
#
# Usage in modules/default.nix:
#   (mkFlatpakModule { name = "zoom"; appId = "us.zoom.Zoom"; })
#
# This replaces ~14-line boilerplate files that only declare a flatpak package.
{ name
, appId
, description ? "enable ${name} via flatpak"
}:

{ lib, config, ... }: {

  options.mine.flatpak.${name}.enable =
    lib.mkEnableOption description;

  config = lib.mkIf config.mine.flatpak.${name}.enable {
    services.flatpak.packages = [
      { inherit appId; origin = "flathub"; }
    ];
  };
}
