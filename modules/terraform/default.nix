{ config, lib, pkgs, ... }:
{
  home.packages = with pkgs; [ 
    opentofu
    terraform-ls
  ];

  programs.fish.shellAbbrs.tf = "tofu";

  xdg.configFile."opentofu/tofurc".source = ./tofurc;

  home.file = {
    ".local/share/terraform/plugin-cache/.keep".text = "";
    ".local/bin/terraform".source = "${pkgs.opentofu}/bin/tofu";
  };

}
