#!/bin/sh
# Update the config in place: git pull --ff-only, restore the +x bits, reload a
# running server. os.conf and theme.conf are generated and untracked, so the OS
# profile and the theme selection survive an update untouched.
#
#   update.sh          update and reload
#   update.sh --pause  same, then wait for Enter — used by the prefix U popup,
#                      which would otherwise close before the output is read
set -eu

CONFIG_DIR=$(cd "$(dirname "$0")/.." && pwd)
DEFAULT_THEME=damin

PAUSE=0
case "${1:-}" in
    '') ;;
    --pause) PAUSE=1 ;;
    *)
        echo "usage: update.sh [--pause]" >&2
        exit 2
        ;;
esac

if [ -t 1 ]; then
    RESET=$(printf '\033[0m')
    BOLD=$(printf '\033[1m')
    SKY=$(printf '\033[38;2;152;171;204m')
    PINK=$(printf '\033[38;2;232;144;176m')
    YELLOW=$(printf '\033[33m')
    RED=$(printf '\033[31m')
else
    RESET=''
    BOLD=''
    SKY=''
    PINK=''
    YELLOW=''
    RED=''
fi

step() { printf '\n%s%s▸ %s%s\n' "$BOLD" "$SKY" "$1" "$RESET"; }
info() { printf '  %sℹ%s  %s\n' "$SKY" "$RESET" "$1"; }
ok() { printf '  %s✓%s  %s\n' "$PINK" "$RESET" "$1"; }
warn() { printf '  %s⚠%s  %s\n' "$YELLOW" "$RESET" "$1"; }
err() { printf '  %s✗%s  %s\n' "$RED" "$RESET" "$1" >&2; }

# Runs on every exit path, so a failed pull is still readable in the popup.
finish() {
    if [ "$PAUSE" -eq 1 ]; then
        printf '\n  %spress Enter to close%s ' "$SKY" "$RESET"
        read -r _ </dev/tty 2>/dev/null || true
    fi
}
trap finish EXIT

step "Update $CONFIG_DIR"

if ! command -v git >/dev/null 2>&1; then
    err "git not found — install it first"
    exit 1
fi

if [ ! -d "$CONFIG_DIR/.git" ]; then
    err "not a git clone — reinstall with: sh $CONFIG_DIR/install.sh"
    exit 1
fi

if [ -n "$(git -C "$CONFIG_DIR" status --porcelain 2>/dev/null)" ]; then
    warn "local changes present — the pull will fail if they conflict"
fi

before=$(git -C "$CONFIG_DIR" rev-parse --short HEAD)

if ! git -C "$CONFIG_DIR" pull --ff-only; then
    err "git pull --ff-only failed"
    info "resolve by hand, or reinstall: sh $CONFIG_DIR/install.sh"
    exit 1
fi

after=$(git -C "$CONFIG_DIR" rev-parse --short HEAD)

if [ "$before" = "$after" ]; then
    ok "already up to date ($after)"
else
    ok "$before → $after"
    git -C "$CONFIG_DIR" --no-pager log --oneline "$before..$after" | sed 's/^/      /'
fi

# Tarball / manual copy strips +x, and a pull can add new scripts.
for script in "$CONFIG_DIR"/bin/*.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
    fi
done

step "Check generated config"

if [ -f "$CONFIG_DIR/os.conf" ]; then
    ok "os.conf kept"
else
    warn "no os.conf — clipboard bindings are missing; run: sh $CONFIG_DIR/install.sh"
fi

theme=$("$CONFIG_DIR/bin/theme.sh" current)
if [ -f "$CONFIG_DIR/themes/$theme.conf" ]; then
    ok "theme kept: $theme"
else
    # The selected theme was renamed or removed upstream.
    warn "theme '$theme' no longer exists — falling back to $DEFAULT_THEME"
    "$CONFIG_DIR/bin/theme.sh" set "$DEFAULT_THEME" >/dev/null
fi

if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
    step "Reload"
    if tmux source-file "$CONFIG_DIR/tmux.conf"; then
        ok "sourced tmux.conf — live in attached clients"
        tmux display-message "♡ updated ✿"
    else
        warn "tmux source-file returned non-zero — inspect the config"
    fi
fi
