{ home, config, pkgs, ... }:
{
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    texliveFull # packages to write latex
  ];

  imports = [
    ../modules/nvim
    ../modules/kitty
    ../modules/kubernetes
    # ../modules/librewolf
    # ../modules/gnome.nix
    # ../modules/podman
    ../modules/terraform
  ];
}
