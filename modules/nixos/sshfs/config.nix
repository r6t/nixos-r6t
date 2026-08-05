{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ sshfs ];
}
