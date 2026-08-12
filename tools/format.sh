#!/bin/sh
# Format shell scripts (shfmt).
set -e

cd "$(dirname "$0")/.."

if ! command -v shfmt >/dev/null 2>&1; then
    echo "missing required tool: shfmt" >&2
    exit 1
fi

scripts="install.sh tools/format.sh tools/lint.sh"
scripts="$scripts bin/refresh-windows.sh bin/theme.sh bin/update.sh"

# shellcheck disable=SC2086  # deliberate word splitting over the script list
shfmt -w -i 4 -ci -bn -s $scripts
