#!/bin/sh
# List, apply, and persist the active theme.
#
#   theme.sh list         names of themes/*.conf, one per line (default first)
#   theme.sh current      name of the active theme
#   theme.sh set <name>   write theme.conf, load it into a running server
#   theme.sh menu         tmux picker, bound to `prefix T` in tmux.conf
#
# theme.conf is generated (gitignored) and holds a single source-file line, the
# same trick os.conf uses — tmux.conf sources it on every start and reload.
set -eu

CONFIG_DIR=$(cd "$(dirname "$0")/.." && pwd)
THEMES_DIR="$CONFIG_DIR/themes"
THEME_CONF="$CONFIG_DIR/theme.conf"
SELF="$CONFIG_DIR/bin/theme.sh"
DEFAULT_THEME=damin

usage() {
    echo "usage: theme.sh list|current|set <name>|menu" >&2
    exit 2
}

# Default first, then the rest alphabetically — glob order would bury `damin`
# behind every `damin-*` variant ('-' sorts before '.').
list_themes() {
    if [ -f "$THEMES_DIR/$DEFAULT_THEME.conf" ]; then
        printf '%s\n' "$DEFAULT_THEME"
    fi
    for f in "$THEMES_DIR"/*.conf; do
        [ -f "$f" ] || continue
        name=${f##*/}
        name=${name%.conf}
        if [ "$name" != "$DEFAULT_THEME" ]; then
            printf '%s\n' "$name"
        fi
    done
}

# Parsed from theme.conf rather than @theme_name so it also answers outside tmux.
current_theme() {
    if [ -f "$THEME_CONF" ]; then
        name=$(sed -n 's|^source-file .*/themes/\(.*\)\.conf$|\1|p' "$THEME_CONF" | head -n1)
        if [ -n "$name" ]; then
            printf '%s\n' "$name"
            return
        fi
    fi
    printf '%s\n' "$DEFAULT_THEME"
}

set_theme() {
    name=$1
    if [ ! -f "$THEMES_DIR/$name.conf" ]; then
        echo "unknown theme: $name" >&2
        echo "available: $(list_themes | tr '\n' ' ')" >&2
        exit 1
    fi

    printf 'source-file %s/themes/%s.conf\n' "$CONFIG_DIR" "$name" >"$THEME_CONF"

    # Live-apply when a server is up; otherwise the next tmux start picks it up.
    if command -v tmux >/dev/null 2>&1 && tmux has-session 2>/dev/null; then
        tmux source-file "$THEME_CONF"
        # The theme only ships static fallbacks for the window list — regenerate
        # the gradient against the new endpoints and glyphs.
        "$CONFIG_DIR/bin/refresh-windows.sh"
        tmux display-message "♡ theme → $name ✿"
    else
        echo "theme → $name (no tmux server running; applies on next start)"
    fi
}

menu() {
    active=$(current_theme)
    accent=$(tmux show-option -gqv @theme_grad_end 2>/dev/null || printf '')
    if [ -z "$accent" ]; then
        accent='#E890B0'
    fi

    set -- -T "#[align=centre,fg=$accent,bold] theme " -x C -y C
    i=1
    for name in $(list_themes); do
        if [ "$name" = "$active" ]; then
            label="✿ $name"
        else
            label="  $name"
        fi
        # Keys run out at 9; extra themes stay clickable with no shortcut.
        if [ "$i" -le 9 ]; then
            key=$i
        else
            key=''
        fi
        set -- "$@" "$label" "$key" "run-shell -b \"$SELF set $name\""
        i=$((i + 1))
    done
    tmux display-menu "$@"
}

[ $# -ge 1 ] || usage

case $1 in
    list) list_themes ;;
    current) current_theme ;;
    set)
        [ $# -eq 2 ] || usage
        set_theme "$2"
        ;;
    menu) menu ;;
    *) usage ;;
esac
