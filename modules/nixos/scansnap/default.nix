{ lib, config, pkgs, userConfig, ... }: {

  options.mine.scansnap.enable = lib.mkEnableOption "enable scansnap s1300i support";

  config = lib.mkIf config.mine.scansnap.enable {
    hardware.sane = {
      enable = true;
      drivers.scanSnap.enable = true;
    };

    users.users.${userConfig.username} = {
      extraGroups = [ "scanner" "lp" ];
    };

    environment.systemPackages = with pkgs; [
      imagemagick
      ocrmypdf
      (writeScriptBin "scansnap-front" ''
        #!${fish}/bin/fish
        set timestamp (date +"%Y-%m-%d-%H-%M-%S")
        set device_id "epjitsu:libusb:001:031"
        set output_dir "/home/${userConfig.username}/scans"

        mkdir -p $output_dir

        scanimage \
          --device-name $device_id \
          --format=png \
          --source "ADF Front" \
          --mode Color \
          --resolution 300 \
          --batch=scan-%d.png \
        && magick scan-*.png \
          -units PixelsPerInch \
          -density 300 \
          -define pdf:use-trimbox=true \
          scansnap-temp.pdf \
        && ocrmypdf \
          --rotate-pages \
          --deskew \
          --clean-final \
          --image-dpi 300 \
          scansnap-temp.pdf "$output_dir/scansnap-front-$timestamp.pdf" \
        && rm scan-*.png scansnap-temp.pdf
      '')
      (writeScriptBin "scansnap-duplex" ''
        #!${fish}/bin/fish
        set timestamp (date +"%Y-%m-%d-%H-%M-%S")
        set device_id "epjitsu:libusb:001:031"
        set output_dir "/home/${userConfig.username}/scans"

        mkdir -p $output_dir

        scanimage \
          --device-name $device_id \
          --format=png \
          --source "ADF Duplex" \
          --mode Color \
          --resolution 300 \
          --batch=scan-%d.png \
        && magick scan-*.png \
          -units PixelsPerInch \
          -density 300 \
          -define pdf:use-trimbox=true \
          scansnap-temp.pdf \
        && ocrmypdf \
          --rotate-pages \
          --deskew \
          --clean-final \
          --image-dpi 300 \
          scansnap-temp.pdf "$output_dir/scansnap-duplex-$timestamp.pdf" \
        && rm scan-*.png scansnap-temp.pdf
      '')
    ];

    system.activationScripts.create-scan-dir = ''
      mkdir -p /home/${userConfig.username}/scans
      chown ${userConfig.username} /home/${userConfig.username}/scans
    '';
  };
}

#         #!${fish}/bin/fish
#         set timestamp (date +"%Y-%m-%d-%H-%M-%S")
#         set device_id "epjitsu:libusb:001:031"
#         set output_dir "/home/${userConfig.username}/scans"
#         
#         mkdir -p $output_dir
#         
#         # 1. Scan with optimized settings
#         scanimage \
#           --device-name $device_id \
#           --format=png \
#           --source "ADF Duplex" \
#           --mode Gray \        # Grayscale reduces file size dramatically
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
#           scansnap-temp.pdf || exit 1
#         
#         # 3. OCR with aggressive optimization
#         ocrmypdf \
#           --rotate-pages \
#           --deskew \
#           --optimize 3 \       # Maximum optimization level
#           --jpeg-quality 40 \   # Aggressive compression
#           --jbig2-lossy \      # Better compression for B&W text
#           --remove-vectors \   # Prevent vector art bloat
#           --image-dpi 200 \    # Match scan resolution
#           scansnap-temp.pdf "$output_dir/scansnap-duplex-$timestamp.pdf" || exit 1
#         
#         # 4. Cleanup
#         rm -f scan-*.png scansnap-temp.pdf
# To Modify Further:
#    Quality Tradeoffs: Adjust -quality/--jpeg-quality (40-80 range)
#    Color Documents: Keep --mode Color but add --color-conversion-strategy RGB in OCRmyPDF
#    Resolution: For very dense text, increase to --resolution 250

