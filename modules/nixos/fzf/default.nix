{ lib, config, pkgs, ... }: {

  options = {
    mine.fzf.enable =
      lib.mkEnableOption "enable fzf";
  };

  config = lib.mkIf config.mine.fzf.enable {
    environment.systemPackages = with pkgs; [ fzf ];
  };
}
