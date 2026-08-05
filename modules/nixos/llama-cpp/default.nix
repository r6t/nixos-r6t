{ lib, config, pkgs, outputs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.llama-cpp.enable (
    import ./config.nix { inherit lib config pkgs outputs; }
  );
}
