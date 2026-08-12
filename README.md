# tmux Configuration

Minimal tmux config in the damin palette (`#98ABCC` blue / `#E890B0` pink). Ships 5 themes you can switch without leaving tmux.

## Installation

**One-liner:**

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/miniex/dotfiles.tmux/main/install.sh)"
```

It clones to `~/.config/tmux`, asks for an OS profile and a theme, writes `os.conf` and `theme.conf`, installs a modern `tmux-256color` terminfo entry if the system one is too old for bracketed paste, then offers to reload a running server. Re-run it any time: an existing clone gets `git pull`, and both questions default to your current answers. A config that isn't this repo is moved to `~/.config/tmux.backup.<timestamp>`, and a legacy `~/.tmux.conf` is handled the same way.

**Manual:**

```bash
git clone https://github.com/miniex/dotfiles.tmux.git ~/.config/tmux
sh ~/.config/tmux/install.sh   # OS profile + theme
```

Needs **tmux 3.3 or newer**, for `menu-selected-style` and `copy-mode-current-match-style`. On Linux install `xclip` (X11) or `wl-clipboard` (Wayland) for the yank bindings. On macOS install Homebrew's ncurses (`brew install ncurses`) so the installer has a modern `tmux-256color` to copy from; without it that step is skipped with a warning.

## Highlights

- **Five themes.** Switched live with `prefix T`. The pick lands in `theme.conf` and is reused on the next start.
- **One-key update.** `prefix U` pulls and reloads, keeping your OS profile and theme.
- **Window-list gradient.** Rebuilt across the live window count on every window create, kill, rename and attach. Both ends come from the active theme.
- **Dingbats, not Nerd Font icons.** Any font with basic Unicode coverage works. `damin-geek` is plain ASCII instead.
- **Prefix indicator.** The leftmost glyph changes color while the prefix key is held.
- **Themed widgets.** Popup and menu borders, copy-mode matches and `prefix q` pane numbers all follow the active theme.
- **OS profiles.** `os/linux.conf` (xclip / wl-copy) and `os/macos.conf` (pbcopy / pbpaste).
- **Bracketed-paste fix.** Where the system `tmux-256color` predates bracketed paste, mostly on macOS, the installer drops a modern entry into `~/.terminfo` so pastes stop leaking `[200~` markers into vim, psql and friends.
- **Sane defaults.** Ctrl-a prefix, vi mode, mouse, 24-bit color, 50k history, base-index 1, renumbered windows, splits that inherit cwd.

## Key Bindings

Prefix is **`Ctrl-a`**, rebound from the default `Ctrl-b`. `prefix r` means press `Ctrl-a`, release, then `r`.

| Key                      | Description                                |
| ------------------------ | ------------------------------------------ |
| `prefix r`               | Reload `tmux.conf`                         |
| `prefix T`               | Pick a theme, applied live                 |
| `prefix U`               | Update and reload, in a popup              |
| `prefix \|` / `prefix -` | Split horizontal / vertical (inherits cwd) |
| `prefix h/j/k/l`         | Select pane                                |
| `prefix H/J/K/L`         | Resize pane (repeatable)                   |
| `prefix >` / `prefix <`  | Swap window forward / backward             |
| `prefix Enter`           | Enter copy-mode                            |
| `v` / `V` / `C-v`        | Begin / line / block selection             |
| `y`                      | Yank to system clipboard (per OS)          |
| `prefix P`               | Paste from system clipboard                |

## Themes

| Theme               | Colors                                 | Notes                                                    |
| ------------------- | -------------------------------------- | -------------------------------------------------------- |
| `damin` _(default)_ | `#98ABCC` borders, `#E890B0` highlight | Same palette as btop-theme-damin and dotfiles.kitty.     |
| `damin-blue`        | `#6F7E96` to `#D4E0EF`, six steps      | No pink. Blue only, brightness carries the emphasis.     |
| `damin-light`       | `#4A6FA5` / `#C25E86`                  | Darkened for light terminal backgrounds.                 |
| `damin-mono`        | `#9a9a9a` / `#e0e0e0`                  | Greyscale. Emphasis comes from brightness.               |
| `damin-geek`        | `#008F11` / `#00FF41`                  | Phosphor green, ASCII glyphs only, square popup borders. |

**Switching:**

```bash
prefix T                                       # picker, inside tmux

sh ~/.config/tmux/bin/theme.sh list
sh ~/.config/tmux/bin/theme.sh set damin-geek
sh ~/.config/tmux/install.sh                   # asks again, current theme as default
```

The pick lands in `theme.conf`, a generated one-line file that `tmux.conf` sources on start and on reload. Same trick as `os.conf`. Both are gitignored, so updates leave them alone.

**Writing your own:** copy a file out of `themes/`, save it as `themes/mine.local.conf`, and it shows up in the picker (`*.local.conf` is gitignored). A switch re-sources one file and nothing else, so every theme has to set the same option list, or values from the previous theme stay behind. On top of the tmux options, each theme sets:

| Option                                 | Purpose                                                         |
| -------------------------------------- | --------------------------------------------------------------- |
| `@theme_name`                          | Name shown in the picker.                                       |
| `@theme_grad_start`, `@theme_grad_end` | `#RRGGBB` ends of the window-list gradient.                     |
| `@theme_win_format`                    | Window-list template. `@C` is replaced with the gradient color. |
| `@theme_win_current_format`            | Same, for the active window.                                    |

## Updating

`prefix U` opens a popup running `bin/update.sh`: `git pull --ff-only`, restore the executable bits, re-source `tmux.conf`. `os.conf` and `theme.conf` are untracked, so the OS profile and the theme carry over. If the theme you picked is gone from the repo, it falls back to `damin` instead of leaving a half-styled bar.

```bash
sh ~/.config/tmux/bin/update.sh
```

`install.sh` updates as well, and asks the two questions again.

## Companion repos

- [btop-theme-damin](https://github.com/miniex/btop-theme-damin) - btop theme
- [fish-theme-damin](https://github.com/miniex/fish-theme-damin) - fish prompt
- [dotfiles.kitty](https://github.com/miniex/dotfiles.kitty) - kitty terminal config
- [dotfiles.nvim](https://github.com/miniex/dotfiles.nvim) - Neovim config

## Contributing

Personal dotfiles, so outside contributions are not accepted. Fork instead. Bug reports for the published behavior are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © 2026 Han Damin.
