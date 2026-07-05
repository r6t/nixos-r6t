{ inputs, self, ... }:

{
  perSystem = { system, ... }: {
    # Devshells for both Linux and macOS.
    devShells = import ../devshells.nix {
      pkgs = import inputs.nixpkgs { inherit system; };
      inherit (inputs) nixpkgs;
      inherit self;
    };
  };
}
