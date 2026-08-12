#!/bin/sh
# Rewrite window-status-{,current-}format with a gradient across the live window
# count. Endpoints and glyphs come from the active theme: the colour is
# interpolated between @theme_grad_start and @theme_grad_end, then substituted
# for every @C in @theme_win_format / @theme_win_current_format.
# Wired to tmux hooks in tmux.conf; bin/theme.sh re-runs it after a switch.
set -eu

# Fallbacks — used when no theme is loaded, or when it sets a non-hex colour.
DEFAULT_START='#98ABCC'
DEFAULT_END='#E890B0'
DEFAULT_FORMAT='#[fg=@C,nobold] #I:#W '
DEFAULT_CURRENT='#[fg=@C,bold] ✿ #I:#W ♡ '

# $1=option name, $2=fallback
opt() {
    value=$(tmux show-option -gqv "$1" 2>/dev/null || printf '')
    if [ -n "$value" ]; then
        printf '%s' "$value"
    else
        printf '%s' "$2"
    fi
}

# Same, but rejects anything that isn't #RRGGBB — the interpolation below does
# integer math on the components and can't work from a named colour.
opt_hex() {
    value=$(opt "$1" "$2")
    case $value in
        '#'[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]) ;;
        *) value=$2 ;;
    esac
    printf '%s' "$value"
}

start=$(opt_hex @theme_grad_start "$DEFAULT_START")
end=$(opt_hex @theme_grad_end "$DEFAULT_END")
tpl_format=$(opt @theme_win_format "$DEFAULT_FORMAT")
tpl_current=$(opt @theme_win_current_format "$DEFAULT_CURRENT")

# '#RRGGBB' → $r $g $b. POSIX sh has no arrays, so callers copy the three
# globals out before the next call overwrites them.
split_rgb() {
    hex=${1#\#}
    rest=${hex#??}
    r=$((0x${hex%????}))
    g=$((0x${rest%??}))
    b=$((0x${rest#??}))
}

split_rgb "$start"
sr=$r
sg=$g
sb=$b
split_rgb "$end"
er=$r
eg=$g
eb=$b

count=$(tmux display-message -p '#{session_windows}' 2>/dev/null || echo 1)
case $count in
    '' | *[!0-9]*) count=1 ;;
esac

# idx,total → #RRGGBB (linear interp ×1000 for integer math).
interp() {
    idx=$1
    total=$2
    if [ "$total" -lt 2 ]; then
        printf '%s' "$start"
        return
    fi
    t=$(((idx - 1) * 1000 / (total - 1)))
    printf '#%02X%02X%02X' \
        "$((sr + (er - sr) * t / 1000))" \
        "$((sg + (eg - sg) * t / 1000))" \
        "$((sb + (eb - sb) * t / 1000))"
}

# Nest #{?#{==:#I,N},c_N,…} so one static format colors every row —
# tmux substitutes #I per window at render time.
build_color_expr() {
    total=$1
    expr=$(interp 1 "$total")
    i=$total
    while [ "$i" -ge 1 ]; do
        c=$(interp "$i" "$total")
        expr="#{?#{==:#I,${i}},${c},${expr}}"
        i=$((i - 1))
    done
    printf '%s' "$expr"
}

color=$(build_color_expr "$count")

# Substitute every @C in a theme template with that expression.
expand_tpl() {
    tpl=$1
    out=''
    while :; do
        case $tpl in
            *@C*)
                out="$out${tpl%%@C*}$color"
                tpl=${tpl#*@C}
                ;;
            *)
                printf '%s' "$out$tpl"
                return
                ;;
        esac
    done
}

tmux set-option -gw window-status-format "$(expand_tpl "$tpl_format")"
tmux set-option -gw window-status-current-format "$(expand_tpl "$tpl_current")"
