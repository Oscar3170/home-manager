{
  description = "Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      hosts = {
        greenpath = {
          system = "x86_64-linux";
          username = "oscar";
        };
        crystal-peaks = {
          system = "x86_64-linux";
          username = "oscar";
        };
        ancient-basin = {
          system = "x86_64-linux";
          username = "oscar";
        };
        "PS-STFA080-00881" = {
          system = "aarch64-darwin";
          username = "oscar";
        };
      };

      hostModule = hostname:
        if builtins.pathExists ./machines/${hostname}.nix
        then ./machines/${hostname}.nix
        else ./machines/default.nix;

    in
    {
      homeConfigurations = nixpkgs.lib.mapAttrs' (hostname: host:
        nixpkgs.lib.nameValuePair "${host.username}@${hostname}" (
          home-manager.lib.homeManagerConfiguration {
            pkgs = import nixpkgs {
              inherit (host) system;
            };
            modules = [
              ({ lib, pkgs, ... }: {
                home.username = lib.mkDefault host.username;
                home.homeDirectory = lib.mkDefault 
                  "${if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home"}/${host.username}"
                ;
              })
              ./home.nix
              (hostModule hostname)
            ];
          }
        )
      ) hosts;
    };
}
