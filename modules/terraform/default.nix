{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [ 
    opentofu
    tofu-ls
  ];

  # programs.fish.shellAbbrs.tf = "tofu";
  home.sessionVariables.TF_LOG = "ERROR";

  xdg.configFile."opentofu/tofurc".source = ./tofurc;

  home.file = {
    ".local/share/terraform/plugin-cache/.keep".text = "";
  };

}
