{ home, config, pkgs, ... }:
{
  home.username = "oscar";
  home.homeDirectory = "/home/oscar";

  targets.genericLinux.enable = true;

  imports = [
    ../modules/kubernetes
    ../modules/librewolf
    ../modules/gnome.nix
    ../modules/podman
    ../modules/terraform
  ];

  dconf.settings."org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
    name = "1Password";
    command = "1password --quick-access";
    binding = "<Shift><Alt>z";
  };
}
