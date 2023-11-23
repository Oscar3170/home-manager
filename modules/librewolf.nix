# vim: sw=4
{ home, config, pkgs, ... }:
{
    programs.librewolf = {
        enable = false;
    };

    home.file.".librewolf/librewolf.overrides.cfg".source = ./librewolf/librewolf.overrides.cfg;
}
