{ config, lib, pkgs, ... }:
let
  profilesPath = if builtins.currentSystem == "aarch64-darwin" then
    "$HOME/Library/Application Support/librewolf/Profiles/"
  else
    "$HOME/.librewolf/";
in
{
  programs.librewolf = {
    enable = false;
  };

  home.file.".librewolf/librewolf.overrides.cfg".source = ./librewolf.overrides.cfg;
  home.file.".librewolf/chrome".source = ./chrome;

  home.activation.librewolfLinkUserChrome =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      find "${profilesPath}" -maxdepth 2 -name storage.sqlite -print0 |
        while IFS= read -r -d "" db; do
          ln -sfT "$HOME/.librewolf/chrome" "''${db%/storage.sqlite}/chrome"
        done
    '';

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  xdg.mimeApps.defaultApplications = lib.mkDefault {
    "x-scheme-handler/http" = [ "librewolf.desktop" ];
    "application/xhtml+xml" = [ "librewolf.desktop" ];
    "text/html" = [ "librewolf.desktop" ];
    "x-scheme-handler/https" = [ "librewolf.desktop" ];
    "application/x-extension-burp" = [ "librewolf.desktop" ];
    "x-scheme-handler/jetbrains" = [ "librewolf.desktop" ];
  };
}
