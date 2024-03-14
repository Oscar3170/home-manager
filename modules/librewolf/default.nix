{ home, config, pkgs, ... }:
{
  programs.librewolf = {
    enable = false;
  };

  home.file.".librewolf/librewolf.overrides.cfg".source = ./librewolf.overrides.cfg;

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
