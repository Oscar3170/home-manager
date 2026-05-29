{ home, config, pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep

    # go dev
    go
    gopls
    delve

    # python dev
    uv
    basedpyright

    # javascript dev
    typescript
    # vue-language-server
    # vtsls
    typescript-language-server
    # tailwindcss-language-server

    # various language servers
    yaml-language-server
    stylua
    nixd
    lua-language-server

    tree-sitter
  ];

  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withRuby = true;
    withPython3 = true;
  };
}
