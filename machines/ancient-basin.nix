{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    kops
  ];
  imports = [
    ./../modules/kubernetes
    ./../modules/librewolf
    ./../modules/gnome.nix
    ./../modules/podman
    ./ancient-basin.private.nix
  ];
}
