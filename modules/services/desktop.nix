{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  fcitx5Rime = pkgs.fcitx5-rime.override {
    rimeDataPkgs = with pkgs; [
      rime-data
      rime-ice
    ];
  };

  fcitx5ClassicUi = pkgs.writeText "zeus-fcitx5-classicui.conf" ''
    Theme=mellow-youlan
    Font="LXGW WenKai Screen 14"
    MenuFont="LXGW WenKai Screen 14"
    TrayFont="LXGW WenKai Screen 11"
    UseInputMethodLangaugeToDisplayText=True
  '';

  rimeDefaultCustom = pkgs.writeText "zeus-rime-default.custom.yaml" ''
    patch:
      schema_list:
        - schema: rime_ice
      menu/page_size: 9
      "key_binder/bindings/+":
        - { when: always, toggle: ascii_mode, accept: Control+space }
  '';

  clipboardBridge = pkgs.writeShellScript "zeus-clipboard-bridge.sh" ''
    #!/usr/bin/env bash
    set -eu

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export XDG_RUNTIME_DIR="$runtime_dir"
    export DISPLAY="''${DISPLAY:-:0}"

    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      attempt=0
      while [ "$attempt" -lt 10 ]; do
        for socket in "$runtime_dir"/wayland-*; do
          if [ -S "$socket" ]; then
            export WAYLAND_DISPLAY="$(basename "$socket")"
            break 2
          fi
        done
        attempt=$((attempt + 1))
        ${pkgs.coreutils}/bin/sleep 1
      done
    fi

    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      echo "clipboard bridge: unable to find WAYLAND_DISPLAY in $runtime_dir" >&2
      exit 1
    fi

    state_dir="$runtime_dir/clipboard-bridge"
    mkdir -p "$state_dir"

    wl_state="$state_dir/wayland"
    x_state="$state_dir/x11"

    sync_wl_to_x() {
      local tmp
      tmp="$(mktemp "$state_dir/wl.XXXXXX")"
      cat >"$tmp"

      if [ -f "$wl_state" ] && cmp -s "$tmp" "$wl_state"; then
        rm -f "$tmp"
        return 0
      fi

      cp "$tmp" "$wl_state"

      if [ -f "$x_state" ] && cmp -s "$tmp" "$x_state"; then
        rm -f "$tmp"
        return 0
      fi

      ${pkgs.xsel}/bin/xsel -ib <"$tmp" || true
      cp "$tmp" "$x_state"
      rm -f "$tmp"
    }

    sync_x_to_wl() {
      while true; do
        ${pkgs.clipnotify}/bin/clipnotify

        local tmp
        tmp="$(mktemp "$state_dir/x.XXXXXX")"

        if ! ${pkgs.xsel}/bin/xsel -ob >"$tmp" 2>/dev/null; then
          rm -f "$tmp"
          continue
        fi

        if [ -f "$x_state" ] && cmp -s "$tmp" "$x_state"; then
          rm -f "$tmp"
          continue
        fi

        cp "$tmp" "$x_state"

        if [ -f "$wl_state" ] && cmp -s "$tmp" "$wl_state"; then
          rm -f "$tmp"
          continue
        fi

        ${pkgs.wl-clipboard}/bin/wl-copy <"$tmp" || true
        cp "$tmp" "$wl_state"
        rm -f "$tmp"
      done
    }

    case "''${1:-}" in
      wl-to-x)
        sync_wl_to_x
        ;;
      *)
        sync_x_to_wl &
        exec ${pkgs.wl-clipboard}/bin/wl-paste --watch "$0" wl-to-x
        ;;
    esac
  '';

  niriConfig = ./niri-config.kdl;
  wallpaperImage = ../../assets/wallpapers/sunlight-beams-wallpaper-3840x2160-magical-woods-forest-magic-29641.jpg;
  wallpaperPath = toString wallpaperImage;
  noctaliaSettingsSeed = pkgs.writeText "zeus-noctalia-settings.json" (builtins.toJSON {
    general = {
      enableBlurBehind = true;
      showChangelogOnStartup = false;
    };
    ui = {
      panelBackgroundOpacity = 0.9;
      translucentWidgets = true;
    };
    bar = {
      barType = "floating";
      position = "top";
      backgroundOpacity = 0.88;
      useSeparateOpacity = false;
      showCapsule = true;
      capsuleOpacity = 0.82;
      marginVertical = 6;
      marginHorizontal = 6;
      frameThickness = 8;
      frameRadius = 14;
      widgetSpacing = 6;
      contentPadding = 2;
    };
    wallpaper = {
      enabled = true;
      directory = builtins.dirOf wallpaperPath;
      viewMode = "single";
      setWallpaperOnAllMonitors = true;
      linkLightAndDarkWallpapers = true;
      fillMode = "crop";
      useSolidColor = false;
      overviewEnabled = true;
      overviewBlur = 0.4;
      overviewTint = 0.45;
    };
  });
  noctaliaWallpaperCacheSeed = pkgs.writeText "zeus-noctalia-wallpapers.json" (builtins.toJSON {
    wallpapers = { };
    defaultWallpaper = wallpaperPath;
    usedRandomWallpapers = { };
  });
