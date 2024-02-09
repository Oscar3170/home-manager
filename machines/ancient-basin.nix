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
    ./../modules/librewolf.nix
    ./../modules/gnome.nix
    ./../modules/podman
    ./ancient-basin.private.nix
  ];
}
