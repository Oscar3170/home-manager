{ home, config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;

    font = {
      size = 11;
      name = "DejaVuSansM Nerd Font Mono";
      package = pkgs.nerd-fonts.blex-mono;
      # name = "BlexMono Nerd Font";
      # package = pkgs.nerd-fonts.dejavu-sans-mono;
    };

    extraConfig = "include ./themes/gruvbox_dark_hard_alt.conf";

    settings = {
      scrollback_lines = 50000;

      background_tint = 5;
      background_opacity = "0.97";
      dynamic_background_opacity = true;

      touch_scroll_multiplier = 6;
      wayland_titlebar_color = "background";

      copy_on_select = true;

      enabled_layouts = "fat:bias=50;full_size=1;mirrored=true,*";

      mark1_background = "red";
      mark2_background = "yellow";
      mark3_background = "green";
    };
    shellIntegration = {
      mode = "no-cursor";
      enableFishIntegration = true;
    };
    keybindings = {
      # Launch windows
      "ctrl+alt+enter" = "launch";
      "ctrl+shift+enter" = "launch --cwd=current";
      "ctrl+shift+n" = "launch --cwd=current --type os-window";

      # Launch tabs
      "ctrl+shift+t" = "launch --type=tab --cwd=current";
      "ctrl+alt+t" = "launch --type=tab";

      # Layouts
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+r" = "start_resizing_window";

      # SSH
      "ctrl+shift+alt+p" = "close_shared_ssh_connections";


      "ctrl+shift+o" = "show_last_visited_command_output";

      "ctrl+shift+m" = "create_marker";
      "ctrl+shift+alt+m" = "remove_marker";
    };
    mouseBindings = {
      # Disable opening of URLs with a plain click
      "left click" = "ungrabbed";

      "ctrl+left press" = "ungrabbed mouse_selection rectangle";
    };
  };

  xdg.configFile."kitty/ssh.conf".source = ./ssh.conf;

  xdg.configFile."kitty/themes" = {
    source = ./themes;
    recursive = true;
  };

  home.sessionVariables.TERMINAL = "kitty";
  programs.fish.shellAliases.ssh = "kitty +kitten ssh";
}
