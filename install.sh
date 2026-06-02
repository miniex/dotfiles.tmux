#!/bin/sh
# Bootstrap installer for miniex/dotfiles.tmux.
# Run: sh -c "$(curl -fsSL https://raw.githubusercontent.com/miniex/dotfiles.tmux/main/install.sh)"
# Or: sh install.sh   (in-place from a clone)
set -eu

REPO_URL="https://github.com/miniex/dotfiles.tmux.git"
TMUX_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/tmux"
LEGACY_TMUX_CONF="$HOME/.tmux.conf"

if [ -t 1 ]; then
    RESET=$(printf '\033[0m')
    BOLD=$(printf '\033[1m')
    DIM=$(printf '\033[2m')
    SKY=$(printf '\033[38;2;135;206;235m')
    PINK=$(printf '\033[38;2;255;182;193m')
    SKY2=$(printf '\033[38;2;165;200;225m')
    PINK2=$(printf '\033[38;2;225;188;204m')
    YELLOW=$(printf '\033[33m')
    RED=$(printf '\033[31m')
else
    RESET=''
    BOLD=''
    DIM=''
    SKY=''
    PINK=''
    SKY2=''
    PINK2=''
    YELLOW=''
    RED=''
fi

banner() {
    printf '\n'
    printf '   %s%s╭──────────────────────────────────────────────╮%s\n' "$SKY" "$BOLD" "$RESET"
    printf '   %s%s│  %sminiex/dotfiles.tmux%s%s%s                        %s%s│%s\n' \
        "$SKY" "$BOLD" "$PINK" "$RESET" "$SKY" "$BOLD" "$SKY" "$BOLD" "$RESET"
    printf '   %s%s│  %stmux configuration installer%s%s%s                %s%s│%s\n' \
        "$SKY2" "$BOLD" "$PINK2" "$RESET" "$SKY2" "$BOLD" "$SKY2" "$BOLD" "$RESET"
    printf '   %s%s╰──────────────────────────────────────────────╯%s\n' "$PINK" "$BOLD" "$RESET"
    printf '\n'
}

step() { printf '\n%s%s▸ %s%s\n' "$BOLD" "$SKY" "$1" "$RESET"; }
info() { printf '  %sℹ%s  %s\n' "$SKY" "$RESET" "$1"; }
ok() { printf '  %s✓%s  %s\n' "$PINK" "$RESET" "$1"; }
warn() { printf '  %s⚠%s  %s\n' "$YELLOW" "$RESET" "$1"; }
err() { printf '  %s✗%s  %s\n' "$RED" "$RESET" "$1" >&2; }

# /dev/tty so prompts survive `curl | sh`.
read_answer() {
    answer=''
    if { read -r answer </dev/tty; } 2>/dev/null; then
        return 0
    fi
    if read -r answer 2>/dev/null; then
        return 0
    fi
    answer=''
    return 0
}

prompt_yes() {
    printf '  %s?%s  %s %s[y/N]%s ' "$PINK" "$RESET" "$1" "$DIM" "$RESET"
    read_answer
    case "$answer" in
        [yY] | [yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# $1=question, $2=default (linux|macos) → echoes chosen value
prompt_choice() {
    default=$2
    printf '  %s?%s  %s %s[linux/macos, default: %s]%s ' \
        "$PINK" "$RESET" "$1" "$DIM" "$default" "$RESET" >&2
    read_answer
    case "$answer" in
        l | L | linux | Linux | LINUX) printf 'linux' ;;
        m | M | mac | Mac | MAC | macos | macOS | MACOS | darwin | Darwin) printf 'macos' ;;
        '') printf '%s' "$default" ;;
        *) printf '%s' "$default" ;;
    esac
}

backup_path() { printf '%s.backup.%s' "$1" "$(date +%Y%m%d-%H%M%S)"; }

detect_os() {
    case "$(uname -s)" in
        Darwin) printf 'macos' ;;
        Linux) printf 'linux' ;;
        *) printf 'linux' ;;
    esac
}

