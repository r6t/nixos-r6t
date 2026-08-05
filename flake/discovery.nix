let
  childDirsWithFile = fileName: dir:
    let
      entries = if builtins.pathExists dir then builtins.readDir dir else { };
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
