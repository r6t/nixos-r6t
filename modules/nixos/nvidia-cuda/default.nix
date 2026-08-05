{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.nvidia-cuda.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
