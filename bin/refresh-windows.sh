#!/bin/sh
# Rewrite window-status-{,current-}format with a #98ABCC → #E890B0 gradient
# across the live window count. Wired to tmux hooks in tmux.conf.
set -eu

count=$(tmux display-message -p '#{session_windows}' 2>/dev/null || echo 1)
case $count in
    '' | *[!0-9]*) count=1 ;;
esac

# idx,total → #RRGGBB (linear interp ×1000 for integer math).
interp() {
    idx=$1
    total=$2
    if [ "$total" -lt 2 ]; then
        printf '#98ABCC'
        return
    fi
    t=$(((idx - 1) * 1000 / (total - 1)))
    r=$((152 + (232 - 152) * t / 1000))
    g=$((171 + (144 - 171) * t / 1000))
    b=$((204 + (176 - 204) * t / 1000))
    printf '#%02X%02X%02X' "$r" "$g" "$b"
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

tmux set-option -gw window-status-format "#[fg=${color},nobold] #I:#W "
tmux set-option -gw window-status-current-format "#[fg=${color},bold] ✿ #I:#W ♡ "
