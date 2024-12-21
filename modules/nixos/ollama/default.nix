{ lib, config, ... }:

{
  options = {
    mine.ollama.enable =
      lib.mkEnableOption "enable ollama server (nvidia)";
  };
  config = lib.mkIf config.mine.ollama.enable {
    services.ollama = {
      openFirewall = true;
      enable = true;
      acceleration = "cuda";
      host = "0.0.0.0";
      port = 11434;
    };
  };
}
