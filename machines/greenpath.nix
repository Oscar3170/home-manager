{ home, config, pkgs, ... }:
{
  targets.genericLinux.enable = true;


  home.packages = with pkgs; [
    google-cloud-sdk
    postgresql
  ];

  home.sessionVariables = {
    CDP_DEPTH = "7";
  };

  imports = [
    ../modules/nvim
    ../modules/kitty
    ../modules/kubernetes
    ../modules/librewolf
    ../modules/gnome.nix
    ../modules/podman
    ../modules/terraform
  ] ++ (
    # Private per-machine config is git-ignored on purpose. Note that git-based
    # flake refs only see git-tracked files, so it would be silently missing
    # from the flake source even when present on disk.
    if builtins.pathExists ./greenpath.private.nix
    then [ ./greenpath.private.nix ]
    else throw ''
      machines/greenpath.private.nix is not present in the flake source.
      If the file exists on disk: git-based flake refs (plain `home-manager
      switch`) hide git-ignored files. Either apply with
        home-manager switch -b backup --flake path:.
      or expose the file to git with
        git add -f machines/greenpath.private.nix
      Otherwise, create machines/greenpath.private.nix on this machine first.
    ''
  );
}
