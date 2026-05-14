# Neovim (nixvim)

Source of truth: `modules/home/nixvim/default.nix`. Uses
[nixvim](https://github.com/nix-community/nixvim) as the framework — plugins
and settings are declared as Nix attrs, no `init.lua` to edit.

## Working with this config

- **Add a plugin**: find the right grouped block in `default.nix` (plugins are
  loosely clustered by domain — git, lsp, ui, completion, etc.). Add
  `<plugin>.enable = true;` and any settings underneath it. Rebuild with `nrs`
  on the workstation. nixvim's option names usually match the upstream plugin
  name with `-` instead of `.` (e.g. `git-conflict-nvim` → `git-conflict`).
- **Remove a plugin**: prefer `.enable = false;` over deleting the line. Intent
  stays visible, easier to revert, and leaves a trail when someone wonders why
  a plugin isn't loading.
- **Per-host vs shared**: nixvim is a home-manager module enabled per host via
  `mine.home.nixvim.enable`. Host-specific tweaks (e.g. enabling
  `opencode-llamacpp` only on mountainball) live in the host's configuration,
  not this module.
- **opencode integration**: provider config and per-model variants are built
  in this same file — search for `opencode-llamacpp` / `opencode-ollama`.
  Enabled per host via `mine.home.nixvim.opencode-llamacpp` (see
  `docs/LLM-HOSTING-TUNING.md` for the surrounding context).

## Licensing pitfalls

Nixpkgs' vim-plugin auto-generator defaults `meta.license = lib.licenses.unfree`
for any plugin whose upstream license can't be detected. This is correct
conservative behavior — not a nixpkgs bug. Most often it means the upstream
repo has no `LICENSE` file at all.

- **Don't work around with `allowUnfreePredicate`**: if upstream has no
  LICENSE file, the code is legally all-rights-reserved by the author.
  Allowlisting it via `allowUnfreePredicate` lets it build but doesn't change
  the legal status. Find a properly-licensed alternative instead.
- **If upstream genuinely has a license** that nixpkgs failed to detect, the
  right fix is a PR to nixpkgs adding
  `meta.license = lib.licenses.<x>;` to the plugin's block in
  `pkgs/applications/editors/vim/plugins/overrides.nix`.

## Currently disabled: `git-conflict.nvim`

Provides inline merge-conflict resolution UI (`co`/`ct`/`cb`/`c0` keybinds to
pick ours/theirs/both/none on a `<<<<<<<` block). Upstream
`akinsho/git-conflict.nvim` has no LICENSE file, so nixpkgs (correctly) marks
it unfree and the build refuses to evaluate it without explicit
`allowUnfreePredicate` allowlisting, which we don't want to do.

What we use today instead:

- `gitsigns.nvim` (MIT) — left-gutter change indicators, hunk staging
- `vim-fugitive` (Vim license) — `:Git mergetool`, `:Gdiffsplit!`, status
- Native `<<<<<<<` / `=======` / `>>>>>>>` markers for direct edits

### TODO: evaluate a replacement

When convenient, try one of these properly-licensed alternatives:

- `diffview-nvim` (GPL-3.0) — `:DiffviewOpen` gives a 3-way merge view; the
  closest UX equivalent to git-conflict.nvim
- `conflict-marker-vim` (MIT) — simpler; the plugin git-conflict.nvim was
  originally inspired by
- `mini.diff` (MIT) — part of the `mini.nvim` family if you want broader
  mini.\* adoption

Process: flip the chosen plugin's `.enable = true;`, `nrs`, test on a real
conflict, decide before committing.

## Removed: `zellij-nvim`

Provided unified `<C-h/j/k/l>` navigation between vim windows and zellij
panes. Upstream `Lilja/zellij.nvim` has no LICENSE file AND the repository
is archived (no longer maintained), so it's not getting a license added
retroactively. Removed from `extraPlugins` in the nixvim block.

Day-to-day impact: vim's built-in `<C-w>h/j/k/l` still moves between vim
windows; zellij's own keybinds still move between zellij panes; you just
have to use the right one for the right boundary instead of a single
unified keystroke.

### TODO: evaluate a replacement

`smart-splits.nvim` (MIT) is the maintained successor that most former
`zellij.nvim` users moved to. It also handles tmux, wezterm, and kitty
seamlessly. Add as `smart-splits.enable = true;` (or via `extraPlugins`)
when convenient.

## Related docs

- `docs/LLM-HOSTING-TUNING.md` — opencode + local llama-server integration
- `docs/THEMING.md` — colorscheme (oxocarbon)
