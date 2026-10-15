# Home Manager Configuration

Flake-based [Home Manager](https://github.com/nix-community/home-manager) configuration.

One `homeConfiguration` is exposed per machine, keyed as `<username>@<hostname>`.
Each entry in the `hosts` map declares its `system` and `username`.
The per-machine module `machines/<hostname>.nix` (or
`machines/default.nix` when there is none) is selected from the `hosts` map in
`flake.nix`.

# Installation

``` bash
# Link this repository to ~/.config/home-manager
ln -s $PWD ~/.config/home-manager

# Install nix
sh $(curl -L https://nixos.org/nix/install | psub) --daemon   # fish
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon  # bash

# Replace <username> and <hostname> with values from flake.nix.
# Select the host explicitly: auto-detection does not forward feature flags.
nix --extra-experimental-features 'nix-command flakes' run \
  --inputs-from path:. \
  --override-input nixpkgs nixpkgs \
  home-manager#home-manager -- \
  switch -b backup \
  --flake 'path:.#<username>@<hostname>'
```

After activation, `home.nix`  installs a `home-manager` wrapper, so subsequent switches 
can just run `home-manager switch -b backup` from any directory.

# Adding a machine

Add an entry to the `hosts` map in `flake.nix`:

```nix
"<hostname>" = {
  system = "x86_64-linux";
  username = "<username>";
};
```

Create `machines/<hostname>.nix` and, optionally, the matching git-ignored
`machines/<hostname>.private.nix`. The username defaults to the map entry and
the home directory defaults to `/home/<username>` on Linux or `/Users/<username>`
on macOS; machine modules can override these defaults.
