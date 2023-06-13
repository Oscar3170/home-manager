function ssh-ec2 --wraps=ssh
    set -f SSH_CMD kitty +kitten ssh

    set -f CMD_OPTIONS (_get_ssh_options) 'h/help' 'sudo'

    set -f ssh_args $argv

    set -l _argparse_args --ignore-unknown --min-args 1 --name="ssh-ec2" $CMD_OPTIONS
    if ! set -l cmd_sep (contains -i -- -- $argv)
        set -p _argparse_args --max-args 1
    end

    argparse $_argparse_args -- $argv
    or return 1

    if set -ql _flag_help
        $SSH_CMD --help
        return 0
    end

    for i in (seq 1 (count $ssh_args))
        set arg $ssh_args[$i]
        #echo arg: $arg
        if string match -q -r '^x.+@i-[0-9a-f]{17}$' "x$arg"
            set -f user (string split @ "$arg")[1]
            set -f instance_id (string split @ "$arg")[2]
            set -a to_delete ssh_args[$i]
            break
        else if string match -q -r '^xi-[0-9a-f]{17}$' "x$arg"
            set -f instance_id "$arg"
            set -a to_delete ssh_args[$i]
            break
        else if test "x--" = "x$arg"
            echo "error: couldn't find an instance id before the -- argument"
            return 1
        end
    end
    if test -z "$instance_id"
        echo "error: couldn't find an instance id in args"
        return 1
    end
    set -e $to_delete
    #echo user:        $user
    #echo instance id: $instance_id

    if set -ql _flag_sudo
        if test -n "$cmd_sep"
            echo 'error: --sudo can only be used if no command is specified'
            return 1
        end

        set -e ssh_args[(contains -i -- --sudo $ssh_args)]
        if set -l _tty_flag_index (contains -i -- -t $ssh_args || contains -i -- --tty $ssh_args)
            set -e ssh_args[$_tty_flag_index]
        end

        set -fa ssh_args -t -- 'sudo cp -rf $HOME/.terminfo /root/.terminfo; sudo su -'
    end


    set ip (aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[].Instances[].PrivateIpAddress' --output text)
    set -p ssh_args (string join @ $user $ip)
    #echo kitty +kitten ssh -o StrictHostKeyChecking=off  $ssh_args
    $SSH_CMD -o StrictHostKeyChecking=off  $ssh_args
end


function _get_ssh_options
    if ! set -q SSH_CMD
        set -f SSH_CMD ssh
    end

    set -l raw_options ($SSH_CMD --help 2>&1 | grep -oP '((?<=\[-)\w(?= ))|((?<=\[-)(\w)+(?=\]))')
    set -l value_options (printf '%s\n' $raw_options | grep -P '^\w$' | sed -E -e 's/^(\w)$/\1=/g')
    set -l flag_options (printf '%s\n' $raw_options | grep -Pv '^\w$' | string split '')

    printf '%s\n' $value_options $flag_options
end
