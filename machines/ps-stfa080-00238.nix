{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;

  dconf.settings = {
    "org/gnome/shell/extensions/dash-to-panel".status-icon-padding = 3;
  };

  imports = [
    ./../modules/kubernetes
    ./../modules/podman
    ./../modules/librewolf
    ./../modules/gnome.nix
    ./ps-stfa080-00238.private.nix
  ];
}
