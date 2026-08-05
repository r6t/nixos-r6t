{ lib, ... }:

{
  options.mine.home.darktable = {
    enable = lib.mkEnableOption "darktable";

    enableRusticl = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Mesa Rusticl OpenCL support for darktable.";
    };
  };
}
