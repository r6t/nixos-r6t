{ lib, config, ... }: {

  options = {
    mine.npm.enable = lib.mkEnableOption "enable npm";
  };

  config = lib.mkIf config.mine.npm.enable {
    programs.npm.enable = true;
  };
}

