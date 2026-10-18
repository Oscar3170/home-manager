function watchg --description 'Watch a command and, with --pattern, notify when its output matches a PCRE2 regex'

    set -l raw_argv $argv

    # Short flags follow GNU watch(1) where they overlap; watchg's own switches
    # are long-only unless noted.
    argparse --name=watchg \
        'b/beep' 'c/color' 'C/no-color' 'd/differences' 'e/errexit' 'f/follow' \
        'g/chgexit' 'q/equexit=+' 'n/interval=+' 'p/precise' 'r/no-rerun' \
        's/shotsdir=+' 't/no-title' 'w/no-wrap' 'x/exec' 'version' \
        'P/pattern=+' 'i/ignore-case' 'v/invert' 'context=+' 'h/help' \
        'title=+' 'u/urgency=+' 'a/app-name=+' 'sound=+' 'o/occasion=+' \
        'N/notifier=+' 'T/no-tui' 'Q/quiet' 'S/state-dir=+' 'L/no-lock' \
        -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'watchg - run a command every N seconds, optionally notifying on a pattern match' \
            '' \
            'Usage:' \
            '  watchg [OPTIONS] -- COMMAND [ARGS...]' \
            '' \
            'Without --pattern this is a plain watch(1) replacement. With --pattern the' \
            'merged stdout and stderr of COMMAND are matched line by line, and a desktop' \
            'notification is sent when the output starts matching. Notifications are edge' \
            'triggered: no further notification until an update with no match is seen.' \
            '' \
            'Display (GNU watch compatible):' \
            '  -n, --interval SECS     Seconds between updates, may be fractional (default: 5)' \
            '  -p, --precise           Include the command runtime in the interval' \
            '  -t, --no-title          No header and status lines' \
            '  -c, --color             Keep SGR color in the command output (default)' \
            '  -C, --no-color          Strip every escape sequence from the command output' \
            '  -w, --no-wrap           Do not wrap long lines' \
            '  -d, --differences       Highlight lines that changed since the last update' \
            '  -f, --follow            No full screen view, print all output every update' \
            '  -b, --beep              Beep when the command exits non-zero' \
            '  -e, --errexit           Exit when the command exits non-zero' \
            '  -g, --chgexit           Exit when the output changes' \
            '  -q, --equexit CYCLES    Exit when the output is unchanged for CYCLES updates' \
            '  -s, --shotsdir DIR      Write every changed screen into DIR' \
            '  -r, --no-rerun          Accepted for compatibility, watchg never reruns on resize' \
            '  -x, --exec              Accepted for compatibility, commands always run directly' \
            '      --version           Print the version and exit' \
            '' \
            'Matching (needs --pattern):' \
            '  -P, --pattern REGEX     PCRE2 pattern, "grep -P" syntax' \
            '  -i, --ignore-case       Case insensitive matching' \
            '  -v, --invert            Select the lines that do NOT match REGEX' \
            '      --context N         Lines of context around the match in the notification' \
            '' \
            'Notifications (need --pattern):' \
            '      --title TEXT        Title (default: "watchg: <command>")' \
            '  -u, --urgency LEVEL     low, normal or critical (default: normal)' \
            '  -a, --app-name NAME     Application name (default: watchg)' \
            '      --sound NAME        system, silent, info, warn, error... (default: silent)' \
            '  -o, --occasion WHEN     always, unfocused or invisible (default: always)' \
            '  -N, --notifier NAME     auto, kitty or notify-send (default: auto)' \
            '' \
            'This tool:' \
            '  -T, --no-tui            Print matching lines (all output without --pattern)' \
            '  -Q, --quiet             Do not print anything' \
            '  -S, --state-dir DIR     Lock and scratch directory (default: /tmp/watchg-$UID)' \
            '  -L, --no-lock           Allow several identical watchers to run at once' \
            '  -h, --help              Show this help' \
            '' \
            'Notes:' \
            '  Command output is sanitized before it reaches the terminal: OSC/DCS and all' \
            '  non-SGR sequences are dropped, so log content cannot move the cursor, change' \
            '  terminal modes, write the clipboard or forge notifications. -C drops SGR too.' \
            '' \
            '  In kitty the notification uses the OSC 99 escape code and clicking it focuses' \
            '  the window that emitted it; --sound/--occasion/--urgency only apply there.' \
            '  Elsewhere notify-send is used, when available.' \
            '' \
            '  Only one watcher per working directory, pattern and command runs at a time.' \
            '  The lock is a lease the holder renews every update, so an interrupted run' \
            '  frees it after max(3, interval+1) seconds without any cleanup. --no-lock' \
            '  disables the check entirely.' \
            '' \
            '  The full screen view is drawn on the normal screen, not on the alternate one:' \
            '  fish cannot restore the alternate screen when an interactive function is' \
            '  interrupted, which would leave the shell drawing off screen. The last frame' \
            '  therefore stays in the scrollback.' \
            '' \
            'Exit status: the command status with --errexit, 130 when interrupted' \
            'interactively, 2 usage error, 3 another watcher holds the lock.'
        return 0
    end

    if set -q _flag_version
        echo 'watchg 1.1.0'
        return 0
    end

    if not contains -- -- $raw_argv
        echo 'watchg: missing "--" before COMMAND' >&2
        return 2
    end

    set -l child $argv
    if not set -q child[1]
        echo 'watchg: missing COMMAND' >&2
        return 2
    end

    set -l pattern
    set -q _flag_pattern; and set pattern $_flag_pattern[-1]
    if test -z "$pattern"
        for pair in _flag_ignore_case:--ignore-case _flag_invert:--invert _flag_context:--context \
                _flag_title:--title _flag_urgency:--urgency _flag_app_name:--app-name \
                _flag_sound:--sound _flag_occasion:--occasion _flag_notifier:--notifier
            set -l parts (string split ':' -- $pair)
            if set -q $parts[1]
                echo "watchg: $parts[2] requires --pattern" >&2
                return 2
            end
        end
    end

    set -l interval 5
    set -q _flag_interval; and set interval $_flag_interval[-1]
    if not string match -qr '^[0-9]+(\.[0-9]+)?$' -- $interval; or not test $interval -gt 0
        echo "watchg: invalid interval: $interval" >&2
        return 2
    end

    set -l context 0
    if set -q _flag_context
        set context $_flag_context[-1]
        if not string match -qr '^[0-9]+$' -- $context
            echo "watchg: invalid context: $context" >&2
            return 2
        end
    end

    set -l equexit 0
    if set -q _flag_equexit
        set equexit $_flag_equexit[-1]
        if not string match -qr '^[0-9]+$' -- $equexit; or test $equexit -lt 1
            echo "watchg: invalid --equexit value: $equexit" >&2
            return 2
        end
    end

    set -l beep 0
    set -q _flag_beep; and set beep 1
    set -l errexit 0
    set -q _flag_errexit; and set errexit 1
    set -l chgexit 0
    set -q _flag_chgexit; and set chgexit 1
    set -l diff_mode 0
    set -q _flag_differences; and set diff_mode 1
    set -l follow 0
    set -q _flag_follow; and set follow 1
    set -l no_title 0
    set -q _flag_no_title; and set no_title 1
    set -l no_wrap 0
    set -q _flag_no_wrap; and set no_wrap 1
    set -l precise 0
    set -q _flag_precise; and set precise 1
    set -l strip_color 0
    set -q _flag_no_color; and set strip_color 1
    set -l quiet 0
    set -q _flag_quiet; and set quiet 1

    if test $follow = 1; and test $diff_mode = 1
        echo 'watchg: --follow cannot be combined with --differences' >&2
        return 2
    end
    if test $follow = 1; and test $chgexit = 1
        echo 'watchg: --follow cannot be combined with --chgexit' >&2
        return 2
    end
    if test $follow = 1; and test $equexit -gt 0
        echo 'watchg: --follow cannot be combined with --equexit' >&2
        return 2
    end

    set -l shotsdir
    if set -q _flag_shotsdir
        set shotsdir $_flag_shotsdir[-1]
        if test -z "$shotsdir"
            echo 'watchg: empty --shotsdir' >&2
            return 2
        end
        if not mkdir -p -- $shotsdir
            echo "watchg: cannot create $shotsdir" >&2
            return 2
        end
    end

    set -l urgency normal
    set -q _flag_urgency; and set urgency $_flag_urgency[-1]
    set -l ucode 1
    switch $urgency
        case low
            set ucode 0
        case normal
            set ucode 1
        case critical
            set ucode 2
        case '*'
            echo "watchg: invalid urgency: $urgency" >&2
            return 2
    end

    set -l occasion always
    set -q _flag_occasion; and set occasion $_flag_occasion[-1]
    if not contains -- $occasion always unfocused invisible
        echo "watchg: invalid occasion: $occasion" >&2
        return 2
    end

    set -l sound silent
    set -q _flag_sound; and set sound $_flag_sound[-1]

    set -l app_name watchg
    set -q _flag_app_name; and set app_name $_flag_app_name[-1]

    set -l title 'watchg: '(basename -- $child[1])
    set -q _flag_title; and set title $_flag_title[-1]

    if test -n "$pattern"
        if not type -q rg
            echo 'watchg: --pattern needs ripgrep (rg)' >&2
            return 2
        end
        # Fail early on a malformed pattern instead of on the first poll.
        rg --pcre2 --text -e $pattern -- /dev/null 2>/dev/null
        if test $status -eq 2
            echo "watchg: invalid PCRE2 pattern: $pattern" >&2
            return 2
        end
    end

    set -l rgflags --pcre2 --text
    set -q _flag_ignore_case; and set -a rgflags --ignore-case
    set -q _flag_invert; and set -a rgflags --invert-match

    set -l notifier auto
    set -q _flag_notifier; and set notifier $_flag_notifier[-1]
    switch $notifier
        case auto
            if test -t 1; and set -q KITTY_WINDOW_ID; and string match -q 'xterm-kitty*' -- "$TERM"
                set notifier kitty
            else if type -q notify-send
                set notifier notify-send
            else
                set notifier none
            end
        case kitty notify-send
        case '*'
            echo "watchg: invalid notifier: $notifier" >&2
            return 2
    end
    if test $notifier = none; and test -n "$pattern"
        echo 'watchg: no notification backend available, matches will not be reported' >&2
    end

    set -l state_dir '/tmp/watchg-'(id -u)
    set -q _flag_state_dir; and set state_dir $_flag_state_dir[-1]
    if not mkdir -p -- $state_dir
        echo "watchg: cannot create state directory: $state_dir" >&2
        return 2
    end
    # Reap scratch directories of runs that were interrupted before they could
    # clean up (an interactive fish never runs cleanup after Ctrl-C). A live run
    # refreshes its `beat` file every update, so only dead ones age out.
    for beat in (find $state_dir -maxdepth 2 -name beat -mmin +60 2>/dev/null)
        rm -rf -- (dirname -- $beat)
    end

    # One watcher per working directory, pattern and command. The lock is a
    # lease: the holder rewrites its deadline every update, so an interrupted or
    # killed run stops holding it after at most one lease, with no cleanup
    # needed and no guessing from process ids.
    set -l lease (math "max(3, $interval + 1)")
    set -l token (string join '' $fish_pid '-' (date +%s%N))
    set -l lock_dir
    if not set -q _flag_no_lock
        set -l hasher
        if type -q sha256sum
            set hasher sha256sum
        else if type -q md5sum
            set hasher md5sum
        end
        if test -z "$hasher"
            echo 'watchg: no sha256sum/md5sum available, running without an instance lock' >&2
        else
            # NUL separated so that argument boundaries are part of the key.
            set -l key (printf '%s\0' "$PWD" "$pattern" $child | $hasher | string sub -l 16)
            set lock_dir $state_dir/lock-$key
            if not mkdir -- $lock_dir 2>/dev/null
                set -l until (cat $lock_dir/until 2>/dev/null | string trim)
                set -l now (date +%s)
                if test -z "$until"
                    # Lock created but its deadline was never written: only trust
                    # the directory's age for that sub-millisecond window.
                    set until (math (stat -c %Y -- $lock_dir 2>/dev/null; or date +%s) + $lease)
                end
                if string match -qr '^[0-9]+(\.[0-9]+)?$' -- "$until"; and test $now -le (math "ceil($until)")
                    echo "watchg: another watcher for this pattern and command is running (its lease lasts another "(math "ceil($until) - $now")"s)" >&2
                    echo "watchg: if that is wrong, remove $lock_dir or pass --no-lock" >&2
                    return 3
                end
                rm -rf -- $lock_dir
                if not mkdir -- $lock_dir
                    echo "watchg: cannot acquire lock $lock_dir" >&2
                    return 3
                end
            end
            printf '%s\n' $token >$lock_dir/token
            set -l now (date +%s)
            printf '%s\n' (math "ceil($now + $lease)") >$lock_dir/until
        end
    end

    set -l scratch (mktemp -d "$state_dir/run.XXXXXX")
    or begin
        echo "watchg: cannot create a scratch directory in $state_dir" >&2
        test -n "$lock_dir"; and rm -rf -- $lock_dir
        return 2
    end
    touch -- $scratch/beat

    set -g __watchg_tui 0
    set -g __watchg_stop 0
    if not set -q _flag_no_tui; and test $quiet = 0; and test $follow = 0; and test -t 1
        set -g __watchg_tui 1
    end

    # Ctrl-C reaches the polled command (same process group) and this shell. A
    # script fish keeps running this function after the signal, so the handler
    # releases the lock and the scratch directory; an interactive fish abandons
    # the function body instead, which is harmless because the lock is a lease
    # that simply expires and the terminal is left in its normal state.
    set -l handler __watchg_cleanup_$fish_pid
    function $handler --on-signal INT --on-signal TERM --on-signal HUP \
            --inherit-variable handler --inherit-variable lock_dir --inherit-variable scratch \
            --inherit-variable token
        set -g __watchg_stop 1
        rm -rf -- $scratch
        set -l holder
        test -n "$lock_dir"; and set holder (cat $lock_dir/token 2>/dev/null | string trim)
        if test -n "$lock_dir"; and test "$holder" = "$token"
            rm -rf -- $lock_dir
        end
        # Do not leave this handler attached to the interactive shell.
        functions -e $handler
    end

    # No alternate screen: fish cannot restore it when an interactive function is
    # interrupted, which would leave the shell drawing into the hidden screen.
    # The view is redrawn in place at the top of the normal screen instead.
    if test "$__watchg_tui" = 1
        printf '\e[H\e[2J'
    end

    set -l tty_dev
    if test -c /dev/tty; and command sh -c 'true >/dev/tty' 2>/dev/null
        set tty_dev /dev/tty
    end

    set -l notify_target
    if test -t 1
        set notify_target /dev/stdout
    else if test -n "$tty_dev"
        set notify_target $tty_dev
    end
    if test -z "$notify_target"; and test $notifier = kitty
        if type -q notify-send
            set notifier notify-send
        else
            echo 'watchg: no terminal for OSC 99 notifications and no notify-send available' >&2
            set notifier none
        end
    end

    set -l ns_print_id 0
    if test $notifier = notify-send
        if notify-send --help 2>&1 | string match -qr -- '--print-id'
            set ns_print_id 1
        end
    end
    set -l notify_id

    # Command output is untrusted: keep only SGR (and not even that with -C).
    # SGR sequences are parked on a placeholder so that every other escape can be
    # dropped without special-casing the CSI final byte.
    set -l scrub \
        -e 's/\x1b\][^\x07\x1b]*\x07//g' \
        -e 's/\x1b\][^\x07\x1b]*\x1b[\x5c]//g' \
        -e 's/\x1bP[^\x1b]*\x1b[\x5c]//g'
    if test $strip_color = 0
        set -a scrub -e 's/\x1b\[\([0-9;?<=>!]*\)m/\x01SGR\1m/g'
    end
    set -a scrub \
        -e 's/\x1b\[[0-9;?<=>!]*[@-~]//g' \
        -e 's/\x1b[()#][0-9A-Za-z]//g' \
        -e 's/\x1b[a-zA-Z]//g' \
        -e 's/\x1b\[//g' \
        -e 's/\x1b//g'
    if test $strip_color = 0
        set -a scrub -e 's/\x01SGR/\x1b[/g'
    end

    set -l esc (printf '\e')
    set -l last_match 0
    set -l notifications 0
    set -l cycle 0
    set -l unchanged 0
    set -l exit_status 0
    # Header and notification text must not carry controls either.
    set -l cmd_label (string replace -ra '[\x00-\x1f\x7f]' ' ' -- (string join ' ' -- $child))

    while test "$__watchg_stop" = 0
        set -l started (date +%s.%N)
        set -l stamp (date '+%Y-%m-%d %H:%M:%S')
        set cycle (math $cycle + 1)
        touch -- $scratch/beat
        if test -n "$lock_dir"
            # Someone with an expired lease may have taken over while we were busy.
            set -l holder (cat $lock_dir/token 2>/dev/null | string trim)
            if not test "$holder" = "$token"
                echo 'watchg: another instance took over the lock, stopping' >&2
                break
            end
            set -l now (date +%s)
            printf '%s\n' (math "ceil($now + $lease)") >$lock_dir/until
        end

        # Run first, draw afterwards: the previous frame stays on screen while a
        # slow command runs, and the new frame can be painted in one atomic batch.
        $child >$scratch/out 2>&1
        set -l cmd_status $status
        if test -n "$lock_dir"
            set -l now2 (date +%s)
            printf '%s\n' (math "ceil($now2 + $lease)") >$lock_dir/until
        end

        if test -e $scratch/out
            env LC_ALL=C sed $scrub <$scratch/out >$scratch/clean
        else
            printf '' >$scratch/clean
        end

        set -l changed 1
        if test -f $scratch/prevout; and cmp -s -- $scratch/clean $scratch/prevout
            set changed 0
        end

        set -l matches
        set -l matching 0
        set -l matcher_error 0
        if test -n "$pattern"; and test -e $scratch/clean
            set matches (rg $rgflags -N --no-heading --color=never -m 7 -e $pattern -- $scratch/clean 2>/dev/null)
            set -l rg_status $status
            if test $rg_status -gt 1
                set matcher_error 1
            else if test $rg_status -eq 0
                set matching 1
            end
        end

        if test "$__watchg_tui" = 1
            set -l dims (stty size 2>/dev/null)
            if test -z "$dims"; and test -n "$tty_dev"
                set dims (stty size <$tty_dev 2>/dev/null)
            end
            set -l rows 24
            set -l cols 80
            if set -q dims[1]
                set -l parts (string split ' ' -- $dims)
                set rows $parts[1]
                if set -q parts[2]
                    set cols $parts[2]
                end
            end
            set -l reserved 5
            test $no_title = 1; and set reserved 2
            set -l show_rows (math "max(1, $rows - $reserved)")

            set -l display_flags --pcre2 --text --passthru --color=always
            test -n "$pattern"; and set -q _flag_ignore_case; and set -a display_flags --ignore-case
            if test -s $scratch/clean
                if test -n "$pattern"
                    tail -n $show_rows -- $scratch/clean | rg $display_flags -e $pattern >$scratch/body
                else
                    tail -n $show_rows -- $scratch/clean >$scratch/body
                end
            else
                printf '' >$scratch/body
            end
            if test $diff_mode = 1; and test -f $scratch/prev
                # Reverse video on lines that appeared or changed since last time.
                set -l fmt (printf '%s[7m%%L%s[0m' $esc $esc)
                diff --old-line-format='' --unchanged-line-format='%L' \
                    --new-line-format="$fmt" -- $scratch/prev $scratch/body >$scratch/frame
            else if test -f $scratch/body
                cp -- $scratch/body $scratch/frame
            end
            test -f $scratch/body; and cp -- $scratch/body $scratch/prev

            # DECSET 2026 (synchronized output): the terminal buffers everything
            # between the two markers and paints one frame, so the redraw is never
            # visible half finished. Terminals without it simply ignore the mode.
            # Lines are overwritten in place (\e[K, \e[J) rather than by clearing
            # the screen first, which is what used to flash a blank frame.
            printf '\e[?2026h\e[H'
            if test $no_title = 0
                set -l shown (string shorten -m (math "max(12, $cols - 34)") -- $cmd_label)
                printf '\e[1mEvery %ss:\e[0m %s    \e[2m%s\e[0m\e[K\n' $interval $shown $stamp
                printf '\e[K\n'
                if test $matcher_error = 1
                    printf '\e[33mmatcher failed\e[0m\e[K'
                else if test -z "$pattern"
                    printf '\e[K'
                else if test $matching = 1
                    set -l shown_count (count $matches)
                    set -l plus ''
                    test $shown_count -ge 7; and set plus '+'
                    printf '\e[31m%s%s matching line(s)\e[0m\e[K' $shown_count $plus
                else
                    printf '\e[2mno match\e[0m\e[K'
                end
                if test $cmd_status -ne 0
                    printf '    \e[33mexit %s\e[0m\e[K' $cmd_status
                end
                printf '\n\e[K\n'
            end
            test $no_wrap = 1; and printf '\e[?7l'
            if test -f $scratch/frame; and test -s $scratch/frame
                awk '{ printf "%s\033[K\n", $0 }' <$scratch/frame
            else
                printf '\e[2m(no output)\e[0m\e[K\n'
            end
            test $no_wrap = 1; and printf '\e[?7h'
            printf '\e[J\e[?2026l'
        else if test $follow = 1
            test $quiet = 0; and cat -- $scratch/clean
        else if test $quiet = 0
            if test -z "$pattern"
                cat -- $scratch/clean
            else if test $matching = 1
                rg $rgflags -N --no-heading --color=never -e $pattern -- $scratch/clean
            end
        end

        if test -n "$shotsdir"; and test $changed = 1
            # mktemp keeps same-second captures from overwriting each other.
            set -l shot (mktemp "$shotsdir/watchg_"(date +%Y%m%d-%H%M%S)".XXXXXX")
            or set shot ''
            if test -n "$shot"
                printf 'Every %ss: %s\n\n' $interval $cmd_label >$shot
                set -l shot_src $scratch/clean
                test -f $scratch/frame; and set shot_src $scratch/frame
                sed -e 's/\x1b\[[0-9;]*[a-zA-Z]//g' <$shot_src >>$shot
            end
        end

        if test $matching = 1; and test $last_match = 0; and test $matcher_error = 0
            # Edge triggered: one notification per transition into a matching state.
            set -l excerpt $matches
            if test $context -gt 0
                # At most three lines each side, so the match itself is always in
                # the excerpt handed to the notification.
                set -l ctx (math "min($context, 3)")
                set -l first_num (string replace -r ':.*' '' -- (rg $rgflags -n -m 1 --no-heading --color=never -e $pattern -- $scratch/clean 2>/dev/null)[1])
                if string match -qr '^[0-9]+$' -- "$first_num"
                    set -l from (math "max(1, $first_num - $ctx)")
                    set -l to (math "$first_num + $ctx")
                    set excerpt (sed -n "$from,"(math $to)"p" -- $scratch/clean)
                end
            end
            set -l body (printf '%s\n' $excerpt[1..7] '' \
                '$ '(string sub -l 200 -- $cmd_label) | string collect -N)
            # OSC 99 wants at most 2048 bytes of payload per chunk, before base64.
            if test (printf '%s' $body | wc -c) -gt 1900
                set body (printf '%s' $body | head -c 1900 | string collect -N)
                if type -q iconv
                    set body (printf '%s' $body | iconv -c -f UTF-8 -t UTF-8 | string collect -N)
                end
            end
            set title (string sub -l 80 -- $title)

            set -l sent 0
            switch $notifier
                case kitty
                    set -l b64_app (string join '' -- (printf '%s' $app_name | base64))
                    set -l b64_sound (string join '' -- (printf '%s' $sound | base64))
                    set -l b64_title (string join '' -- (printf '%s' $title | base64))
                    set -l b64_body (string join '' -- (printf '%s' $body | base64))
                    set -l nid watchg-$fish_pid-(string sub -l 8 -- (date +%s%N))
                    if printf '\e]99;i=%s:a=focus:e=1:u=%s:o=%s:s=%s:f=%s:p=title:d=0;%s\e\\' \
                            $nid $ucode $occasion $b64_sound $b64_app $b64_title >$notify_target 2>/dev/null
                        printf '\e]99;i=%s:a=focus:e=1:f=%s:p=body:d=1;%s\e\\' \
                            $nid $b64_app $b64_body >$notify_target 2>/dev/null
                        and set sent 1
                    end
                case notify-send
                    set -l send_args --app-name=$app_name --urgency=$urgency --icon=utilities-terminal
                    if test $ns_print_id = 1
                        set -a send_args --print-id
                        test -n "$notify_id"; and set -a send_args --replace-id=$notify_id
                        set -l id (notify-send $send_args -- $title $body 2>/dev/null)
                        if string match -qr '^[0-9]+$' -- "$id"
                            set notify_id $id
                            set sent 1
                        end
                    else
                        if notify-send $send_args -- $title $body 2>/dev/null
                            set sent 1
                        end
                    end
            end
            if test $sent = 1
                set notifications (math $notifications + 1)
                set last_match 1
            end
        end
        if test $matching = 0; and test $matcher_error = 0
            set last_match 0
        end

        if test $cmd_status -ne 0
            test $beep = 1; and printf '\a'
            if test $errexit = 1
                set exit_status $cmd_status
                break
            end
        end
        if test $chgexit = 1; and test $cycle -gt 1; and test $changed = 1
            break
        end
        if test $equexit -gt 0
            if test $cycle -gt 1; and test $changed = 0
                set unchanged (math $unchanged + 1)
                test $unchanged -ge $equexit; and break
            else
                set unchanged 0
            end
        end

        test -f $scratch/clean; and cp -- $scratch/clean $scratch/prevout

        set -l slept $interval
        if test $precise = 1
            set slept (math "$interval - ("(date +%s.%N)" - $started)")
        end
        if test $slept -gt 0
            sleep $slept
        end
    end

    functions -e $handler
    if test "$__watchg_tui" = 1
        printf '\e[J\n'
    end
    set -e __watchg_stop __watchg_tui
    rm -rf -- $scratch
    set -l final_holder
    test -n "$lock_dir"; and set final_holder (cat $lock_dir/token 2>/dev/null | string trim)
    if test -n "$lock_dir"; and test "$final_holder" = "$token"
        rm -rf -- $lock_dir
    end
    if test $quiet = 0
        if test $notifications -gt 0
            printf '\nwatchg: stopped after %s notification(s)\n' $notifications >&2
        else
            printf '\nwatchg: stopped\n' >&2
        end
    end
    return $exit_status
end
