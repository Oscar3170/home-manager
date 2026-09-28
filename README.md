# Home Manager Configuration



Applying the configuration:
```bash
home-manager switch -b backup
```

# Installation

``` bash
# Link this repository to ~/.config/home-manager
ln -s $PWD ~/.config/home-manager

# Install nix
sh $(curl -L https://nixos.org/nix/install | psub) --daemon   # fish
curl -L https://nixos.org/nix/install | sh -s -- --no-daemon  # bash


# Install home-manager
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# Run home-manager config
fish -c 'home-manager switch'
```
