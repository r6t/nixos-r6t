{ lib, ... }:

{
  options.mine.asusctl = {
    enable = lib.mkEnableOption "enable asusctl";

    auraConfigs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Per-device aura LED configs keyed by USB product ID (e.g. "1a30",
        "18c6"). Each value is the text content of
        /etc/asusd/aura_<id>.ron. Written as a read-only Nix store
        symlink so asusd cannot overwrite it at runtime.
      '';
    };
  };
}
