{ lib, ... }:

{
  options.mine.printing.enable =
    lib.mkEnableOption "enable printing with brlaser + discovery";
}
