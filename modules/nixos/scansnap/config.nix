{ pkgs, userConfig, ... }:

{
  hardware.sane = {
    enable = true;
    drivers.scanSnap.enable = true;
  };

  users.users.${userConfig.username} = {
    extraGroups = [ "scanner" "lp" ];
  };

  environment.systemPackages = with pkgs; [
    libtiff
    imagemagick
    ocrmypdf
    (writeScriptBin "scansnap-front" ''
      #!${fish}/bin/fish
      set timestamp (date +"%Y-%m-%d-%H-%M-%S")
      set device_id "epjitsu:libusb:001:082"
      set output_dir "/home/${userConfig.username}/scans"

      mkdir -p $output_dir

      scanimage \
        --device-name $device_id \
        --mode Gray \
        --resolution 200 \
        --batch=scan-%d.png \
      && magick scan-*.png \
        -units PixelsPerInch \
        -density 200 \
        -define pdf:use-trimbox=true \
        scansnap-temp.pdf \
      && ocrmypdf \
        --rotate-pages \
        --deskew \
        --jpeg-quality 40 \
        --jbig2-lossy \
        --remove-vectors \
        --clean-final \
        --image-dpi 200 \
        scansnap-temp.pdf "$output_dir/scansnap-front-$timestamp.pdf" \
      && rm scan-*.png scansnap-temp.pdf
    '')
    (writeScriptBin "scansnap-duplex" ''
      #!${fish}/bin/fish
      set timestamp (date +"%Y-%m-%d-%H-%M-%S")
      set device_id "epjitsu:libusb:001:035"
      set output_dir "/home/${userConfig.username}/scans"

      mkdir -p $output_dir

      scanimage \
        --device-name $device_id \
        --format=png \
        --source "ADF Duplex" \
        --mode Gray \
        --resolution 200 \
        --batch=scan-%d.png \
      && magick scan-*.png \
        -units PixelsPerInch \
        -density 200 \
        -define pdf:use-trimbox=true \
        scansnap-temp.pdf \
      && ocrmypdf \
        --rotate-pages \
        --deskew \
        --jpeg-quality 40 \
        --jbig2-lossy \
        --remove-vectors \
        --clean-final \
        --image-dpi 200 \
        scansnap-temp.pdf "$output_dir/scansnap-duplex-$timestamp.pdf" \
      && rm scan-*.png scansnap-temp.pdf
    '')
  ];

  system.activationScripts.create-scan-dir = ''
    mkdir -p /home/${userConfig.username}/scans
    chown ${userConfig.username} /home/${userConfig.username}/scans
  '';
}
