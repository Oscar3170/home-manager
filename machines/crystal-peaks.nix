{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    texliveFull # packages to write latex
  ];

  imports = [
    ../modules/kubernetes
    # ../modules/librewolf
    # ../modules/gnome.nix
    # ../modules/podman
    ../modules/terraform
  ];
}
