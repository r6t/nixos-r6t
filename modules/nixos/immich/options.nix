{ lib, ... }:

{
  options.mine.immich = {
    enable = lib.mkEnableOption "enable immich server";

    oidcIssuerUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional OIDC issuer URL for Immich authentication.";
      example = "https://id.example.com";
    };
  };
}
