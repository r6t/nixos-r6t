{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.stable-diffusion-cpp.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
