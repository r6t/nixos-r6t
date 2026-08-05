let
  childDirsWithFile = fileName: dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.filter
      (name: entries.${name} == "directory" && builtins.pathExists (dir + "/${name}/${fileName}"))
      (builtins.attrNames entries);
in
{
  flakeModuleDirs = childDirsWithFile "flake-module.nix";

  flakeModuleImports = dir:
    map (name: dir + "/${name}/flake-module.nix")
      (childDirsWithFile "flake-module.nix" dir);
}
