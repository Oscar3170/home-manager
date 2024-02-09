{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [ docker-compose ];

  home.shellAliases.docker = "podman";
  home.sessionVariables.DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
  home.activation.enablePodmanSocket =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      systemctl=$(PATH=$PATH:/bin:/usr/bin:/sbin:/usr/sbin command -v systemctl)
      $systemctl --user enable --now podman.socket
    '';

  xdg.configFile."containers/containers.conf.d/" = {
    source = ./containers.conf.d;
    recursive = true;
  };

}
