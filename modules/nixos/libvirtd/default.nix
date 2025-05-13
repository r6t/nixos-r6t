{ lib, config, pkgs, ... }:
let
  cfg = config.mine.libvirtd;
in
{
  options.mine.libvirtd = {
    enable = lib.mkEnableOption "QEMU/KVM virtualization";
    enableDesktop = lib.mkEnableOption "graphical VM features";
    cpuVendor = lib.mkOption {
      type = lib.types.enum [ "intel" "amd" ];
      default = "intel";
      description = "CPU vendor for IOMMU configuration";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };

      virtualisation.libvirtd = {
        enable = true;
        onBoot = "ignore";
        onShutdown = "shutdown";
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          ovmf.enable = true;
          verbatimConfig = ''
            namespaces = []
            user = "root"
          '';
        };
      };

      boot = {
        kernelParams = [
          (if cfg.cpuVendor == "intel"
          then "intel_iommu=on"
          else "amd_iommu=on")
        ];
        kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ]
          ++ (if cfg.cpuVendor == "intel"
        then [ "kvm-intel" ]
        else [ "kvm-amd" ]);
      };

      users.users.r6t.extraGroups = [ "libvirtd" "kvm" ];
    })

    (lib.mkIf (cfg.enable && cfg.enableDesktop) {
      # Allow bridge NAT + passthrough to host's Tailscale exit node
      networking.firewall = {
        checkReversePath = "loose";
        trustedInterfaces = [ "virbr0" ];
        extraCommands = ''
          iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -j MASQUERADE

          iptables -I FORWARD -i virbr0 -j ACCEPT
          iptables -I FORWARD -o virbr0 -j ACCEPT
        '';
      };
      virtualisation.libvirtd.qemu = {
        verbatimConfig = ''
          vga = "virtio"
          spice_port = 5900
          spice_addr = "127.0.0.1"
          spice_tls = 0
        '';
        vhostUserPackages = [ pkgs.virtiofsd ];
      };

      environment.systemPackages = with pkgs; [
        virt-manager
        spice-gtk
        virtiofsd
      ];

      services.spice-vdagentd.enable = true;
      programs.dconf.enable = true; # Required for virt-manager GUI
    })
  ];
}
