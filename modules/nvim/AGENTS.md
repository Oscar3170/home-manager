# Neovim config

## Querying Neovim help / documentation

The Neovim runtime docs are plain text files under the `doc/` directory of the
Neovim installation. Locate the runtime via the `nvim` binary, e.g.:

```sh
RUNTIME=$(dirname $(dirname $(realpath $(which nvim))))/share/nvim/runtime
```

Then read the relevant help file directly, e.g.:

```sh
rg -n 'wincmd' "$RUNTIME"/doc/windows.txt
sed -n '471,490p'   "$RUNTIME"/doc/windows.txt
```

Common help files: `windows.txt`, `terminal.txt`, `api.txt`, `lua.txt`,
`options.txt`, `autocmd.txt`, `builtin.txt`, `map.txt`, `various.txt`.

Avoid invoking `nvim --headless` with `:help`/`:redir` to dump help text — it's
finicky. Reading the `.txt` source files with `rg`/`sed` is faster and more
reliable.
