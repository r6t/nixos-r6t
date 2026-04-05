# Wrap home-manager config for NixOS (home-manager.users wrapper) or standalone mode.
#
# Usage in portable modules:
#   let wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };
#   in { config = lib.mkIf cfg.enable (wrapHome hmConfig); }
#
# For modules with extra NixOS-only config outside home-manager (e.g. sops secrets):
#   config = lib.mkIf cfg.enable (wrapHome hmConfig // lib.optionalAttrs isNixOS { sops.secrets = ...; });
{ isNixOS, userConfig }:

hmConfig:
if isNixOS then {
  home-manager.users.${userConfig.username} = hmConfig;
} else
  hmConfig
