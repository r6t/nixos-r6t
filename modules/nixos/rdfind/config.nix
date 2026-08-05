{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ rdfind ];
}
