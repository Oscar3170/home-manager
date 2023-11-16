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

## Librewolf
TODO: add to script
``` bash
ln -s ~/.mozilla/native-messaging-hosts ~/.librewolf/native-messaging-hosts
sudo ln -s /usr/lib/mozilla/native-messaging-hosts /usr/lib/librewolf/native-messaging-hosts
```