write_os_conf() {
    target="$1/os/$2.conf"
    if [ ! -f "$target" ]; then
        err "missing $target — repo layout looks wrong"
        exit 1
    fi
    printf 'source-file %s/os/%s.conf\n' "$1" "$2" >"$1/os.conf"
    ok "os.conf → source os/$2.conf"
}

# macOS's system ncurses (2015) ships tmux-256color without bracketed paste
# (BE/BD), so pastes leak raw [200~/[201~ markers into vim, psql, etc. under
# tmux. Install a modern entry into ~/.terminfo (searched before the system db).
# Capability-detected, not OS-branched — a no-op on modern Linux.
install_terminfo() {
    if infocmp -x tmux-256color 2>/dev/null | grep -q 'BE='; then
        ok "tmux-256color already supports bracketed paste"
        return 0
    fi

    # System infocmp may be too old to be the source; prefer Homebrew's ncurses.
    src=''
    for ic in \
        /opt/homebrew/opt/ncurses/bin/infocmp \
        /usr/local/opt/ncurses/bin/infocmp \
        infocmp; do
        if command -v "$ic" >/dev/null 2>&1 \
            && "$ic" -x tmux-256color 2>/dev/null | grep -q 'BE='; then
            src=$ic
            break
        fi
    done

    if [ -z "$src" ]; then
        warn "no terminfo source with bracketed paste found — paste inside tmux"
        warn "may show literal [200~ markers; fix with: brew install ncurses, then rerun"
        return 0
    fi

    # Compile with the SYSTEM tic, not Homebrew's: vim/nvim link against the
    # platform's older ncurses, which can't read the format newer tic emits.
    if "$src" -x tmux-256color 2>/dev/null | tic -x -o "$HOME/.terminfo" - 2>/dev/null; then
        ok "installed modern tmux-256color → ~/.terminfo (fixes paste markers)"
    else
        warn "failed to compile tmux-256color into ~/.terminfo"
    fi
}

banner

step "Pre-flight checks"
if ! command -v git >/dev/null 2>&1; then
    err "git not found — install it first"
    exit 1
fi
ok "git"

if command -v tmux >/dev/null 2>&1; then
    tmux_version=$(tmux -V | awk '{print $2}')
    ok "tmux $tmux_version"
else
    warn "tmux not installed — install tmux ≥ 3.3 before launching"
fi

# In-place run from inside a clone → skip clone/backup.
# Only trust IN_PLACE when $0 is a real file (rules out `sh -c` / `curl | sh`,
# where $0 is just `sh` and dirname resolves to CWD).
IN_PLACE=0
if [ -f "$0" ]; then
    SCRIPT_DIR=$(cd "$(dirname "$0")" 2>/dev/null && pwd || printf '')
    if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/tmux.conf" ] && [ -d "$SCRIPT_DIR/os" ]; then
        IN_PLACE=1
        TMUX_CONFIG="$SCRIPT_DIR"
        info "running in-place inside $TMUX_CONFIG"
    fi
fi

# Returns 0 if $TMUX_CONFIG is a clone of $REPO_URL.
is_same_repo() {
    [ -d "$TMUX_CONFIG/.git" ] || return 1
    existing=$(git -C "$TMUX_CONFIG" remote get-url origin 2>/dev/null || printf '')
    [ -n "$existing" ] || return 1
    # Tolerate trailing .git / https-vs-ssh by stripping noise.
    normalize() { printf '%s' "$1" | sed -e 's#\.git$##' -e 's#^git@github.com:#https://github.com/#'; }
    [ "$(normalize "$existing")" = "$(normalize "$REPO_URL")" ]
}

