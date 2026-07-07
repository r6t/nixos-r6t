{ lib, config, pkgs, userConfig, ... }: {

  options.mine.scansnap.enable = lib.mkEnableOption "enable scansnap s1300i support";

  config = lib.mkIf config.mine.scansnap.enable (import ./config.nix { inherit pkgs userConfig; });
}

#         # 1. Scan with optimized settings
#         scanimage \
#           --device-name $device_id \
#           --format=png \
#           --source "ADF Duplex" \
#           --mode Gray \        # Grayscale reduces file size dramatically
#           --mode Color \         # Gray or Color
#           --resolution 200 \   # Lower resolution for documents
#           --batch=scan-%d.png || exit 1
#         
#         # 2. Convert with compression
#         magick scan-*.png \
#           -units PixelsPerInch \
#           -density 200 \
#           -define pdf:use-trimbox=true \
#           -compress JPEG \     # Explicit JPEG compression
#           -quality 60 \        # Quality balance (60-80 for documents)
#           I found compress JPEG and quality 60 acutally made files bigger, going from 1.3 to 1.7MB in an example.
#           scansnap-temp.pdf || exit 1
#         
#         # 3. OCR with aggressive optimization, going from 1.3 to 1.2MB in the same example.
#         ocrmypdf \
#           --optimize 3 \       # Maximum optimization level
#           --jpeg-quality 40 \   # Aggressive compression
#           --jbig2-lossy \      # Better compression for B&W text
#           --remove-vectors \   # Prevent vector art bloat
#           --image-dpi 200 \    # Match scan resolution
# To Modify Further:
#    Quality Tradeoffs: Adjust -quality/--jpeg-quality (40-80 range)
#    Color Documents: Keep --mode Color but add --color-conversion-strategy RGB in OCRmyPDF
#    Resolution: For very dense text, increase to --resolution 250
