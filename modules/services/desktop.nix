{ config, lib, pkgs, userSettings, ... }:
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
      "ascii_composer/switch_key/Shift_L": commit_code
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
  niriLatest = pkgs.niri.overrideAttrs (oldAttrs: rec {
    version = "26.04";
    src = pkgs.fetchFromGitHub {
      owner = "niri-wm";
      repo = "niri";
      tag = "v${version}";
      hash = "sha256-ehSMsSpE+0k8r+2Vseu8kangsYxToZv3vinynsDp9zs=";
    };
    postPatch = ''
      patchShebangs resources/niri-session
      substituteInPlace resources/niri.service \
        --replace-fail 'ExecStart=niri' "ExecStart=$out/bin/niri"
    '';
    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = "sha256-gfnalA3qI3a9h3PvsxgQLCrzapfjLLkxhTMJpwRh+ro=";
    };
    env = oldAttrs.env // {
      NIRI_BUILD_COMMIT = "8ed0da44d974c32c6877d2f4630c314da0717ecb";
    };
  });
  defaultCursorTheme = pkgs.runCommand "zeus-default-cursor-theme" { } ''
    mkdir -p $out/share/icons/default
    cat >$out/share/icons/default/index.theme <<'EOF'
    [Icon Theme]
    Inherits=Bibata-Modern-Ice
    EOF
  '';
  wallpaperImage = ../../assets/wallpapers/sunlight-beams-wallpaper-3840x2160-magical-woods-forest-magic-29641.jpg;
  wallpaperPath = toString wallpaperImage;
  noctaliaDesktopEntry = pkgs.makeDesktopItem {
    name = "dev.noctalia.noctalia-qs";
    desktopName = "Noctalia Shell";
    genericName = "Desktop Shell";
    comment = "Noctalia desktop shell";
    exec = "${config.services.noctalia-shell.package}/bin/noctalia-shell";
    icon = "nix-snowflake";
    categories = [ "Utility" ];
    startupNotify = false;
  };
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
      widgets = {
        left = [
          { id = "Workspace"; }
          { id = "ActiveWindow"; }
        ];
        center = [
          {
            id = "Clock";
            clockColor = "none";
            useCustomFont = false;
            customFont = "";
            formatHorizontal = "HH:mm ddd, MMM dd";
            formatVertical = "HH mm - dd MM";
            tooltipFormat = "HH:mm ddd, MMM dd";
          }
          { id = "MediaMini"; }
        ];
        right = [
          {
            id = "Tray";
            drawerEnabled = false;
            hidePassive = true;
          }
          {
            id = "SystemMonitor";
            compactMode = false;
            useMonospaceFont = true;
            usePadding = true;
            showCpuUsage = true;
            showCpuCores = false;
            showCpuFreq = false;
            showCpuTemp = false;
            showGpuTemp = false;
            showLoadAverage = false;
            showMemoryUsage = true;
            showMemoryAsPercent = true;
            showSwapUsage = false;
            showNetworkStats = true;
            showDiskUsage = false;
            showDiskUsageAsPercent = false;
            showDiskAvailable = false;
            diskPath = "/";
          }
          { id = "NotificationHistory"; }
          { id = "Volume"; }
          { id = "ControlCenter"; }
        ];
      };
    };
    dock = {
      enabled = false;
    };
    location = {
      name = "Chengdu";
      autoLocate = false;
      weatherEnabled = true;
      useFahrenheit = false;
      use12hourFormat = false;
      firstDayOfWeek = -1;
    };
    colorSchemes = {
      darkMode = false;
      schedulingMode = "location";
      manualSunrise = "06:30";
      manualSunset = "18:30";
      syncGsettings = true;
      useWallpaperColors = true;
      predefinedScheme = "One";
      generationMethod = "tonal-spot";
      monitorForColors = "HDMI-A-1";
    };
    controlCenter = {
      cards = [
        {
          enabled = true;
          id = "profile-card";
        }
        {
          enabled = true;
          id = "shortcuts-card";
        }
        {
          enabled = true;
          id = "audio-card";
        }
        {
          enabled = false;
          id = "brightness-card";
        }
        {
          enabled = true;
          id = "weather-card";
        }
        {
          enabled = true;
          id = "media-sysmon-card";
        }
      ];
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
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.udisks2.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "foot.desktop" ];
  };

  # QQ 在 Wayland 下默认会退回 X11；开启 Ozone 后才能正常启动。
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    NIRI_CONFIG = "/etc/niri/config.kdl";
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    QT_IM_MODULE = "fcitx";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
    EDITOR = "${pkgs.helix}/bin/hx";
    VISUAL = "${pkgs.helix}/bin/hx";
    TERMINAL = "${pkgs.foot}/bin/foot";
  };

  systemd.user.extraConfig = '';
    DefaultEnvironment="EDITOR=${pkgs.helix}/bin/hx" "VISUAL=${pkgs.helix}/bin/hx" "TERMINAL=${pkgs.foot}/bin/foot" "XCURSOR_THEME=Bibata-Modern-Ice" "XCURSOR_SIZE=24"
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
    after = [ "graphical-session.target" "niri.service" ];
    path = with pkgs; [ xdg-utils ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "zeus-udiskie-session" ''
        set -eu

        runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        export XDG_RUNTIME_DIR="$runtime_dir"

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

        exec ${pkgs.udiskie}/bin/udiskie \
          --automount \
          --notify \
          --tray \
          --file-manager ${pkgs.xdg-utils}/bin/xdg-open
      '';
      Environment = [ "LC_ALL=C.UTF-8" ];
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  environment.systemPackages = with pkgs; [
    bibata-cursors
    defaultCursorTheme
    mpv
    papirus-icon-theme
    xwayland-satellite
    noctaliaDesktopEntry
  ] ++ [
    config.services.noctalia-shell.package
  ];

  environment.pathsToLink = [ "/share/icons" ];

  # Provide a real icon theme instead of relying on the bare hicolor fallback
  # metadata only.
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/interface" = {
          "icon-theme" = "Papirus";
          "cursor-theme" = "Bibata-Modern-Ice";
          "cursor-size" = lib.gvariant.mkInt32 24;
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
        blur = true;
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

  programs.niri = {
    enable = true;
    package = niriLatest;
  };
  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "niri";

  services.dbus.packages =
    let
      filteredSystemDbus = pkgs.runCommand "filtered-system-dbus" { } ''
        copy_dir() {
          local source_dir="$1"
          local target_dir="$2"

          if [ -d "$source_dir" ]; then
            mkdir -p "$target_dir"
            for entry in "$source_dir"/*; do
              [ -e "$entry" ] || continue
              ln -s "$entry" "$target_dir/"
            done
          fi
        }

        copy_dir ${config.system.path}/etc/dbus-1/system.d $out/etc/dbus-1/system.d
        copy_dir ${config.system.path}/share/dbus-1/system.d $out/share/dbus-1/system.d
        copy_dir ${config.system.path}/share/dbus-1/system-services $out/share/dbus-1/system-services

        rm -f $out/share/dbus-1/system-services/org.freedesktop.resolve1.service
      '';
    in
    lib.mkForce [
      config.services.dbus.dbusPackage
      filteredSystemDbus
      pkgs.gcr
      pkgs.nautilus
    ];

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        libsForQt5.fcitx5-qt
        fcitx5-mellow-themes
        fcitx5Rime
        qt6Packages.fcitx5-qt
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
    dryMessage = "would manage ${userSettings.name} noctalia files";
    removePaths = [
      ".cache/DankMaterialShell"
      ".config/DankMaterialShell"
      ".config/niri/dms"
      ".local/state/DankMaterialShell"
    ];
    files = [
      {
        source = noctaliaSettingsSeed;
        target = ".config/noctalia/settings.json";
      }
    ];
    seedFiles = [
      {
        source = noctaliaWallpaperCacheSeed;
        target = ".cache/noctalia/wallpapers.json";
      }
    ];
    })
