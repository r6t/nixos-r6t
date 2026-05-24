{ lib, config, pkgs, ... }: {

  options = {
    mine.bluetooth.enable =
      lib.mkEnableOption "enable my usual bluetooth config";
  };

  config = lib.mkIf config.mine.bluetooth.enable {
    # blueman disabled as long as hyprland isn't in use
    services.blueman.enable = false;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          # adding the 3 below trying to get bluetooth to start enabled
          Enable = "Source,Sink,Media,Socket";
          FastConnectable = "true";
          MultiProfile = "multiple";
          # Experimental settings allow the os to read bluetooth device battery level
          Experimental = true;
        };
      };
    };

    # MediaTek MT7925/MT7922/MT7921K BT regression workaround.
    #
    # Kernel commit 634a4408c061 ("Bluetooth: btmtk: validate WMT event SKB length
    # before struct access", May 6 2026) added a bounds check to btmtk_usb_hci_wmt_sync()
    # that is too strict — real MT79xx firmware sends a WMT FUNC_CTRL event that's
    # missing the trailing status field, and the new check returns -EINVAL, leaving
    # hci0 stuck at "HW/SW Version: 0x00000000, Failed to send wmt func ctrl (-22)".
    #
    # Cc: stable so the regression hit kernel 7.0.7 and 6.19.12 simultaneously.
    # Affects MT7925 (goldenball, GZ302EA Strix Halo) and MT7925 (mountainball, FW13 AMD).
    #
    # Fix: upstream commit e3ac0d9f1a (May 14 2026) treats short response as
    # BTMTK_WMT_ON_UNDONE, restoring pre-regression behaviour. 4-line patch in
    # drivers/bluetooth/btmtk.c. Cherry-pick onto any kernel with the bad commit.
    #
    # nixpkgs's 7.0.8 (build date May 15 2026) was cut from stable-7.0.y before
    # the fix backported, so 7.0.8 here STILL has the regression even though Fedora's
    # 7.0.8 includes it. Always apply the patch; it will fail to apply (loud build
    # error) once nixpkgs advances to a kernel that includes the fix, at which point
    # delete this block.
    #
    # References:
    #   - bad commit: torvalds/linux@634a4408c061
    #   - fix:        torvalds/linux@e3ac0d9f1a205f33a43fba3b79ef74d2f604c78b
    #   - NixOS:      https://github.com/NixOS/nixpkgs/issues/521528
    #   - Fedora:     https://discussion.fedoraproject.org/t/191420
    boot.kernelPatches = [
      {
        name = "btmtk-accept-short-wmt-funcc";
        patch = pkgs.fetchpatch {
          url = "https://github.com/torvalds/linux/commit/e3ac0d9f1a205f33a43fba3b79ef74d2f604c78b.patch";
          hash = "sha256-ByGMwBkEDv0yf9DfJjwILzmPBJBTcb0art8/lscbwUI=";
        };
      }
    ];
  };
}
