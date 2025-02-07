{ lib, config, pkgs, userConfig, ... }: {

  options.mine.scansnap.enable = lib.mkEnableOption "enable scansnap s1300i support";

  config = lib.mkIf config.mine.scansnap.enable {
    hardware.sane = {
      enable = true;
      drivers.scanSnap.enable = true;
    };

    users.users.${userConfig.username}.extraGroups = [ "scanner" "lp" ];

    environment.systemPackages = with pkgs; let
      mkScanScript = { scanType ? "duplex" }: writeScriptBin "scansnap-${scanType}" ''
                #!${fish}/bin/fish
                set scan_type "${scanType}"
                set timestamp (date +"%Y-%m-%d-%H-%M-%S")
                set device_id "epjitsu:libusb:001:009"
                set output_dir "/home/${userConfig.username}/scans"

                mkdir -p $output_dir

                if not contains $scan_type front duplex
                  echo "Invalid scan type: $scan_type. Use 'front' or 'duplex'"
                  exit 1
                end
        
        	# Run document scanner, crop, optimize and OCR
                scanimage \
                  --device-name $device_id \
                  --format=png \
                  --source "ADF "(string upper $scan_type) \
                  --mode Color \
                  --resolution 300 \
                  --batch=scan-%d.png \
                && magick scan-*.png \
                  -fuzz 15% \
                  -trim +repage \
                  -shave 2x2 \
                  -blur 0x0.5 \
                  -sharpen 0x1 \
                  -background white \
                  -flatten \
                  -define pdf:use-trimbox=true \
                  -units PixelsPerInch \
                  -density 300 \
                  scansnap-temp.pdf \
                && ocrmypdf \
                  --rotate-pages \
                  --deskew \
                  --clean-final \
                  --optimize 3 \
                  --image-dpi 300 \
                  scansnap-temp.pdf "$output_dir/scansnap-$scan_type-$timestamp.pdf" \
                && rm scan-*.png scansnap-temp.pdf
      '';
    in
    [
      imagemagick
      ocrmypdf
      (mkScanScript { scanType = "front"; })
      (mkScanScript { scanType = "duplex"; })
    ];

    system.activationScripts.create-scan-dir = ''
      mkdir -p /home/${userConfig.username}/scans
      chown ${userConfig.username} /home/${userConfig.username}/scans
    '';
  };
}

