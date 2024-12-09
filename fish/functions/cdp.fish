function cdp 
    set -f fd_args --no-ignore-vcs --glob --hidden --prune --follow


    set -q CDP_DEPTH; or set CDP_DEPTH 6
    set -a fd_args --max-depth $CDP_DEPTH

    set -q CDP_EXCLUDES; or set CDP_EXCLUDES '\.terraform' '/\.*/' '/go/' 'teams-for-linux'
    for exclude in $CDP_EXCLUDES
        set -a fd_args -E "$exclude"
    end

    set -q CDP_DIRS; or set CDP_DIRS ~/Documents ~/scripts

    set -f selected (fd .git $CDP_DIRS $fd_args | sed -e 's/\.git\///g' | fzf)

    if [ -z $selected ]
        return
    end

    cd $selected
end
