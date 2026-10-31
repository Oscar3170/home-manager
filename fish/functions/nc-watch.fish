function nc-watch --wraps=nc --description 'Poll a TCP port with nc and report reachability'
    argparse --name=nc-watch 'w/timeout=+' 'i/interval=+' 'h/help' -- $argv
    or return 2

    if set -q _flag_help
        printf '%s\n' \
            'nc-watch - poll HOST:PORT with nc, printing SUCCESS or FAILURE' \
            '' \
            'Usage:' \
            '  nc-watch [-w SECONDS] [-i SECONDS] HOST PORT' \
            '' \
            'Options:' \
            '  -w, --timeout SECONDS   nc connection timeout (default: 2)' \
            '  -i, --interval SECONDS  Seconds between attempts (default: 5)' \
            '  -h, --help              Show this help'
        return 0
    end

    if test (count $argv) -ne 2
        echo 'nc-watch: expected HOST and PORT' >&2
        return 2
    end

    set -l host $argv[1]
    set -l port $argv[2]

    set -l timeout 2
    set -q _flag_timeout; and set timeout $_flag_timeout[-1]
    if not string match -qr '^[0-9]+$' -- $timeout; or test $timeout -lt 1
        echo "nc-watch: invalid timeout: $timeout" >&2
        return 2
    end

    set -l interval 5
    set -q _flag_interval; and set interval $_flag_interval[-1]
    if not string match -qr '^[0-9]+(\.[0-9]+)?$' -- $interval; or not test $interval -gt 0
        echo "nc-watch: invalid interval: $interval" >&2
        return 2
    end

    if test -z "$host"
        echo 'nc-watch: empty HOST' >&2
        return 2
    end

    while true
        set -l out (nc -nvzw$timeout $host $port 2>&1)
        set -l nc_status $status
        if test $nc_status -eq 0
            printf '%s - %sSUCCESS%s\n' (date '+%H:%M:%S') (set_color green) (set_color normal)
        else
            # nc -v reports the version banner on every run, drop those lines.
            set -l reason (string join ' ' -- (string match -rv 'Version' -- $out))
            printf '%s - %sFAILURE%s - %s\n' (date '+%H:%M:%S') (set_color red) (set_color normal) $reason
        end
        sleep $interval
    end
end
