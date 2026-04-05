# Auto-discover all modules under flatpak/, home/, and nixos/.
# Any subdirectory containing a default.nix is imported as a module.
# The lib/ directory is excluded (it contains helpers, not modules).
_:

let
  discoverModules = dir:
    let
      entries = builtins.readDir (./. + "/${dir}");
      subdirs = builtins.filter
        (name: entries.${name} == "directory")
        (builtins.attrNames entries);
      hasDefault = name:
        builtins.pathExists (./. + "/${dir}/${name}/default.nix");
    in
    map (name: ./. + "/${dir}/${name}/default.nix")
      (builtins.filter hasDefault subdirs);
in
{
  imports =
    discoverModules "flatpak"
    ++ discoverModules "home"
    ++ discoverModules "nixos";
}
