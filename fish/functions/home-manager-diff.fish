function home-manager-diff --description 'Compare Home Manager generation files by contents'
    argparse 'c/content' 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        echo 'Usage: home-manager-diff [--content|-c] [OLD_ID [NEW_ID]]'
        echo 'Defaults: OLD_ID = previous generation, NEW_ID = latest generation.'
        return 0
    end
    if test (count $argv) -gt 2
        echo 'home-manager-diff: expected at most two generation IDs' >&2
        return 2
    end

    set -l generations (home-manager generations)
    if test (count $generations) -lt 2
        echo 'home-manager-diff: need at least two generations' >&2
        return 2
    end

    set -l old_id (string match -r -- 'id [0-9]+' "$generations[2]" | string replace 'id ' '')
    set -l new_id (string match -r -- 'id [0-9]+' "$generations[1]" | string replace 'id ' '')
    if set -q argv[1]
        set old_id $argv[1]
    end
    if set -q argv[2]
        set new_id $argv[2]
    end

    for id in $old_id $new_id
        if not string match -qr -- '^[0-9]+$' "$id"
            echo "home-manager-diff: invalid generation ID: $id" >&2
            return 2
        end
    end

    set -l old_color yellow
    set -l new_color green
    if test "$old_id" -gt "$new_id"
        set old_color green
        set new_color yellow
    end
    set -l old_label (set_color $old_color)$old_id(set_color normal)
    set -l new_label (set_color $new_color)$new_id(set_color normal)

    set -l old_gen (string match -r -- "id $old_id -> /nix/store/[^ ]+-home-manager-generation" $generations | string match -r '/nix/store/[^ ]+-home-manager-generation')
    set -l new_gen (string match -r -- "id $new_id -> /nix/store/[^ ]+-home-manager-generation" $generations | string match -r '/nix/store/[^ ]+-home-manager-generation')
    if test (count $old_gen) -ne 1; or test (count $new_gen) -ne 1
        echo "home-manager-diff: generation not found: $old_label or $new_label" >&2
        return 2
    end

    printf 'Comparing Home Manager generations %s(%s) and %s(%s)\n\n' "$old_label" "$old_gen" "$new_label" "$new_gen" >&2

    if test "$old_id" = "$new_id"
        return 0
    end

    if not set -q _flag_content
        diff -qr -- "$old_gen/home-files" "$new_gen/home-files" \
            | string replace -a -- "$old_gen/home-files" "$old_label" \
            | string replace -a -- "$new_gen/home-files" "$new_label"
        return $pipestatus[1]
    end

    # Git compares symlink targets by default; copy and dereference to diff their contents.
    set -l tmp (mktemp -d)
    or return 2
    if not cp -RL -- "$old_gen/home-files/." "$tmp/$old_id"
        chmod -R u+w -- "$tmp"
        rm -rf -- "$tmp"
        return 2
    end
    if not cp -RL -- "$new_gen/home-files/." "$tmp/$new_id"
        chmod -R u+w -- "$tmp"
        rm -rf -- "$tmp"
        return 2
    end

    git -C "$tmp" diff --no-index --color=always -- "$old_id" "$new_id" | while read -l line
        # Git prefixes colored headers with ANSI codes; inspect their plain text only.
        set -l plain (string replace -r -- '^(\x1b\[[0-9;]*m)*' '' "$line")
        switch $plain
            case 'diff --git *' '--- *' '+++ *' 'Binary files *'
                set line (string replace -a -- "a/$old_id/" "a/$old_label/" "$line" \
                    | string replace -a -- "b/$new_id/" "b/$new_label/")
        end
        printf '%s\n' "$line"
    end
    set -l result $pipestatus[1]
    chmod -R u+w -- "$tmp"
    rm -rf -- "$tmp"
    return $result
end
