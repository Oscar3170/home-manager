{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    jetbrains.pycharm-professional
  ];

  imports = [
    ./../modules/kubernetes
    ./../modules/podman
    ./../modules/librewolf
    ./../modules/gnome.nix
    ./nb019021.private.nix
  ];
}