if [ "$IN_PLACE" -eq 0 ]; then
    if [ -e "$TMUX_CONFIG" ] && is_same_repo; then
        step "Update existing clone"
        info "$TMUX_CONFIG already tracks $REPO_URL — pulling latest"
        if git -C "$TMUX_CONFIG" pull --ff-only; then
            ok "updated $TMUX_CONFIG"
        else
            warn "git pull failed — falling back to backup + fresh clone"
            bk=$(backup_path "$TMUX_CONFIG")
            mv "$TMUX_CONFIG" "$bk"
            ok "moved conflicting clone to $bk"
            git clone --depth 1 "$REPO_URL" "$TMUX_CONFIG"
            ok "cloned to $TMUX_CONFIG"
        fi
    else
        step "Backup existing"
        if [ -e "$TMUX_CONFIG" ]; then
            bk=$(backup_path "$TMUX_CONFIG")
            # Non-interactive (no /dev/tty): back up silently instead of aborting.
            if [ ! -r /dev/tty ]; then
                mv "$TMUX_CONFIG" "$bk"
                ok "non-interactive — moved existing config to $bk"
            elif prompt_yes "Move $TMUX_CONFIG → $bk?"; then
                mv "$TMUX_CONFIG" "$bk"
                ok "config moved to $bk"
            else
                err "aborted — config already exists at $TMUX_CONFIG"
                exit 1
            fi
        else
            info "no existing $TMUX_CONFIG"
        fi

        # ~/.tmux.conf shadows ~/.config/tmux/tmux.conf on tmux ≥ 3.1.
        if [ -e "$LEGACY_TMUX_CONF" ]; then
            bk=$(backup_path "$LEGACY_TMUX_CONF")
            if [ -r /dev/tty ] && prompt_yes "Move legacy $LEGACY_TMUX_CONF → $bk? (it shadows the new config)"; then
                mv "$LEGACY_TMUX_CONF" "$bk"
                ok "legacy config moved to $bk"
            else
                warn "kept $LEGACY_TMUX_CONF — tmux will prefer it over the new config"
            fi
        fi

        step "Clone repository"
        git clone --depth 1 "$REPO_URL" "$TMUX_CONFIG"
        ok "cloned to $TMUX_CONFIG"
    fi
fi

# Tarball / manual copy strips +x.
if [ -f "$TMUX_CONFIG/bin/refresh-windows.sh" ]; then
    chmod +x "$TMUX_CONFIG/bin/refresh-windows.sh"
fi

step "OS selection"
detected=$(detect_os)
info "detected: $detected"
if [ -r /dev/tty ]; then
    choice=$(prompt_choice "Which OS profile should tmux load?" "$detected")
else
    choice=$detected
    info "non-interactive — using detected ($choice)"
fi
write_os_conf "$TMUX_CONFIG" "$choice"

step "Terminal database"
install_terminfo

if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    step "Reload running tmux"
    if [ -r /dev/tty ] && prompt_yes "Source new config into the running tmux server?"; then
        if tmux source-file "$TMUX_CONFIG/tmux.conf"; then
            ok "reloaded — new theme is live in attached clients"
        else
            warn "tmux source-file returned non-zero — inspect the config"
        fi
    else
        info "skipped reload — run :source-file $TMUX_CONFIG/tmux.conf inside tmux"
    fi
fi

step "Done"
ok "miniex/dotfiles.tmux installed at $TMUX_CONFIG"
printf '\n  %sNext:%s\n' "$BOLD" "$RESET"
printf '    %s•%s launch %s%stmux%s — prefix is %s%sCtrl-a%s\n' \
    "$PINK" "$RESET" "$SKY" "$BOLD" "$RESET" "$SKY" "$BOLD" "$RESET"
printf '    %s•%s pair with %s%sminiex/dotfiles.kitty%s + %s%sfish-theme-damin%s for the matched palette\n' \
    "$PINK" "$RESET" "$SKY" "$BOLD" "$RESET" "$SKY" "$BOLD" "$RESET"
printf '    %s•%s rerun %s%ssh %s/install.sh%s to switch OS profile\n\n' \
    "$PINK" "$RESET" "$SKY" "$BOLD" "$TMUX_CONFIG" "$RESET"
