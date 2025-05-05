{ config, lib, pkgs, ... }:

let
  hostname = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname);
  machine_config = if builtins.pathExists ./machines/${hostname}.nix then ./machines/${hostname}.nix else ./machines/default.nix;
  isLinux = builtins.match ".*-linux" builtins.currentSystem == [ ];
in
{
  imports = [
    machine_config
  ];

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05";

  xdg.enable = isLinux;
  xdg.mime.enable = isLinux;
  xdg.mimeApps.enable = isLinux;

  home.packages = with pkgs; [
    nerd-fonts.dejavu-sans-mono   

    pre-commit
    direnv

    # noisetorch
    bat
    fd
    ripgrep
    fzf
    jq
    yq-go
    btop

    httpie
    jrnl

    # go development
    go
    gopls
    delve

    uv
    poetry
    pyright

    dotnet-sdk_8
    omnisharp-roslyn

    awscli2

    yaml-language-server

    stylua

    nixd

    glab

    lua-language-server
    vue-language-server
    typescript
    typescript-language-server
    tailwindcss-language-server

    bun
  ];

  home.sessionVariables = {
    NIX_PATH = "$HOME/.nix-defexpr/channels:$HOME/.nix-defexpr/channels_root";
    AWS_SDK_LOAD_CONFIG = "1";
    TERMINAL = "kitty";
    EDITOR = "nvim";
    BROWSER = "librewolf";
    PYENV_ROOT = "$HOME/.pyenv";
    TF_LOG = "ERROR";
    DOTNET_CLI_TELEMETRY_OPTOUT = "true";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  pam.sessionVariables = config.home.sessionVariables // {
    LANGUAGE = "en_US:en";
    LANG = "en_US.UTF-8";
  };

  programs.home-manager.enable = true;

  xdg.configFile."nix/nix.conf" = {
    text = ''
      experimental-features = nix-command flakes
    '';
  };

  programs.git = {
    enable = true;

    userName = "Oscar Lenzi";

    aliases = {
      s = "status";
      d = "diff";
    };

    extraConfig = {
      pull = {
        rebase = true;
      };
      push = {
        autoSetupRemote = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.man = {
    enable = true;
    generateCaches = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      type -q pyenv; and pyenv init - | source
      type -q rbenv; and source (rbenv init -|psub)

      set -x AWS_PAGER 'sh -c \'in=$(cat);echo $in | jq 2> /dev/null || echo $in\' '
      set -x MANPAGER 'sh -c \'sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | bat --language man --plain\' '
    '';

    shellAbbrs = {
      kbat = "bat -plyaml";
      rmr = "rm -r";
      cat = "bat -pp";
      apt = "aptitude";
    };

    shellAliases = {
      vim = "nvim";
      ssh = "kitty +kitten ssh";
      ls = "eza";
      ip = "/usr/bin/env ip -c";
      batlog = "bat --color=always --theme=\"Solarized (light)\" -l log --wrap never -pp";
      kctx = "kubectl config use-context";
      kubens = "kubectl config set-context --current --namespace";
      watch-pods = "watch -tcn1 kubectl watch";
    };


    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
      { name = "foreign-env"; src = pkgs.fishPlugins.foreign-env.src; }
      { name = "done"; src = pkgs.fishPlugins.done.src; }
    ];
  };

  xdg.configFile."fish/functions" = {
    source = ./fish/functions;
    recursive = true;
  };
  xdg.configFile."fish/completions" = {
    source = ./fish/completions;
    recursive = true;
  };

  xdg.configFile."kitty" = {
    source = ./kitty;
    recursive = true;
  };

  programs.kitty = {
    enable = false;

    font = {
      size = 11;
      name = "DejaVuSansMono";
      package = (pkgs.nerdfonts.override { fonts = [ "DejaVuSansMono" ]; });
    };
    settings = {
      "scrollback_lines" = 50000;

      "background_tint" = 5;
      "background_opacity" = "0.97";
      "dynamic_background_opacity" = true;

      "touch_scroll_multiplier" = 6;
      "linux_display_manager" = "wayland";
      "wayland_titlebar_color" = "background";
    };
    shellIntegration = {
      mode = "no-cursor";
      enableFishIntegration = true;
    };
    keybindings = {
      "ctrl+alt+enter" = "launch";
      "ctrl+shift+enter" = "launch --cwd=current";
      "ctrl+shift+n" = "launch --cwd=current --type os-window";

      # Layouts
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+r" = "start_resizing_window";

      # SSH
      "ctrl+shift+alt+p" = "close_shared_ssh_connections";
    };
  };


  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  home.file.".ideavimrc".source = ./.ideavimrc;

  programs.eza = {
    enable = true;
    git = true;
  };
}

