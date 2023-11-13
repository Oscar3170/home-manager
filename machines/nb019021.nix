{ home, config, pkgs, ... }:
{
    home.username = "oscar";
    home.homeDirectory = "/home/oscar";

    targets.genericLinux.enable = true;
    # imports = [
    #     ./common.nix
    #     # ./nb019021-private.nix
    # ];
}
