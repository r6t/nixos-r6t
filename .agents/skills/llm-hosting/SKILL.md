---
name: llm-hosting
description: Use for llama.cpp, llama-server, local model hosting, ROCm or Vulkan inference, model and KV-cache tuning, Open WebUI, or OpenCode local-provider configuration in this repository.
---

# LLM Hosting

If a private checkout provides LLM hosting notes, read the relevant section;
search headings first instead of loading unrelated sections.

For OpenCode and nixvim integration, also read `docs/NIXVIM.md` and inspect `modules/home/nixvim/default.nix`. Host-specific llama.cpp service tuning is private; inspect the private module if present.

Preserve measured hardware-specific values unless the task provides new evidence. After edits, run `./format.fish`; never run a Nix build or activation command.
