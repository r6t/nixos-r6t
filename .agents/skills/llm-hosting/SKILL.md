---
name: llm-hosting
description: Use for llama.cpp, llama-server, local model hosting, ROCm or Vulkan inference, model and KV-cache tuning, Open WebUI, or OpenCode local-provider configuration in this repository.
---

# LLM Hosting

Read the relevant section of `docs/LLM-HOSTING-TUNING.md`; search its headings first instead of loading unrelated sections.

For OpenCode and nixvim integration, also read `docs/NIXVIM.md` and inspect `modules/home/nixvim/default.nix`. For NixOS service behavior, inspect `modules/nixos/llama-cpp/default.nix`.

Preserve measured hardware-specific values unless the task provides new evidence. After edits, run `./format.fish`; never run a Nix build or activation command.
