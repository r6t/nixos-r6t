let
  discovery = import ./discovery.nix;
in
{
  imports =
    (discovery.flakeModuleImports ../hosts)
    ++ [ ../modules/flake-module.nix ]
    ++ (discovery.flakeModuleImports ../modules/home)
    ++ (discovery.flakeModuleImports ../modules/profiles);
}
