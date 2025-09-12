{ lib, pkgs, ... }:
{
  #targets.genericLinux.enable = true;

  programs.git = {
    enable = true;
  };

  home.packages = with pkgs; [
    gnumake
    gnugrep
    iproute2mac
    watch
    openconnect
    wget
    nmap
    gnupg

    emacs
    ispell
  ];

  programs.fish.shellAliases = {
      ip = lib.mkForce "/usr/bin/env ip";
      nc = "ncat";
      glab = "op plugin run -- glab";
  };

  # programs.kitty.enable = true;

  home.sessionPath = [
    "$HOME/.local/bin"
    "/opt/homebrew/bin"
  ];

  xdg.mimeApps.defaultApplications = null;

  home.file."Library/LaunchAgents/com.local.KeyRemapping.plist".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.local.KeyRemapping</string>
        <key>ProgramArguments</key>
        <array>
            <string>/usr/bin/hidutil</string>
            <string>property</string>
            <string>--set</string>
            <!-- 
              caps_lock       -> esc
              fn              -> left_control
              right_option    -> fn
              right_command   -> right_option 
            -->
            <string>{"UserKeyMapping":[
                {
                  "HIDKeyboardModifierMappingSrc": 0x700000039,
                  "HIDKeyboardModifierMappingDst": 0x700000029
                },
                {
                  "HIDKeyboardModifierMappingSrc": 0xFF00000003,
                  "HIDKeyboardModifierMappingDst": 0x7000000E0
                },
                {
                  "HIDKeyboardModifierMappingSrc": 0x7000000E6,
                  "HIDKeyboardModifierMappingDst": 0xFF00000003
                },
                {
                  "HIDKeyboardModifierMappingSrc": 0x7000000E7,
                  "HIDKeyboardModifierMappingDst": 0x7000000E6
                }
            ]}</string>
        </array>
        <key>RunAtLoad</key>
        <true/>
    </dict>
    </plist>
  '';

  imports = [
    ../modules/kubernetes
    ../modules/librewolf
    ../modules/terraform
    ./PS-STFA080-00881.private.nix
  ];
}
