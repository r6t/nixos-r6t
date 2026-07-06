{
  flake.modules.nixos.hedgehog = {
    imports = [
      ./configuration.nix
      {
        nixpkgs.config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      }
    ];
  };
}
