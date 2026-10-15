{ home, config, pkgs, ... }:
{
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    kops
  ];
  imports = [
    ./../modules/kubernetes
    ./../modules/librewolf
    ./../modules/gnome.nix
    ./../modules/podman
  ] ++ (
    # Private per-machine config is git-ignored on purpose. Note that git-based
    # flake refs only see git-tracked files, so it would be silently missing
    # from the flake source even when present on disk.
    if builtins.pathExists ./ancient-basin.private.nix
    then [ ./ancient-basin.private.nix ]
    else throw ''
      machines/ancient-basin.private.nix is not present in the flake source.
      If the file exists on disk: git-based flake refs (plain `home-manager
      switch`) hide git-ignored files. Either apply with
        home-manager switch -b backup --flake path:.
      or expose the file to git with
        git add -f machines/ancient-basin.private.nix
      Otherwise, create machines/ancient-basin.private.nix on this machine first.
    ''
  );
}
