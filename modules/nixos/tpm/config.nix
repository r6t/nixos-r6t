{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    clevis
    tpm2-tools
  ];
}
