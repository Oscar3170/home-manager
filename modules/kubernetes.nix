# vim: sw=4
{ home, config, pkgs, ... }:
{
    home.packages = with pkgs; [
        kubectl
        kubectx
        krew
    ];

    programs.k9s = {
        enable = true;
    };

    home.file.".bin/kubernetes/".source = ./kubernetes/bin;
    home.sessionPath = [
        "$HOME/.bin/kubernetes"
    ];
}
