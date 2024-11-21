{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;

  imports = [
    ./../modules/kubernetes
    ./../modules/librewolf
    ./../modules/gnome.nix
    ./../modules/podman
  ];
}
