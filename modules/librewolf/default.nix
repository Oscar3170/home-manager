{ config, lib, pkgs, ... }:
{
  programs.librewolf = {
    enable = false;
  };

  home.file.".librewolf/librewolf.overrides.cfg".source = ./librewolf.overrides.cfg;
  home.file.".librewolf/chrome".source = ./chrome;

  home.activation.librewolfLinkUserChrome =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for profile in $(find "$HOME/.librewolf/" -maxdepth 1 -name "*.default-default"); do
        ln -sfT "$HOME/.librewolf/chrome" "$profile/chrome"
      done
    '';

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/http" = [ "librewolf.desktop" ];
    "application/xhtml+xml" = [ "librewolf.desktop" ];
    "text/html" = [ "librewolf.desktop" ];
    "x-scheme-handler/https" = [ "librewolf.desktop" ];
    "application/x-extension-burp" = [ "librewolf.desktop" ];
    "x-scheme-handler/jetbrains" = [ "librewolf.desktop" ];
  };
}
