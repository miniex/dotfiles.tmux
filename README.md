# tmux Configuration

Minimal tmux config in the damin two-color palette (`#98ABCC` blue / `#E890B0` pink). Pairs with [`miniex/dotfiles.kitty`](https://github.com/miniex/dotfiles.kitty), [`miniex/dotfiles.nvim`](https://github.com/miniex/dotfiles.nvim), and [`miniex/fish-theme-damin`](https://github.com/miniex/fish-theme-damin).

## Installation

**One-liner:**
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/miniex/dotfiles.tmux/main/install.sh)"
```

The installer clones to `~/.config/tmux`, backs up any existing config (including the legacy `~/.tmux.conf`), auto-detects your OS, writes `os.conf`, and offers to reload a running tmux server.

**Manual:**
```bash
git clone https://github.com/miniex/dotfiles.tmux.git ~/.config/tmux
sh ~/.config/tmux/install.sh   # picks the OS profile
```

Requires **tmux ≥ 3.3** (for `menu-selected-style` and `copy-mode-current-match-style`). On Linux, install `xclip` (X11) or `wl-clipboard` (Wayland) for the yank bindings.

## Highlights

- **Live window-list gradient** — `bin/refresh-windows.sh` rewrites `window-status-format` on every window create / kill / rename / attach, interpolating between `#98ABCC` and `#E890B0` across the live window count.
- **Dingbat-only glyphs** — `✿` active window + prefix flag, `♡` active window trail, `❥` clock, `✧` / `⋆` sparkle bookends, `⌬` zoom, `✎` copy-mode. Pure dingbats, no Nerd Font required.
- **Prefix indicator** — left `✿` flips blue → pink while `Ctrl-a` is held.
- **Themed widgets** — popup / menu borders, copy-mode match highlight, and `prefix-q` pane numbers all use the same blue/pink palette.
- **OS profiles** — `os/linux.conf` (xclip / wl-copy) and `os/macos.conf` (pbcopy / pbpaste), selected by `install.sh`.
- **Sane defaults** — Ctrl-a prefix, vi mode, mouse, 24-bit color, 50k history, base-index 1, renumber windows, splits inherit cwd.

## Key Bindings

| Key                         | Description                                |
|-----------------------------|--------------------------------------------|
| `prefix r`                  | Reload `tmux.conf`                         |
| `prefix \|` / `prefix -`    | Split horizontal / vertical (inherits cwd) |
| `prefix h/j/k/l`            | Select pane                                |
| `prefix H/J/K/L`            | Resize pane (repeatable)                   |
| `prefix >` / `prefix <`     | Swap window forward / backward             |
| `prefix Enter`              | Enter copy-mode                            |
| `v` / `V` / `C-v`           | Begin / line / block selection             |
| `y`                         | Yank to system clipboard (per OS)          |
| `prefix P`                  | Paste from system clipboard                |

## Contributing

Personal dotfiles — outside contributions are not accepted. Fork instead. Bug reports for the published behavior are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Han Damin.
