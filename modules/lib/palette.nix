# Oxocarbon dark palette — single source of truth for all tool themes.
# Each color is defined once as a hex string. Consumers import this file
# and use the conversion helpers to get the format they need.
#
# Usage:
#   let palette = import ../../lib/palette.nix; in
#   palette.hex.teal          # "#08bdba"
#   palette.rgb.teal          # "8,189,186"
#   palette.rgbTriple.teal    # { r = 8; g = 189; b = 186; }
#   palette.zellijRgb.teal    # "8 189 186"  (space-separated for KDL)

let
  colors = {
    base00 = "161616"; # terminal / editor background
    base01 = "262626"; # subtle backgrounds, panels
    base02 = "393939"; # selection, hover, borders
    base03 = "525252"; # comments, muted text
    base04 = "dde1e6"; # secondary foreground
    base05 = "f2f4f8"; # primary foreground
    teal = "08bdba"; # primary accent, active states
    cyan = "3ddbd9"; # secondary accent
    blue = "78a9ff"; # keywords, links, primary slot
    pink = "ee5396"; # errors
    lightpink = "ff7eb6"; # warnings, emphases
    green = "42be65"; # success, added diffs
    violet = "be95ff"; # types, info, non-normal modes
    lightblue = "82cfff"; # numbers, subtle accents
    darkviolet = "1c1a26"; # UI bar background tint
    yellow = "ffe97b"; # occasional accent (alacritty)
    lightblue33 = "33b1ff"; # alternate blue (alacritty)
    coolGray = "6f6f6f"; # IBM Carbon Gray 60 — visible muted text (opencode)
    darkblue = "1a1f2e"; # bar/panel background tint (opencode)
  };

  # Parse a 6-char hex string into { r, g, b } integers
  hexToTriple = hex:
    let
      hexDigit = c:
        let
          digits = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            "a" = 10;
            "b" = 11;
            "c" = 12;
            "d" = 13;
            "e" = 14;
            "f" = 15;
          };
        in
        digits.${c};
      charAt = n: builtins.substring n 1 hex;
      r = hexDigit (charAt 0) * 16 + hexDigit (charAt 1);
      g = hexDigit (charAt 2) * 16 + hexDigit (charAt 3);
      b = hexDigit (charAt 4) * 16 + hexDigit (charAt 5);
    in
    { inherit r g b; };

  mapColors = f: builtins.mapAttrs (_: f) colors;
in
{
  # "#rrggbb" — for JSON configs (opencode, alacritty)
  hex = mapColors (v: "#${v}");

  # { r, g, b } attrset — for programmatic use
  rgbTriple = mapColors hexToTriple;

  # "r,g,b" — for KDE .colors files
  rgb = mapColors (v:
    let t = hexToTriple v;
    in "${toString t.r},${toString t.g},${toString t.b}");

  # "r g b" — for zellij KDL theme format
  zellijRgb = mapColors (v:
    let t = hexToTriple v;
    in "${toString t.r} ${toString t.g} ${toString t.b}");
}
