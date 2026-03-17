# Theming

This flake uses the [oxocarbon](https://github.com/nyoom-engineering/oxocarbon.nvim) colorscheme
throughout the terminal environment. The goal is visual coherence across all tools with a single
palette, and to centralize theme definitions as better mechanisms emerge.

## Palette reference

Oxocarbon dark palette used across all tools:

| Name       | Hex       | Role                          |
| ---------- | --------- | ----------------------------- |
| base00     | `#161616` | Terminal / editor background  |
| base01     | `#262626` | Subtle backgrounds, panels    |
| base02     | `#393939` | Selection, hover, borders     |
| base03     | `#525252` | Comments, muted text          |
| base04     | `#dde1e6` | Secondary foreground          |
| base05     | `#f2f4f8` | Primary foreground            |
| teal       | `#08bdba` | Primary accent, active states |
| cyan       | `#3ddbd9` | Secondary accent              |
| blue       | `#78a9ff` | Keywords, links, primary slot |
| pink       | `#ee5396` | Errors                        |
| lightpink  | `#ff7eb6` | Warnings, emphases            |
| green      | `#42be65` | Success, added diffs          |
| violet     | `#be95ff` | Types, info, non-normal modes |
| lightblue  | `#82cfff` | Numbers, subtle accents       |
| darkviolet | `#1c1a26` | UI bar background tint        |

## Where theming is applied

### Neovim — `modules/home/nixvim/default.nix`

Uses `colorschemes.oxocarbon.enable = true` via the `oxocarbon-nvim` vimPlugin. This is the
canonical source of the palette — all other tool themes are derived from it.

### Zellij — `modules/home/zellij/default.nix`

Uses zellij's semantic UI component theme format (not the legacy terminal-color format). The theme
is injected as a raw KDL string via `programs.zellij.extraConfig`. Key design decisions:

- Bar background: `#1c1a26` (dark violet tint) — distinct from terminal black without being loud
- Active tab / NORMAL mode: teal ribbon
- Inactive tabs / other modes: `#393939` ribbon on the violet bar
- Mode indicator colors (from `text_unselected.emphasis_*` in `line.rs`):
  - `emphasis_2` = NORMAL → green
  - `emphasis_3` = LOCKED → pink
  - `emphasis_0` = all other modes (TAB, PANE, RESIZE, etc.) → violet

### OpenCode — `modules/home/nixvim/default.nix`

The opencode TUI theme is written to `~/.config/opencode/themes/oxocarbon.json` via `home.file` in
the nixvim module (co-located there because opencode is a nixvim package dependency). The
`tui.json` is also managed to point to the oxocarbon theme.

The opencode agent color cycle is `[secondary, accent, success, warning, primary, error, info]`:

| Agent | Slot        | Color           |
| ----- | ----------- | --------------- |
| build | `secondary` | `#42be65` green |
| plan  | `accent`    | `#08bdba` teal  |

### KDE Plasma — `modules/home/kde-apps/default.nix`

Uses a custom `Oxocarbon.colors` KDE color scheme deployed to
`~/.local/share/color-schemes/Oxocarbon.colors` via `home.file`. plasma-manager references it as
`colorScheme = "Oxocarbon"` and applies it at login.

Key design decisions:

- `Colors:View` background: `base00` (`#161616`) — terminal black for content areas (file lists,
  text editors)
- `Colors:Window` / `Colors:Button` background: `base01`/`base02` — panel chrome
- `Colors:Header` / `Colors:Complementary` background: `base01` — neutral dark for the taskbar,
  avoiding the purple tint that would bleed into the panel
- `Colors:Selection` background: teal (`#08bdba`) with `base00` foreground — dark text on teal
- `WM` active title bar: `darkviolet` (`#1c1a26`) — subtle tint matching the zellij bar
- `WM` inactive title bar: `base00` — recedes completely
- `AccentColor`: lightblue `#82cfff` — muted, distinctive, not pink-reading on large surfaces.
  Teal (`#08bdba`) was tried but too vivid at Plasma accent scale.

#### Kate color scheme

Kate currently uses `colorScheme = "Breeze Dark"`. A future improvement would be a custom Kate
syntax highlighting scheme (`.theme` JSON file in
`~/.local/share/org.kde.syntax-highlighting/themes/`) mapped from the oxocarbon palette, deployed
via `home.file` and referenced as:

```nix
programs.kate.ui.colorScheme = "Oxocarbon";  # must match "name" in the JSON theme file
```

## Current limitations and future direction

Theme colors are currently duplicated across several places:

1. **Zellij** — RGB triplets hardcoded in the KDL string in `modules/home/zellij/default.nix`
2. **OpenCode** — hex strings in the JSON theme written by `home.file` in `modules/home/nixvim/default.nix`
3. **KDE Plasma** — hex/RGB values in `modules/home/kde-apps/Oxocarbon.colors`
4. **Neovim** — delegated to the `oxocarbon-nvim` plugin (no manual color definitions needed)

The ideal end state is a single Nix attribute set defining the palette once, with each tool's
theme generated from it. This would make palette updates a one-line change. Candidate approaches:

- A shared `palette.nix` in `modules/home/` that exports the color map, imported by zellij,
  nixvim, and kde-apps modules
- Using home-manager's module system to pass palette attrs between modules
- KDE `.colors` and Kate `.theme` files generated from the same `palette.nix`

Until then, when updating the palette, change colors in this order:

1. Update this doc
2. Update `oxocarbonTheme` KDL in `modules/home/zellij/default.nix` (RGB triplets)
3. Update `opencodeThemeConfig` in `modules/home/nixvim/default.nix` (opencode JSON hex strings)
4. Update `modules/home/kde-apps/Oxocarbon.colors` (RGB triplets)
5. Update `AccentColor` in `modules/home/kde-apps/default.nix` if the accent slot changes
6. Neovim updates itself via the plugin
