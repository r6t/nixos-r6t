{ lib, config, pkgs, ... }:
let
  cfg = config.mine.yubikey-luks-enroll;

  # Build pbkdf2-sha512 at nix-build time, same as nixos/modules/system/boot/luksroot.nix
  pbkdf2-sha512 = pkgs.runCommandCC "pbkdf2-sha512" { buildInputs = [ pkgs.openssl ]; } ''
    mkdir -p "$out/bin"
    cc -O3 -lcrypto ${pkgs.path}/nixos/modules/system/boot/pbkdf2-sha512.c -o "$out/bin/pbkdf2-sha512"
    strip -s "$out/bin/pbkdf2-sha512"
  '';

  enrollScript = pkgs.writeShellApplication {
    name = "enroll-yubikey-luks";
    runtimeInputs = with pkgs; [
      yubikey-personalization
      openssl
      cryptsetup
      coreutils
      gnused
      pbkdf2-sha512
    ];
    text = ''
      set -euo pipefail

      LUKS_DEV="''${1:-}"
      SALT_FILE="''${2:-}"
      YUBIKEY_SLOT="''${3:-2}"
      SALT_LENGTH="''${4:-16}"
      KEY_LENGTH="''${5:-64}"
      ITERATIONS="''${6:-1000000}"

      if [ -z "$LUKS_DEV" ] || [ -z "$SALT_FILE" ]; then
        echo "Usage: enroll-yubikey-luks <luks-device> <salt-file-path> [slot] [salt-length] [key-length] [iterations]"
        echo ""
        echo "  luks-device    LUKS device path (e.g. /dev/disk/by-uuid/...)"
        echo "  salt-file-path Absolute path for salt file (e.g. /boot/yubikey-salt)"
        echo "  slot           YubiKey slot for HMAC-SHA1 (default: 2)"
        echo "  salt-length    Salt length in bytes (default: 16)"
        echo "  key-length     Derived key length in bytes (default: 64)"
        echo "  iterations     PBKDF2 iterations (default: 1000000)"
        exit 1
      fi

      rbtohex() { od -An -vtx1 | tr -d ' \n'; }
      hextorb() { tr '[:lower:]' '[:upper:]' | sed -e 's/\([0-9A-F]\{2\}\)/\\\\\\x\1/gI' | xargs printf; }

      echo "=== YubiKey HMAC-SHA1 LUKS Enrollment ==="
      echo "LUKS device:  $LUKS_DEV"
      echo "Salt file:    $SALT_FILE"
      echo "YubiKey slot: $YUBIKEY_SLOT"
      echo ""

      # Check YubiKey
      echo "Checking for YubiKey..."
      if ! ykinfo -v >/dev/null 2>&1; then
        echo "ERROR: No YubiKey detected. Plug it in and try again."
        exit 1
      fi
      echo "YubiKey found."

      # Check LUKS device exists
      if [ ! -e "$LUKS_DEV" ]; then
        echo "ERROR: LUKS device $LUKS_DEV not found."
        exit 1
      fi

      # Generate salt
      echo "Generating $SALT_LENGTH-byte random salt..."
      SALT="$(dd if=/dev/random bs=1 count="$SALT_LENGTH" 2>/dev/null | rbtohex)"
      echo "Salt: $SALT"

      # Challenge YubiKey
      echo "Challenging YubiKey slot $YUBIKEY_SLOT..."
      CHALLENGE="$(echo -n "$SALT" | openssl dgst -binary -sha512 | rbtohex)"
      RESPONSE="$(ykchalresp "-$YUBIKEY_SLOT" -x "$CHALLENGE" 2>/dev/null)"
      if [ -z "$RESPONSE" ]; then
        echo "ERROR: YubiKey challenge-response failed."
        echo "Is slot $YUBIKEY_SLOT programmed for HMAC-SHA1?"
        echo "Program it with: ykpersonalize -$YUBIKEY_SLOT -ochal-resp -ochal-hmac -oserial-api-visible"
        exit 1
      fi
      echo "Got response."

      # Derive LUKS key (single-factor: empty passphrase via echo)
      echo "Deriving LUKS key via PBKDF2-SHA512 ($ITERATIONS iterations)..."
      K_LUKS="$(echo | pbkdf2-sha512 "$KEY_LENGTH" "$ITERATIONS" "$RESPONSE" | rbtohex)"
      echo "Derived key: ''${#K_LUKS} hex chars"

      # Write salt file
      echo "Writing salt file to $SALT_FILE..."
      SALT_DIR="$(dirname "$SALT_FILE")"
      if [ ! -d "$SALT_DIR" ]; then
        mkdir -p "$SALT_DIR"
      fi
      printf '%s\n%s' "$SALT" "$ITERATIONS" > "$SALT_FILE"
      echo "Salt file written."

      # Verify
      echo "Verifying salt file contents:"
      cat "$SALT_FILE"
      echo ""

      # Write derived key to a temp file for cryptsetup
      KEY_FILE="$(mktemp)"
      trap 'rm -f "$KEY_FILE"' EXIT
      echo -n "$K_LUKS" | hextorb > "$KEY_FILE"

      # Add key to LUKS
      echo ""
      echo "Adding YubiKey-derived key to LUKS volume."
      echo "You will be prompted for your EXISTING LUKS passphrase."
      cryptsetup luksAddKey "$LUKS_DEV" "$KEY_FILE"
      rm -f "$KEY_FILE"

      echo ""
      echo "=== Success ==="
      echo "YubiKey LUKS enrollment complete."
      echo ""
      echo "Key slots:"
      cryptsetup luksDump "$LUKS_DEV" | grep -E "^\s+[0-9]+:" || cryptsetup luksDump "$LUKS_DEV" | grep -i slot
      echo ""
      echo "Next: rebuild NixOS and reboot with YubiKey plugged in."
    '';
  };
in
{
  options = {
    mine.yubikey-luks-enroll.enable =
      lib.mkEnableOption "enable YubiKey HMAC-SHA1 LUKS enrollment tool";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      enrollScript
      pkgs.yubikey-personalization
      pkgs.yubikey-manager
    ];
  };
}
