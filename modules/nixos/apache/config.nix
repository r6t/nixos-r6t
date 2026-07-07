{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ apacheHttpd ];
}
