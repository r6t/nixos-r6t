{ lib, config, ... }:

{
  options = {
    mine.open-webui.enable =
      lib.mkEnableOption "enable open-webui";
  };
  config = lib.mkIf config.mine.open-webui.enable {
    services.open-webui = {
      enable = true;
      host = "0.0.0.0"; # 8080/tcp default
      openFirewall = true;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_AUTH = "False";
      };
    };
  };
}
