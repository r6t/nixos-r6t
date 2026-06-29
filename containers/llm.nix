{ lib, pkgs, ... }:

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
    max_batch_size: 1
    max_num_tokens: 1024
    kv_cache_config:
      free_gpu_memory_fraction: 0.4
    cuda_graph_config:
      enable_padding: false
      batch_sizes:
      - 1
  '';

  environment.etc."trtllm/qwen3-nonthinking.jinja".text = ''
    {%- set enable_thinking = false if enable_thinking is not defined else enable_thinking %}
    {%- if tools %}
        {{- '<|im_start|>system\n' }}
        {%- if messages[0].role == 'system' %}
            {{- messages[0].content + '\n\n' }}
        {%- endif %}
        {{- "# Tools\n\nYou may call one or more functions to assist with the user query.\n\nYou are provided with function signatures within <tools></tools> XML tags:\n<tools>" }}
        {%- for tool in tools %}
            {{- "\n" }}
            {{- tool | tojson }}
        {%- endfor %}
        {{- "\n</tools>\n\nFor each function call, return a json object with function name and arguments within <tool_call></tool_call> XML tags:\n<tool_call>\n{\"name\": <function-name>, \"arguments\": <args-json-object>}\n</tool_call><|im_end|>\n" }}
    {%- else %}
        {%- if messages[0].role == 'system' %}
            {{- '<|im_start|>system\n' + messages[0].content + '<|im_end|>\n' }}
        {%- endif %}
    {%- endif %}
    {%- set ns = namespace(multi_step_tool=true, last_query_index=messages|length - 1) %}
    {%- for message in messages[::-1] %}
        {%- set index = (messages|length - 1) - loop.index0 %}
        {%- if ns.multi_step_tool and message.role == "user" and message.content is string and not(message.content.startswith('<tool_response>') and message.content.endswith('</tool_response>')) %}
            {%- set ns.multi_step_tool = false %}
            {%- set ns.last_query_index = index %}
        {%- endif %}
    {%- endfor %}
    {%- for message in messages %}
        {%- if message.content is string %}
            {%- set content = message.content %}
        {%- else %}
            {%- set content = "" %}
        {%- endif %}
        {%- if (message.role == "user") or (message.role == "system" and not loop.first) %}
            {{- '<|im_start|>' + message.role + '\n' + content + '<|im_end|>' + '\n' }}
        {%- elif message.role == "assistant" %}
            {%- set reasoning_content = "" %}
            {%- if message.reasoning_content is string %}
                {%- set reasoning_content = message.reasoning_content %}
            {%- else %}
                {%- if '</think>' in content %}
                    {%- set reasoning_content = content.split('</think>')[0].rstrip('\n').split('<think>')[-1].lstrip('\n') %}
                    {%- set content = content.split('</think>')[-1].lstrip('\n') %}
                {%- endif %}
            {%- endif %}
            {%- if loop.index0 > ns.last_query_index %}
                {%- if loop.last or (not loop.last and reasoning_content) %}
                    {{- '<|im_start|>' + message.role + '\n<think>\n' + reasoning_content.strip('\n') + '\n</think>\n\n' + content.lstrip('\n') }}
                {%- else %}
                    {{- '<|im_start|>' + message.role + '\n' + content }}
                {%- endif %}
            {%- else %}
                {{- '<|im_start|>' + message.role + '\n' + content }}
            {%- endif %}
            {%- if message.tool_calls %}
                {%- for tool_call in message.tool_calls %}
                    {%- if (loop.first and content) or (not loop.first) %}
                        {{- '\n' }}
                    {%- endif %}
                    {%- if tool_call.function %}
                        {%- set tool_call = tool_call.function %}
                    {%- endif %}
                    {{- '<tool_call>\n{"name": "' }}
                    {{- tool_call.name }}
                    {{- '", "arguments": ' }}
                    {%- if tool_call.arguments is string %}
                        {{- tool_call.arguments }}
                    {%- else %}
                        {{- tool_call.arguments | tojson }}
                    {%- endif %}
                    {{- '}\n</tool_call>' }}
                {%- endfor %}
            {%- endif %}
            {{- '<|im_end|>\n' }}
        {%- elif message.role == "tool" %}
            {%- if loop.first or (messages[loop.index0 - 1].role != "tool") %}
                {{- '<|im_start|>user' }}
            {%- endif %}
            {{- '\n<tool_response>\n' }}
            {{- content }}
            {{- '\n</tool_response>' }}
            {%- if loop.last or (messages[loop.index0 + 1].role != "tool") %}
                {{- '<|im_end|>\n' }}
            {%- endif %}
        {%- endif %}
    {%- endfor %}
    {%- if add_generation_prompt %}
        {{- '<|im_start|>assistant\n' }}
        {%- if enable_thinking is defined and enable_thinking is false %}
            {{- '<think>\n\n</think>\n\n' }}
        {%- endif %}
    {%- endif %}
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
      serviceConfig = {
        Restart = lib.mkForce "no";
        ExecStartPre = [
          "+${pkgs.writeShellScript "trtllm-cuda-preflight" ''
            set -eu

            test -e /dev/nvidia0
            test -e /dev/nvidiactl
            test -e /usr/lib64/libcuda.so.1
          ''}"
        ];
      };
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
        "nvidia/Qwen3-8B-FP8"
        "--served_model_name"
        "nvidia/Qwen3-8B-FP8"
        "--host"
        "0.0.0.0"
        "--port"
        "8080"
        "--max_seq_len"
        "8192"
        "--config"
        "/etc/trtllm/config.yml"
        "--chat_template"
        "/etc/trtllm/qwen3-nonthinking.jinja"
      ];
      environment = {
        CUDA_MODULE_LOADING = "LAZY";
        HF_HOME = "/root/.cache/huggingface";
      };
      volumes = [
        "/etc/trtllm/config.yml:/etc/trtllm/config.yml:ro"
        "/etc/trtllm/qwen3-nonthinking.jinja:/etc/trtllm/qwen3-nonthinking.jinja:ro"
        "/var/cache/trtllm/huggingface:/root/.cache/huggingface"
        "/var/lib/trtllm:/workspace/trtllm"
      ];
      networks = [ "host" ];
      extraOptions = [
        # Explicit NVIDIA CDI avoids Docker probing unavailable AMD CDI specs.
        "--device=nvidia.com/gpu=all"
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
