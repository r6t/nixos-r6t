{ lib, config, pkgs, ... }:

let
  immichPort = 2283;
in

{
  options = {
    mine.immich.enable =
      lib.mkEnableOption "enable immich server";
  };
  config = lib.mkIf config.mine.immich.enable {

    systemd = {
      tmpfiles.rules = [
        "d /etc/immich 0750 root root -"
        "d /var/cache/immich 0755 immich immich -"
        "d /var/lib/immich/cache 0755 immich immich -"
        "d /var/cache/huggingface 0755 immich immich -"
        "d /var/cache/huggingface/hub 0755 immich immich -"
        "d /home/immich/.cache 0755 immich immich -"
        "d /home/immich/.cache/huggingface 0755 immich immich -"
        "d /var/empty/.cache 0755 immich immich -"
        "d /var/empty/.cache/matplotlib 0755 immich immich -"
      ];
    };

    users.users.immich.extraGroups = [ "video" "render" ];
    services.immich = {
      enable = true;
      host = "0.0.0.0";
      port = immichPort;
      accelerationDevices = null;
      environment = {
        MACHINE_LEARNING_ACCELERATION = "cuda";
        MACHINE_LEARNING_CACHE_FOLDER = "/var/cache/immich";
        MACHINE_LEARNING_MODEL_TTL = "300";
        AUTHENTICATION_OIDC_ENABLED = "true";
        AUTHENTICATION_OIDC_ISSUER_URL = "https://pid.r6t.io";
        AUTHENTICATION_OIDC_AUTO_REGISTER = "true";
        AUTHENTICATION_OIDC_BUTTON_TEXT = "Login with Pocket ID";
        AUTHENTICATION_PASSWORD_ENABLED = "false";
      };
      machine-learning = {
        # environment.LD_LIBRARY_PATH = "${pkgs.python312Packages.onnxruntime}/lib    /python3.12/site-packages/onnxruntime/capi";
        environment = {
          LD_LIBRARY_PATH = "${pkgs.python312Packages.onnxruntime}/lib/python3.12/site-packages/onnxruntime/capi";
          MACHINE_LEARNING_DEVICE_IDS = "0";
          MACHINE_LEARNING_CACHE_FOLDER = "/var/cache/immich";
          MACHINE_LEARNING_ACCELERATION = "cuda";
          MACHINE_LEARNING_MODEL_TTL = "300";
          MPLCONFIGDIR = "/var/cache/immich";
          HF_HOME = "/var/cache/immich";
        };
      };
    };
  };
}
