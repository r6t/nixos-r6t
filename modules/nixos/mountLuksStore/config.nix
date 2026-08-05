{ lib, config, ... }:

let
  cfg = config.mine.mountLuksStore;
in
lib.mkIf (cfg != { }) {
  # 1) Emit /etc/crypttab entries (mkBefore so host configs can append with mkAfter)
  environment.etc."crypttab".text = lib.mkBefore (lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: store: "${name} ${store.device} ${store.keyFile} luks,nofail") cfg
  ));

  # 2) Create each mount point directory
  systemd.tmpfiles.rules = lib.mapAttrsToList (_: store: "d ${store.mountPoint} 0755 root root -") cfg;

  # 3) Declare mounts in fileSystems
  fileSystems = lib.foldl'
    (acc: st: acc // {
      "${st.mountPoint}" = {
        device = "/dev/mapper/${st.name}";
        inherit (st) fsType;
        options = st.fsOptions;
      };
    })
    { }
    (lib.mapAttrsToList
      (name: store: {
        inherit name;
        inherit (store) mountPoint fsType fsOptions;
      })
      cfg);
}
