{ config, lib, pkgs, ... }:
let
  # Pure (flake) evaluation forbids builtins.currentSystem; derive it from pkgs.
  profilesPath = if pkgs.stdenv.hostPlatform.isDarwin then
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

  # Route external links through a chooser when several LibreWolf profiles are
  # open at once; with one profile open the link goes straight there.
  home.file.".local/bin/librewolf-profile-open.sh" = lib.mkIf pkgs.stdenv.isLinux {
    source = ./librewolf-profile-open.sh;
  };

  xdg.desktopEntries.librewolf-profile-open = lib.mkIf pkgs.stdenv.isLinux {
    name = "LibreWolf Profile Chooser";
    genericName = "Web Browser";
    comment = "Open links in an already-running LibreWolf profile, asking which one when several are open";
    exec = "${config.home.homeDirectory}/.local/bin/librewolf-profile-open.sh %u";
    icon = "librewolf";
    terminal = false;
    noDisplay = true;
    startupNotify = true;
    categories = [ "Network" "WebBrowser" ];
    mimeType = [
      "x-scheme-handler/http"
      "x-scheme-handler/https"
      "text/html"
      "application/xhtml+xml"
      "application/x-extension-burp"
      "x-scheme-handler/jetbrains"
    ];
    settings.StartupWMClass = "librewolf";
  };

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
    "x-scheme-handler/http"         = [ "librewolf-profile-open.desktop" ];
    "x-scheme-handler/https"        = [ "librewolf-profile-open.desktop" ];
    "application/xhtml+xml"         = [ "librewolf-profile-open.desktop" ];
    "text/html"                     = [ "librewolf-profile-open.desktop" ];
    "application/x-extension-burp"  = [ "librewolf-profile-open.desktop" ];
    "x-scheme-handler/jetbrains"    = [ "librewolf-profile-open.desktop" ];
  };
}
