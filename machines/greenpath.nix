{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;


  home.packages = with pkgs; [
    google-cloud-sdk
    postgresql
  ];

  home.sessionVariables = {
    CDP_DEPTH = "7";
  };

  imports = [
    ../modules/nvim
    ../modules/kitty
    ../modules/kubernetes
    ../modules/librewolf
    ../modules/gnome.nix
    ../modules/podman
    ../modules/terraform
    ./greenpath.private.nix
  ];
}
