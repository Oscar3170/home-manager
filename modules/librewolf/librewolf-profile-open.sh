#!/usr/bin/env bash

set -uo pipefail

profile_root="${LIBREWOLF_PROFILE_ROOT:-$HOME/.librewolf}"
profiles_ini="$profile_root/profiles.ini"
installs_ini="$profile_root/installs.ini"

librewolf_bin="${LIBREWOLF_BIN:-}"
if [[ -z "$librewolf_bin" ]]; then
    librewolf_bin="$(command -v librewolf 2>/dev/null || true)"
fi

show_error() {
    local message="$1"

    printf 'librewolf-profile-open: %s\n' "$message" >&2
    if command -v zenity >/dev/null 2>&1 \
        && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        zenity --error --title="LibreWolf profile chooser" \
            --text="$message" >/dev/null 2>&1 || true
    fi
    exit 1
}

if (( $# != 1 )); then
    show_error "Expected exactly one URL or file to open."
fi

if [[ -z "$librewolf_bin" || ! -x "$librewolf_bin" ]]; then
    show_error "Could not find the LibreWolf executable."
fi

uri="$1"

# If LibreWolf has not created its profile registry yet, let it start normally.
if [[ ! -r "$profiles_ini" ]]; then
    exec "$librewolf_bin" "$uri"
fi

trim() {
    local value="$1"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    REPLY="$value"
}

# An install-specific default overrides the older Default=1 profile marker.
declare -A default_profile_paths=()
if [[ -r "$installs_ini" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ "$line" == Default=* ]] || continue

        default_path="${line#Default=}"
        trim "$default_path"
        default_path="$REPLY"
        [[ -n "$default_path" ]] || continue

        if [[ "$default_path" != /* ]]; then
            default_path="$profile_root/$default_path"
        fi
        default_path="$(realpath -m -- "$default_path")"
        default_profile_paths["$default_path"]=1
    done < "$installs_ini"
fi

process_uses_profile() {
    local pid="$1"
    local profile_dir="$2"
    local fd target

    [[ -d "/proc/$pid/fd" ]] || return 1

    for fd in "/proc/$pid/fd/"*; do
        target="$(readlink -- "$fd" 2>/dev/null || true)"
        case "$target" in
            "$profile_dir"|"$profile_dir"/*)
                return 0
                ;;
        esac
    done

    return 1
}

declare -a active_profile_names=()
declare -a active_profile_labels=()
declare -A seen_profile_paths=()

section=""
profile_name=""
profile_path=""
profile_is_relative="1"

inspect_profile() {
    [[ "$section" =~ ^Profile[0-9]+$ ]] || return 0
    [[ -n "$profile_name" && -n "$profile_path" ]] || return 0

    local profile_dir="$profile_path"
    local lock_target pid process_exe label

    if [[ "$profile_is_relative" == "1" ]]; then
        profile_dir="$profile_root/$profile_dir"
    fi
    profile_dir="$(realpath -m -- "$profile_dir")"

    [[ -z "${seen_profile_paths[$profile_dir]+present}" ]] || return 0
    seen_profile_paths["$profile_dir"]=1

    # On Linux, an open Mozilla profile has a dangling lock symlink whose
    # target ends in :+PID. Test with -L rather than -e because it is dangling.
    [[ -L "$profile_dir/lock" ]] || return 0
    lock_target="$(readlink -- "$profile_dir/lock" 2>/dev/null || true)"
    [[ "$lock_target" =~ :\+([0-9]+)$ ]] || return 0
    pid="${BASH_REMATCH[1]}"

    [[ -d "/proc/$pid" ]] || return 0
    process_exe="$(readlink -- "/proc/$pid/exe" 2>/dev/null || true)"
    process_exe="${process_exe%" (deleted)"}"
    case "${process_exe##*/}" in
        librewolf|librewolf-bin) ;;
        *) return 0 ;;
    esac

    # This also rejects stale locks whose PID has since been reused.
    process_uses_profile "$pid" "$profile_dir" || return 0

    label="$profile_name"
    if [[ -n "${default_profile_paths[$profile_dir]+present}" ]]; then
        label="$profile_name (default)"
    fi

    active_profile_names+=("$profile_name")
    active_profile_labels+=("$label")
}

while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"

    if [[ "$line" =~ ^\[(.*)\]$ ]]; then
        next_section="${BASH_REMATCH[1]}"
        inspect_profile
        section="$next_section"
        profile_name=""
        profile_path=""
        profile_is_relative="1"
        continue
    fi

    [[ "$section" =~ ^Profile[0-9]+$ && "$line" == *=* ]] || continue

    key="${line%%=*}"
    value="${line#*=}"
    trim "$key"
    key="$REPLY"
    trim "$value"
    value="$REPLY"

    case "$key" in
        Name) profile_name="$value" ;;
        Path) profile_path="$value" ;;
        IsRelative) profile_is_relative="$value" ;;
    esac
done < "$profiles_ini"
inspect_profile

case "${#active_profile_names[@]}" in
    0)
        exec "$librewolf_bin" "$uri"
        ;;
    1)
        exec "$librewolf_bin" -P "${active_profile_names[0]}" \
            --new-tab "$uri"
        ;;
esac

if ! command -v zenity >/dev/null 2>&1; then
    show_error "More than one LibreWolf profile is open, but Zenity is unavailable."
fi

zenity_rows=()
for (( i = 0; i < ${#active_profile_names[@]}; i++ )); do
    zenity_rows+=("${active_profile_names[i]}" "${active_profile_labels[i]}")
done

selected_profile="$(
    zenity --list \
        --title="Choose LibreWolf profile" \
        --text="Choose which open profile should receive the link:" \
        --column="Profile ID" \
        --column="Profile" \
        --hide-column=1 \
        --print-column=1 \
        --hide-header \
        --width=420 \
        --height=280 \
        "${zenity_rows[@]}"
)"
zenity_status=$?

# Cancelling the chooser intentionally leaves the URL unopened.
if (( zenity_status != 0 )) || [[ -z "$selected_profile" ]]; then
    exit 0
fi

exec "$librewolf_bin" -P "$selected_profile" --new-tab "$uri"
