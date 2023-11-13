{ config, pkgs, ... }:
{
    home.username = "oscar";
    home.homeDirectory = "/home/oscar";

    targets.genericLinux.enable = true;
}
