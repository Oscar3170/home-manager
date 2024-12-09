{ lib, pkgs, ... }:
{
  #targets.genericLinux.enable = true;

  programs.git = {
    enable = true;
  };

  home.packages = with pkgs; [
    gnumake
    gnugrep
    darwin.iproute2mac
    watch
    openconnect
    wget
    nmap
    gnupg

    emacs
    ispell
  ];

  programs.fish.shellAliases = {
      ip = lib.mkForce "/usr/bin/env ip";
      nc = "ncat";
  };

  # programs.kitty.enable = true;

  home.sessionPath = [
    "$HOME/.local/bin"
    "/opt/homebrew/bin"
  ];

  xdg.mimeApps.defaultApplications = null;

  imports = [
    ../modules/kubernetes
    ../modules/librewolf
    ../modules/terraform
    ./PS-STFA080-00881.private.nix
  ];
}
