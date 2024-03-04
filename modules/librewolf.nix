{ home, config, pkgs, ... }:
{
  programs.librewolf = {
    enable = false;
  };

  home.file.".librewolf/librewolf.overrides.cfg".source = ./librewolf/librewolf.overrides.cfg;

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };
}
