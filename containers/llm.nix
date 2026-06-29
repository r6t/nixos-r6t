{ pkgs, ... }:

{
  imports = [
    ../modules/nixos/docker/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
    nvidia.acceptLicense = true;
  };

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit = {
    enable = true;
    suppressNvidiaDriverAssertion = true;
  };

  mine.docker.enable = true;

  networking.hostName = "llm";

  environment.etc."trtllm/config.yml".text = ''
    max_batch_size: 8
    max_num_tokens: 4096
    kv_cache_config:
      free_gpu_memory_fraction: 0.75
    cuda_graph_config:
      enable_padding: true
      batch_sizes:
      - 1
      - 2
      - 4
      - 8
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
    "d /var/lib/private/open-webui 0700 root root -"
    "d /var/lib/trtllm 0755 root root -"
    "d /var/cache/private 0700 root root -"
    "d /var/cache/trtllm 0755 root root -"
    "d /var/cache/trtllm/huggingface 0755 root root -"
  ];

  # Crown's Incus NVIDIA runtime mounts versioned driver libraries into
  # /usr/lib64. Docker's NVIDIA runtime and TensorRT-LLM dlopen SONAMEs.
  systemd.services = {
    docker-trtllm = {
      after = [ "network-online.target" "trtllm-cuda-driver-libs.service" ];
      wants = [ "network-online.target" "trtllm-cuda-driver-libs.service" ];
      serviceConfig.ExecStartPre = [
        "+${pkgs.writeShellScript "trtllm-cuda-preflight" ''
          set -eu

          test -e /dev/nvidia0
          test -e /dev/nvidiactl
          test -e /usr/lib64/libcuda.so.1
        ''}"
      ];
    };

    trtllm-cuda-driver-libs = {
      description = "Create NVIDIA driver library SONAME symlinks for TensorRT-LLM CUDA";
      before = [ "docker-trtllm.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu

        link_latest() {
          soname="$1"
          latest=""

          for candidate in /usr/lib64/"$soname".*; do
            if [ -e "$candidate" ] && [ "$candidate" != "/usr/lib64/$soname.1" ]; then
              latest="$candidate"
            fi
          done

          if [ -n "$latest" ]; then
            ln -sfn "$(basename "$latest")" "/usr/lib64/$soname.1"
          fi
        }

        link_latest libcuda.so
        link_latest libnvidia-ml.so
      '';
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.trtllm = {
      image = "nvcr.io/nvidia/tensorrt-llm/release:1.3.0rc19";
      pull = "always";
      cmd = [
        "trtllm-serve"
        "serve"
        "Qwen/Qwen3.6-30B-A3B"
        "--served_model_name"
        "Qwen/Qwen3.6-30B-A3B"
        "--host"
        "0.0.0.0"
        "--port"
        "8080"
        "--max_seq_len"
        "32768"
        "--config"
        "/etc/trtllm/config.yml"
      ];
      environment = {
        CUDA_MODULE_LOADING = "LAZY";
        HF_HOME = "/root/.cache/huggingface";
      };
      volumes = [
        "/etc/trtllm/config.yml:/etc/trtllm/config.yml:ro"
        "/var/cache/trtllm/huggingface:/root/.cache/huggingface"
        "/var/lib/trtllm:/workspace/trtllm"
      ];
      networks = [ "host" ];
      extraOptions = [
        "--gpus=all"
        "--ipc=host"
        "--shm-size=1g"
        "--ulimit=memlock=-1"
        "--ulimit=stack=67108864"
      ];
    };
  };

  mine = {
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrls = [
        "http://localhost:8080/v1"
        "https://openrouter.ai/api/v1"
      ];
      environmentFile = "/etc/oi.env";
    };
  };
}
