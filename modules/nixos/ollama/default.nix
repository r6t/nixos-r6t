{ lib, config, ... }:

{
  options = {
    mine.ollama.enable =
      lib.mkEnableOption "enable ollama";
  };
  config = lib.mkIf config.mine.ollama.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0"; # 8080/tcp default
      openFirewall = true;
      acceleration = "cuda";
    };
  };
}
