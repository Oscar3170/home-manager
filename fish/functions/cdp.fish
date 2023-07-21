function cdp 
    set -l DIRS ~/Documents/datalake ~/Documents/k8s/ ~/Documents/terraform/ ~/Documents/clientarea/ ~/Documents/git/ ~/.config/nvim
    set -l selected (fd .git $DIRS --no-ignore-vcs --glob --hidden --exclude '\.terraform' --follow | sed -e 's/\.git\///g' | fzf)

    if [ -z $selected ]
        return
    end

    cd $selected
end
