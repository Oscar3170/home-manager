{ config, lib, pkgs, ... }:

let
  # Pure (flake) evaluation forbids builtins.currentSystem; derive it from pkgs.
  isLinux = pkgs.stdenv.hostPlatform.isLinux;

  homeManagerWrapper = pkgs.writeScriptBin "home-manager" (lib.replaceStrings
    [ "#!/usr/bin/env bash" "@home-manager@" "@realpath@" ]
    [ "#!${pkgs.bash}/bin/bash" "${config.programs.home-manager.package}" "${pkgs.coreutils}/bin/realpath" ]
    (builtins.readFile ./scripts/home-manager.sh));
in
{
  # Per-machine configuration (home.username, home.homeDirectory, module
  # imports) is selected by hostname in flake.nix and passed in as an extra
  # module.

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

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    # Use the wrapper even when the Nix profile precedes ~/.local/bin in PATH.
    (lib.hiPrio homeManagerWrapper)

    nerd-fonts.dejavu-sans-mono   
    pkgs.nerd-fonts.blex-mono

    pre-commit
    direnv

    opencode
    pi-coding-agent

    bat
    fd
    ripgrep
    fzf
    jq
    yq-go
    btop

    httpie
    jrnl

    awscli2

    glab

    bun
    pnpm
  ];

  home.sessionVariables = {
    NIX_PATH = "$HOME/.nix-defexpr/channels:$HOME/.nix-defexpr/channels_root";
    AWS_SDK_LOAD_CONFIG = "1";
    PYENV_ROOT = "$HOME/.pyenv";
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

    settings = {
      user = {
        name = "Oscar Lenzi";
      };
      alias = {
        s = "status";
        d = "diff";
      };

      pull = {
        rebase = true;
      };
      push = {
        autoSetupRemote = true;
      };
      init = {
        defaultBranch = "main";
      };

      core = {
        hooksPath = "/dev/null";
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
    };

    shellAliases = {
      ls = "eza";
      ip = "/usr/bin/env ip -c";
      batlog = "bat --color=always --theme=\"Solarized (light)\" -l log --wrap never -pp";
      kctx = "kubectl config use-context";
      kubens = "kubectl config set-context --current --namespace";
      watch-pods = "watch -tcn1 kubectl watch";
      vimmd = "vim -c 'set spell ft=markdown spelllang=pt_br'";
    };


    plugins = [
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
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

  home.file.".ideavimrc".source = ./.ideavimrc;

  programs.eza = {
    enable = true;
    git = true;
  };
}

