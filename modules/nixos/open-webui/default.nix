{ lib, config, ... }:
let
  cfg = config.mine.open-webui;
in
{

  options.mine.open-webui = {
    enable = lib.mkEnableOption "enable open-webui";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for open-webui to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8087;
      description = "Port for open-webui to listen on.";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Ollama API base URL. Set to "" to disable Ollama backend.
      '';
    };

    openaiApiUrls = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        List of OpenAI-compatible API base URLs. Each entry is a separate
        backend — e.g. a local llama-server and a remote provider such as
        OpenRouter. Open WebUI merges the model lists from all endpoints into
        a single model picker. Joined with ";" for OPENAI_API_BASE_URLS.
      '';
      example = [
        "http://localhost:8080/v1"
        "https://openrouter.ai/api/v1"
      ];
    };

    openaiApiKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        API keys corresponding to each entry in openaiApiUrls, in the same
        order. Use "none" for local endpoints that do not require a key.
        Joined with ";" for OPENAI_API_KEYS.

        Prefer environmentFile for secrets — any key set here will be stored
        in the Nix store (world-readable on the host). Use this only for
        non-sensitive placeholder values (e.g. "none" for a local endpoint).
        Set the real remote key via environmentFile instead.
      '';
      example = [ "none" ];
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a file containing environment variable assignments loaded at
        service start (EnvironmentFile= in the systemd unit). Use this to
        inject secrets such as OPENAI_API_KEYS without storing them in the
        Nix store. Values in this file override anything set via the
        environment option.

        The file must be readable by the open-webui service user. Bind-mount
        it into the container via the incus profile before referencing it here.

        Example file contents (one assignment per line):
          OPENAI_API_KEYS=none;sk-or-v1-yourkey
      '';
      example = "/run/secrets/open-webui-env";
    };

    imageGenerationUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Base URL for the image generation backend (A1111-compatible API).
        stable-diffusion.cpp sd-server exposes /sdapi/v1/ at this URL.
        Example: "http://localhost:1234" (sd-server default port).
        Open WebUI will use AUTOMATIC1111 engine mode pointing at this URL.
        Set to "" to disable image generation in Open WebUI.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
