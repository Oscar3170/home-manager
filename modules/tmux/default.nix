{ ... }:
{
  programs.tmux = {
    enable = true;

    # $TERM inside tmux: programs in panes get tmux's terminfo, never kitty's.
    terminal = "tmux-256color";

    keyMode = "vi";
    prefix = "C-a";
    baseIndex = 1;
    mouse = true;
    focusEvents = true;
    aggressiveResize = true;
    customPaneNavigationAndResize = true;
    resizeAmount = 5;
    historyLimit = 50000;
    clock24 = true;
    reverseSplit = false;
    disableConfirmationPrompt = false;
    escapeTime = 0;
    newSession = false;
    plugins = [ ];
    sensibleOnTop = false;

    secureSocket = true;

    # Everything the Nix options above cannot express (kitty capabilities,
    # styles, extra bindings). Appended after the generated settings.
    extraConfig = builtins.readFile ./tmux.conf;
  };
}
