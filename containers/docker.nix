{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-lxc-base.nix
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/docker/default.nix
  ];

  networking.hostName = "docker-lxc";

  mine.nvidia-cuda.enable = true;
  mine.docker = {
    enable = true;
  };
}

