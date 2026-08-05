# Neovim (nixvim)

`modules/home/nixvim/default.nix` is the source of truth. Options live in
`modules/home/nixvim/options.nix`. The config uses nixvim Nix options plus small
Lua snippets in `extraConfigLua`; there is no separate `init.lua`.

## Contract

- Enable with `mine.home.nixvim.enable`.
- Keep shared editor behavior in `modules/home/nixvim/default.nix`.
- Keep host-specific model endpoints, secrets, and OpenCode options in host
  configs under `mine.home.nixvim.*`.
- Preserve standalone Home Manager compatibility. The module receives
  `isNixOS`; SOPS-backed secrets are NixOS-only.
- Use nixvim plugin options when available. Use `extraPlugins` only when nixvim
  does not expose a plugin yet or a local plugin needs custom handling.

## Main Options

- `mine.home.nixvim.enableSopsSecrets`: provisions editor/AI secrets on NixOS and
  loads them into fish session env.
- `mine.home.nixvim.enableHaMcp`: adds the Home Assistant MCP server to generated
  OpenCode config.
- `mine.home.nixvim.opencode-llamacpp.enable`: writes an OpenAI-compatible
  OpenCode provider for llama-server.
- `mine.home.nixvim.opencode-llamacpp.baseURL`: llama-server `/v1` endpoint.
- `mine.home.nixvim.opencode-llamacpp.models`: model aliases, picker names,
  optional limits, and per-model variants.

Model keys must match the server-reported alias or model id. Variant attrs are
sent in the OpenCode request body; use them for per-request llama-server options
such as Qwen thinking mode.

## Current Shape

- Theme: oxocarbon for Neovim and generated OpenCode TUI config.
- Packages: formatters, linters, media preview tools, `opencode`, and
  `tree-sitter`.
- Extra plugins: `direnv-vim`, `opencode-nvim`, `oxocarbon-nvim`, `snacks-nvim`,
  and `nvim-lspconfig`.
- Keymaps include zellij-aware `<C-h/j/k/l>` navigation, OpenCode actions,
  diagnostics, LSP, telescope/snacks, and editing helpers.
- Treesitter grammar packages are taken from the configured treesitter package to
  avoid mixed-package warnings.

## Editing Rules

- Add plugins in the existing grouped blocks in `default.nix`.
- Prefer explicit `.enable = false;` for intentionally disabled plugins.
- Do not allowlist unlicensed plugins with `allowUnfreePredicate`.
- If a plugin has a real upstream license but nixpkgs misses it, fix nixpkgs'
  generated plugin metadata instead.
- Run `./format.fish` after changes. Do not run builds or activations as an
  agent.

## Disabled Plugins

- `git-conflict.nvim`: disabled because upstream has no `LICENSE`; nixpkgs marks
  it unfree. Current replacements are `gitsigns.nvim`, `vim-fugitive`, and manual
  conflict-marker edits. Properly licensed candidates: `diffview-nvim`,
  `conflict-marker-vim`, or `mini.diff`.
- `zellij-nvim`: removed because upstream has no `LICENSE` and is archived. If a
  unified pane-navigation plugin is wanted later, prefer `smart-splits.nvim`.

## Related Docs

- Private LLM hosting notes: OpenCode and llama-server model context.
- `docs/THEMING.md`: shared palette and oxocarbon styling.
