{ config, pkgs, ... }:

{
    home.username = "oscar";
    home.homeDirectory = "/home/oscar";

    targets.genericLinux.enable = true;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "23.05"; 

    home.packages = [
        pkgs.kops
        # pkgs.neovim
        pkgs.poetry
        pkgs.ripgrep

        # # It is sometimes useful to fine-tune packages, for example, by applying
        # # overrides. You can do that directly here, just don't forget the
        # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
        # # fonts?
        # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

        # # You can also create simple shell scripts directly inside your
        # # configuration. For example, this adds a command 'my-hello' to your
        # # environment:
        # (pkgs.writeShellScriptBin "my-hello" ''
        #   echo "Hello, ${config.home.username}!"
        # '')
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    home.file = {
        # # Building this configuration will create a copy of 'dotfiles/screenrc' in
        # # the Nix store. Activating the configuration will then make '~/.screenrc' a
        # # symlink to the Nix store copy.
        # ".screenrc".source = dotfiles/screenrc;

        # # You can also set the file content immediately.
        # ".gradle/gradle.properties".text = ''
        #   org.gradle.console=verbose
        #   org.gradle.daemon.idletimeout=3600000
        # '';
    };

    home.sessionVariables = {
        AWS_SDK_LOAD_CONFIG = "1";
        # AWS_PAGER = ''sh -c 'in=$\$(cat);echo $$in | jq 2> /dev/null || echo $$in' '';
        # AWS_PAGER = "jq -rR 'fromjson? // .'";
        MANPAGER = ''sh -c 'col -bx | bat --pager \"less -RF\" -l man -p' '';
        TERMINAL = "kitty";
        EDITOR = "nvim";
        BROWSER = "librewolf";
        PYENV_ROOT = "$HOME/.pyenv";
        TF_LOG = "ERROR";
    };

    programs.home-manager.enable = true;

    programs.fish = {
        enable = true;

        interactiveShellInit = ''
            type -q pyenv; and pyenv init - | source
            type -q rbenv; and source (rbenv init -|psub)
            '';

        shellAbbrs = {
            tf = "terraform";
            kbat = "bat -plyaml";
            rmr = "rm -r";
            kgs = "kubectl get svc";
            kdp = "kubectl describe pod";
            kgp = "kubectl watch";
            cat = "bat -pp";
            apt = "aptitude";
            k = "kubectl";
        };

        shellAliases = {
            vim = "nvim";
            ssh = "kitty +kitten ssh";
            ls = "exa";
            fd = "fdfind";
            ip = "/usr/bin/ip -c";
            batlog = "bat --color=always --theme=\"Solarized (light)\" -l log --wrap never -pp";
            kctx = "kubectl config use-context";
            kubens = "kubectl config set-context --current --namespace";
            watch-pods = "watch -tcn1 kubectl watch";
        };


        plugins = [
        { name = "tide"; src = pkgs.fishPlugins.tide.src; }
        { name = "foreign-env"; src = pkgs.fishPlugins.foreign-env.src; }
        { name = "done"; src = pkgs.fishPlugins.done.src; }

        { 
            name = "kubectl-completions";
            src = pkgs.fetchFromGitHub {
                owner = "evanlucas";
                repo = "fish-kubectl-completions";
                rev = "ced676392575d618d8b80b3895cdc3159be3f628";
                sha256 = "sha256-OYiYTW+g71vD9NWOcX1i2/TaQfAg+c2dJZ5ohwWSDCc=";
            };
        }
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
}
