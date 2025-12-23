{
  imports = [
    ../modules/nixos/n8n/default.nix
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/ollama/default.nix
    ../modules/nixos/open-webui/default.nix
    ./docker.nix
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking = {
    hostName = "llm";
    # allow web frontend docker containers running in LXC to hit LXC host ollama
    firewall.extraCommands = '' iptables -A INPUT -i br+ -p tcp --dport 11434 -j ACCEPT '';
  };

  # avoid onnxruntime + nix build env issues
  nixpkgs.overlays = [
    (_final: prev: {
      python313Packages = prev.python313Packages.overrideScope (_pyFinal: pyPrev: {
        rapidocr-onnxruntime = pyPrev.rapidocr-onnxruntime.overrideAttrs (_old: {
          doCheck = false;
          checkPhase = ":";
          installCheckPhase = ":";
          pythonImportsCheck = [ ];
          nativeCheckInputs = [ ];
          checkInputs = [ ];
          pytestFlagsArray = [ ];
          disabledTests = [ ];
          disabledTestPaths = [ ];
        });
      });
      python3Packages = prev.python3Packages.overrideScope (_pyFinal: pyPrev: {
        rapidocr-onnxruntime = pyPrev.rapidocr-onnxruntime.overrideAttrs (_old: {
          doCheck = false;
          checkPhase = ":";
          installCheckPhase = ":";
          pythonImportsCheck = [ ];
          nativeCheckInputs = [ ];
          checkInputs = [ ];
          pytestFlagsArray = [ ];
          disabledTests = [ ];
          disabledTestPaths = [ ];
        });
      });
    })
  ];

  # Precreate private state dirs (root-owned. systemd will manage perms for DynamicUser)
  # These appear in the rootfs so Incus can bind-mount to them before systemd starts.
  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
    "d /var/lib/private/open-webui 0700 root root -"
    "d /var/lib/private/n8n 0700 root root -"
  ];

  mine = {
    n8n.enable = false;
    nvidia-cuda = {
      enable = true;
      package = "production";
      openDriver = true;
      installCudaToolkit = false;
    };
    ollama.enable = true;
    open-webui.enable = false;
  };
}

