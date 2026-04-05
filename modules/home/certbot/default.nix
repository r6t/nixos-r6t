import ../../lib/mkHomePackageModule.nix {
  name = "certbot";
  packages = p: [ p.certbot2 p.ssm-session-manager-plugin ];
}
