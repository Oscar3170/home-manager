#!/usr/bin/env bash
set -euo pipefail

# Respect explicit flake and legacy configuration selections.
for arg in "$@"; do
    case "$arg" in
        --flake|-f)
            exec "@home-manager@/bin/home-manager" "$@"
            ;;
    esac
done

if [[ ${HOME_MANAGER_CONFIG+x} ]]; then
    exec "@home-manager@/bin/home-manager" "$@"
fi

# Nix path flakes require the source directory itself, not a symlink to it.
flake_dir=$("@realpath@" -e -- "${XDG_CONFIG_HOME:-$HOME/.config}/home-manager")

exec "@home-manager@/bin/home-manager" --flake "path:$flake_dir" "$@"
