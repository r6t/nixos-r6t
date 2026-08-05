let
  discovery = import ./discovery.nix;
in
{
  imports = discovery.flakeModuleImports ../pkgs;
}
