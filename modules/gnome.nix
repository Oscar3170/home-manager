{ lib, ... }:

with lib.hm.gvariant;
{
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      current = mkUint32 0;
      per-window = false;
      show-all-sources = false;
      sources = [ (mkTuple [ "xkb" "us+altgr-intl" ]) ];
      xkb-options = [ "caps:escape" "terminate:ctrl_alt_bksp" "shift:both_capslock" "apple:alupckeys" ];
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      delay = mkUint32 300;
      numlock-state = true;
      repeat-interval = mkUint32 25;
    };

    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "default";
      speed = 2.4793388429751984e-2;
    };

    "org/gnome/desktop/peripherals/touchpad" = {
      natural-scroll = false;
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      disable-while-typing = true;
    };

    "org/gnome/desktop/wm/preferences" = {
      action-middle-click-titlebar = "minimize";
      auto-raise = true;
      button-layout = "icon:minimize,maximize,close";
      mouse-button-modifier = "<Alt>";
      resize-with-right-button = true;
      visual-bell = false;
      visual-bell-type = "frame-flash";
    };

    "org/gnome/desktop/search-providers" = {
      sort-order = [ "org.gnome.Contacts.desktop" "org.gnome.Documents.desktop" "org.gnome.Nautilus.desktop" ];
    };

    "org/gnome/terminal/legacy" = {
      theme-variant = "dark";
    };


    # Keybindings
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [ "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" ];
      home = [ "<Super>e" ];
      mic-mute = [ "F3" ];
    };

    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Super>t";
      command = "kitty";
      name = "Terminal";
    };

    # Extensions
    "org/gnome/shell/extensions/clipboard-history" = {
      cache-only-favorites = true;
      disable-down-arrow = true;
      history-size = 30;
      private-mode = false;
      strip-text = true;
      window-width-percentage = 33;
    };

    "org/gnome/shell/extensions/dash-to-dock-pop" = {
      background-opacity = 0.8;
      border-radius = 42;
      dash-max-icon-size = 48;
      disable-overview-on-startup = true;
      dock-alignment = "CENTRE";
      dock-position = "BOTTOM";
      floating-margin = 4;
      force-straight-corner = false;
      height-fraction = 0.9;
      hot-keys = false;
      intellihide-mode = "ALL_WINDOWS";
      multi-monitor = true;
      preferred-monitor = -2;
      preferred-monitor-by-connector = "DP-1";
      running-indicator-style = "DOTS";
      show-mounts = false;
      show-trash = false;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      apply-custom-theme = true;
      background-opacity = 0.8;
      dash-max-icon-size = 48;
      dock-position = "BOTTOM";
      height-fraction = 1.0;
      hot-keys = false;
      intellihide = false;
      intellihide-mode = "FOCUS_APPLICATION_WINDOWS";
      multi-monitor = false;
      preferred-monitor = -2;
      preferred-monitor-by-connector = "DP-1";
      pressure-threshold = 50.0;
      preview-size-scale = 0.4;
      require-pressure-to-show = true;
      scroll-to-focused-application = false;
      show-favorites = true;
      show-mounts = false;
      show-mounts-only-mounted = false;
      show-show-apps-button = false;
      show-trash = false;
    };

    "org/gnome/shell/extensions/dash-to-panel" = {
      animate-appicon-hover-animation-extent = "{'RIPPLE': 4, 'PLANK': 4, 'SIMPLE': 1}";
      appicon-margin = 8;
      appicon-padding = 4;
      available-monitors = [ 1 0 ];
      dot-position = "BOTTOM";
      hide-overview-on-startup = true;
      hotkeys-overlay-combo = "TEMPORARILY";
      intellihide = false;
      leftbox-padding = -1;
      multi-monitors = false;
      panel-anchors = ''
        {"0":"MIDDLE","1":"MIDDLE"}
      '';
      panel-element-positions = ''
        {"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}],"1":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"dateMenu","visible":true,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":false,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":false,"position":"stackedBR"}]}
      '';
      panel-lengths = ''
        {"0":100,"1":100}
      '';
      panel-positions = ''
        {"0":"LEFT","1":"LEFT"}
      '';
      panel-sizes = ''
        {"0":54,"1":54}
      '';
      primary-monitor = 1;
      progress-show-count = false;
      scroll-panel-action = "NOTHING";
      show-appmenu = false;
      show-apps-icon-file = "";
      show-favorites = false;
      show-running-apps = false;
      show-tooltip = false;
      show-window-previews = false;
      status-icon-padding = -1;
      stockgs-keep-dash = true;
      stockgs-panelbtn-click-only = true;
      trans-use-custom-bg = false;
      trans-use-custom-gradient = false;
      tray-padding = -1;
      window-preview-title-position = "TOP";
    };

    "org/gnome/shell/extensions/date-menu-formatter" = {
      custom-locale = "pt-BR";
      font-size = 10;
      pattern = "dd/MM \\nkk : mm";
      use-default-locale = false;
    };

    "org/gnome/shell/extensions/tiling-assistant" = {
      activate-layout0 = [ ];
      activate-layout1 = [ ];
      activate-layout2 = [ ];
      activate-layout3 = [ ];
      active-window-hint = 1;
      active-window-hint-color = "rgb(53,132,228)";
      auto-tile = [ ];
      center-window = [ ];
      debugging-free-rects = [ ];
      debugging-show-tiled-rects = [ ];
      default-move-mode = 1;
      dynamic-keybinding-behaviour = 2;
      enable-advanced-experimental-features = true;
      enable-raise-tile-group = false;
      enable-tiling-popup = false;
      ignore-ta-mod = 0;
      import-layout-examples = false;
      last-version-installed = 45;
      move-adaptive-tiling-mod = 2;
      move-favorite-layout-mod = 0;
      overridden-settings = "{'org.gnome.mutter.edge-tiling': <false>}";
      restore-window = [ "<Control><Super>Down" ];
      search-popup-layout = [ ];
      tile-bottom-half = [ "<Super>Down" ];
      tile-bottom-half-ignore-ta = [ ];
      tile-bottomleft-quarter = [ "<Super>KP_1" ];
      tile-bottomleft-quarter-ignore-ta = [ ];
      tile-bottomright-quarter = [ "<Super>KP_3" ];
      tile-bottomright-quarter-ignore-ta = [ ];
      tile-edit-mode = [ "<Control><Super>w" ];
      tile-left-half = [ "<Super>Left" "<Super>KP_4" ];
      tile-left-half-ignore-ta = [ ];
      tile-maximize = [ "<Control><Super>Up" ];
      tile-maximize-horizontally = [ ];
      tile-maximize-vertically = [ ];
      tile-right-half = [ "<Super>Right" "<Super>KP_6" ];
      tile-right-half-ignore-ta = [ ];
      tile-top-half = [ "<Super>Up" ];
      tile-top-half-ignore-ta = [ ];
      tile-topleft-quarter = [ "<Super>KP_7" ];
      tile-topleft-quarter-ignore-ta = [ ];
      tile-topright-quarter = [ "<Super>KP_9" ];
      tile-topright-quarter-ignore-ta = [ ];
      tiling-popup-all-workspace = true;
      toggle-always-on-top = [ ];
      toggle-tiling-popup = [ ];
    };
  };
}
