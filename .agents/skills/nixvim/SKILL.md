---
name: nixvim
description: Use for Neovim, nixvim, editor plugins, keymaps, LSP, completion, themes inside Neovim, or OpenCode's Neovim integration in this repository.
---

# Nixvim

Read `docs/NIXVIM.md` before making changes.

Treat `modules/home/nixvim/default.nix` as the source of truth. Use nixvim's Nix options and the existing grouped configuration rather than creating an `init.lua`.

Keep host-specific settings in the host configuration. After edits, run `./format.fish`; never run a Nix build or activation command.
