{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    ../modules/nixos/immich/default.nix
    ../modules/nixos/nvidia-cuda/default.nix
  ];

  networking.hostName = "immich";

  mine = {
    immich.enable = true;
    nvidia-cuda.enable = true;
  };

  nixpkgs.overlays = [
    (_final: prev: {
      onnxruntime = prev.onnxruntime.override { cudaSupport = true; };
    })
  ];
}