in
{
  services.udisks2.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # QQ 在 Wayland 下默认会退回 X11；开启 Ozone 后才能正常启动。
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    NIRI_CONFIG = "/etc/niri/config.kdl";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    EDITOR = "${pkgs.helix}/bin/hx";
    VISUAL = "${pkgs.helix}/bin/hx";
  };

  systemd.user.extraConfig = '';
    DefaultEnvironment="EDITOR=${pkgs.helix}/bin/hx" "VISUAL=${pkgs.helix}/bin/hx"
  '';

  qt.enable = true;
  qt.platformTheme = "qt5ct";

  environment.etc."niri/config.kdl".source = niriConfig;
  environment.etc."niri/clipboard-bridge.sh".source = clipboardBridge;
  environment.etc."xdg/qt5ct/qt5ct.conf".text = ''
    [Appearance]
    icon_theme=Papirus
  '';
  environment.etc."xdg/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme=Papirus
  '';
  environment.etc."xdg/fcitx5/conf/classicui.conf".source = fcitx5ClassicUi;

  systemd.user.services.niri-clipboard-bridge = {
    description = "Bridge clipboard between Wayland and Xwayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = with pkgs; [ coreutils diffutils ];
    serviceConfig = {
      ExecStart = "/etc/niri/clipboard-bridge.sh";
      Restart = "always";
      RestartSec = 1;
    };
  };

  systemd.user.services."app-org.fcitx.Fcitx5@autostart" = {
    description = "Disable Fcitx 5 XDG autostart";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };

  # Auto-mount removable drives for the logged-in desktop user.
  systemd.user.services.udiskie = {
    description = "Auto-mount removable media";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --notify --tray";
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  environment.systemPackages = with pkgs; [
    mpv
    papirus-icon-theme
    xwayland-satellite
  ];

  # Provide a real icon theme instead of relying on the bare hicolor fallback
  # metadata only.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          "icon-theme" = "Papirus";
        };
      };
    }
  ];

  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
    policies = {
      SearchEngines = {
        Default = "Google";
        Remove = [
          "百度"
          "Baidu"
        ];
      };
    };
    preferences = {
      "browser.translations.automaticallyPopup" = false;
      "intl.accept_languages" = "zh-CN,zh,en-US,en";
      "intl.locale.requested" = "zh-CN";
      "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
      "privacy.clearOnShutdown_v2.formdata" = false;
      "privacy.sanitize.pending" = "[]";
      "privacy.sanitize.sanitizeOnShutdown" = false;
      "services.sync.prefs.sync.privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
      "services.sync.prefs.sync.privacy.clearOnShutdown_v2.formdata" = false;
      "services.sync.prefs.sync.privacy.sanitize.sanitizeOnShutdown" = false;
    };
  };

  programs.nano.enable = false;

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "LXGW WenKai Mono:size=13.5, Symbols Nerd Font Mono:size=13.5";
        pad = "20x18 center";
        "bold-text-in-bright" = "palette-based";
      };
      mouse = {
        "hide-when-typing" = true;
      };
      cursor = {
        style = "beam";
        "unfocused-style" = "hollow";
        blink = true;
        "beam-thickness" = "2px";
      };
      "colors-dark" = {
        foreground = "241e2d";
        background = "faf7ff";
        cursor = "faf7ff 755fd0";
        "selection-foreground" = "241e2d";
        "selection-background" = "ddd0fa";
        regular0 = "241e2d";
        regular1 = "b45270";
        regular2 = "4e8664";
        regular3 = "aa8333";
        regular4 = "6963d4";
        regular5 = "9e6ed1";
        regular6 = "4a92b1";
        regular7 = "756b82";
        bright0 = "948aa2";
        bright1 = "cd6988";
        bright2 = "69a07e";
        bright3 = "bc9446";
        bright4 = "837cf0";
        bright5 = "b585e4";
        bright6 = "66a9c7";
        bright7 = "faf7ff";
        alpha = 0.95;
      };
    };
  };

  programs.yazi = {
    enable = true;
    plugins = {
      "smart-enter" = pkgs.yaziPlugins.smart-enter;
    };
    settings = {
      yazi = {
        opener.edit = [
          {
            run = ''${pkgs.helix}/bin/hx "$@"'';
            block = true;
            "for" = "unix";
            desc = "Helix";
          }
        ];
        opener.play = [
          {
            run = "mpv %s";
            orphan = true;
            "for" = "unix";
            desc = "mpv";
          }
        ];
        open.prepend_rules = [
          {
            mime = "text/*";
            use = "edit";
          }
          {
            mime = "video/*";
            use = "play";
          }
          {
            mime = "audio/*";
            use = "play";
          }
          {
            mime = "image/*";
            use = "play";
          }
        ];
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = "<Enter>";
            run = "plugin smart-enter";
            desc = "Enter directory or open file";
          }
        ];
      };
    };
  };

  programs.niri.enable = true;
  services.noctalia-shell.enable = true;
  services.displayManager.ly.enable = true;

  services.displayManager.defaultSession = "niri";

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5-mellow-themes
        fcitx5Rime
      ];
      settings = {
        globalOptions = {
          "Hotkey"."EnumerateWithTriggerKeys" = "False";
          "Hotkey"."EnumerateSkipFirst" = "False";
          "Hotkey/TriggerKeys" = {
            "0" = "Control+space";
          };
          "Hotkey/AltTriggerKeys" = { };
          "Hotkey/EnumerateGroupForwardKeys" = { };
          "Hotkey/EnumerateGroupBackwardKeys" = { };
        };
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "rime";
          };
          "Groups/0/Items/0" = { Name = "rime"; Layout = ""; };
          GroupOrder = { "0" = "Default"; };
        };
      };
    };
  };

} // lib.recursiveUpdate
  (mkUserActivation {
  name = "zeusFcitx5Files";
  dryMessage = "would install ${userSettings.name} fcitx5 files";
  files = [
    {
      source = rimeDefaultCustom;
      target = ".local/share/fcitx5/rime/default.custom.yaml";
    }
  ];
  removePaths = [
    ".config/niri/config.kdl"
    ".config/fcitx5/config"
    ".config/fcitx5/profile"
    ".config/fcitx5/conf/classicui.conf"
    ".config/fcitx5/conf/pinyin.conf"
    ".local/share/fcitx5/pinyin"
  ];
  })
  (mkUserActivation {
    name = "zeusNoctaliaFiles";
    dryMessage = "would initialize ${userSettings.name} noctalia files";
    removePaths = [
      ".cache/DankMaterialShell"
      ".config/DankMaterialShell"
      ".config/niri/dms"
      ".local/state/DankMaterialShell"
    ];
    seedFiles = [
      {
        source = noctaliaSettingsSeed;
        target = ".config/noctalia/settings.json";
      }
      {
        source = noctaliaWallpaperCacheSeed;
        target = ".cache/noctalia/wallpapers.json";
      }
    ];
    })
