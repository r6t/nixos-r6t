{ lib, config, ... }:

let
  cfg = config.mine.open-webui;
in
{
  services.open-webui = {
    enable = true;
    inherit (cfg) host port;
    stateDir = "/var/lib/open-webui"; # open-webui nixpkgs default
    inherit (cfg) environmentFile;
    environment =
      {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_AUTH = "True";
      }
      // lib.optionalAttrs (cfg.ollamaUrl != "") {
        OLLAMA_API_BASE_URL = cfg.ollamaUrl;
      }
      // lib.optionalAttrs (cfg.openaiApiUrls != [ ]) {
        OPENAI_API_BASE_URLS = lib.concatStringsSep ";" cfg.openaiApiUrls;
        # Only set OPENAI_API_KEYS here when keys are explicitly provided AND no
        # environmentFile is in use. systemd applies Environment= after EnvironmentFile=,
        # so a placeholder here would override the real key from the file.
      }
      // lib.optionalAttrs (cfg.openaiApiUrls != [ ] && cfg.openaiApiKeys != [ ] && cfg.environmentFile == null) {
        OPENAI_API_KEYS = lib.concatStringsSep ";" cfg.openaiApiKeys;
      }
      // lib.optionalAttrs (cfg.imageGenerationUrl != "") {
        # A1111-compatible image generation via stable-diffusion.cpp sd-server.
        # sd-server exposes /sdapi/v1/ which open-webui's AUTOMATIC1111 engine uses.
        IMAGE_GENERATION_ENGINE = "automatic1111";
        AUTOMATIC1111_BASE_URL = cfg.imageGenerationUrl;
        # Enable image generation feature in open-webui
        ENABLE_IMAGE_GENERATION = "True";
      };
  };
}
