function cdp 
    set -l DIRS ~/Documents ~/scripts
    set -l excludes -E '\.terraform' -E '/\.*/' -E '/go/' -E 'teams-for-linux'
    set -l selected (fd .git $DIRS --no-ignore-vcs --glob --hidden --prune -d 3 --follow $excludes | sed -e 's/\.git\///g' | fzf)

    if [ -z $selected ]
        return
    end

    cd $selected
end
