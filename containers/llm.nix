{
  imports = [
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/ollama/default.nix
    ./docker.nix
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking = {
    hostName = "llm";
    # allow web frontend docker containers running in LXC to hit LXC host ollama
    firewall.extraCommands = '' iptables -A INPUT -i br+ -p tcp --dport 11434 -j ACCEPT '';
  };

  mine = {
    nvidia-cuda.enable = true;
    ollama.enable = true;
  };
}

