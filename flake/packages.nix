let
  discovery = import ./discovery.nix;
in
{
  imports = [
    ../containers/flake-module/default.nix
  ] ++ discovery.flakeModuleImports ../pkgs;
}
