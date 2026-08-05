let
  discovery = import ./discovery.nix;
in
{
  imports =
    [ ../modules/flake-module.nix ]
    ++ (discovery.flakeModuleImports ../modules/home)
    ++ (discovery.flakeModuleImports ../modules/profiles);
}
