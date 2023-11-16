{ home, config, pkgs, ... }:
{
    home.username = "oscar";
    home.homeDirectory = "/home/oscar";

    targets.genericLinux.enable = true;

    home.packages = with pkgs; [
        kops
    ];
    imports = [
        ./../modules/kubernetes.nix
        ./../modules/firefox.nix
        # ./nb019021-private.nix
    ];
}
