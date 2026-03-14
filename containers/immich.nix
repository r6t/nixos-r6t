{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/immich/default.nix
    ../modules/nixos/nvidia-cuda/default.nix
  ];

  networking.hostName = "immich";

  mine = {
    immich.enable = true;
    nvidia-cuda = {
      enable = true;
      package = "production";
      installCudaToolkit = false;
    };
  };

  nixpkgs.overlays = [
    (_final: prev: {
      onnxruntime = prev.onnxruntime.override { cudaSupport = true; };
    })
  ];
}

