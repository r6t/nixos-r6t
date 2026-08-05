{ lib, ... }:

{
  options.mine.home.ssh = {
    enable = lib.mkEnableOption "configure ssh in home-manager";

    matchBlocks = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "SSH match blocks passed to programs.ssh.matchBlocks.";
    };
  };
}
