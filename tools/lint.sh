#!/bin/sh
# Lint shell scripts (shfmt --diff + shellcheck). Contributor/maintainer tool —
# every binary below must be on PATH.
set -e

cd "$(dirname "$0")/.."

missing=
for tool in shfmt shellcheck; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing="$missing $tool"
    fi
done

if [ -n "$missing" ]; then
    echo "missing required tool(s):$missing" >&2
    echo "install via your package manager (brew/apt/cargo/etc.)" >&2
    exit 1
fi

scripts="install.sh tools/format.sh tools/lint.sh"
scripts="$scripts bin/refresh-windows.sh bin/theme.sh bin/update.sh"

# shellcheck disable=SC2086  # deliberate word splitting over the script list
shfmt -d -i 4 -ci -bn -s $scripts
# shellcheck disable=SC2086
shellcheck $scripts
