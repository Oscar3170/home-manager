# vim: sw=4
{ config, home, pkgs, ... }:

let
    hostname = builtins.replaceStrings ["\n"] [""] (builtins.readFile /etc/hostname);
    machine_config = if builtins.pathExists ./machines/${hostname}.nix then ./machines/${hostname}.nix else ./machines/default.nix;
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

    home.keyboard = {
        layout = "us";
        model = "pc105";
        variant = "altgr-intl";
        options = ["caps:escape" "terminate:ctrl_alt_bksp" "shift:both_capslock" "apple:alupckeys"];
    };

    home.packages = with pkgs; [
        kops

        bat
        eza
        fd
        ripgrep

        # go development
        delve
        gopls

        poetry
        pyright

        terraform-lsp

        nil # nix lsp server

        lua-language-server

        (nerdfonts.override { fonts = [ "DejaVuSansMono" ]; })

        # # You can also create simple shell scripts directly inside your
        # # configuration. For example, this adds a command 'my-hello' to your
        # # environment:
        # (pkgs.writeShellScriptBin "my-hello" ''
        #   echo "Hello, ${config.home.username}!"
        # '')
      ];

    home.sessionVariables = {
        NIX_PATH = "$HOME/.nix-defexpr/channels:$HOME/.nix-defexpr/channels_root";
        AWS_SDK_LOAD_CONFIG = "1";
        # AWS_PAGER = ''sh -c 'in=$\$(cat);echo $$in | jq 2> /dev/null || echo $$in' '';
        # AWS_PAGER = "jq -rR 'fromjson? // .'";
        MANPAGER = "bat -l man -p";
        TERMINAL = "kitty";
        EDITOR = "nvim";
        BROWSER = "librewolf";
        PYENV_ROOT = "$HOME/.pyenv";
        TF_LOG = "ERROR";
        DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
    };

    programs.home-manager.enable = true;

    programs.fish = {
        enable = true;

        interactiveShellInit = ''
            type -q pyenv; and pyenv init - | source
            type -q rbenv; and source (rbenv init -|psub)

            set -x AWS_PAGER 'sh -c \'in=$(cat);echo $in | jq 2> /dev/null || echo $in\' '
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
            ls = "eza";
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

    home.file.".local/bin/".source = ./.local/bin;
}
