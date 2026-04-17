{ lib, pkgs, quickshell, userSettings, ... }:
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
    Theme=default
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

  dmsSettingsPath = "${userSettings.home}/.config/DankMaterialShell/settings.json";
  dmsNiriDir = "${userSettings.home}/.config/niri/dms";
  dmsNiriFiles = [
    "colors"
    "layout"
    "alttab"
    "binds"
    "wpblur"
  ];

  niriConfig = pkgs.writeText "zeus-niri-config.kdl" ''
    ${builtins.readFile ./niri-config.kdl}

    // DMS writes compositor fragments under the user's XDG config dir.
    // Because this system config lives in /etc/niri, use absolute include paths.
    layer-rule {
        match namespace="^quickshell$"
        place-within-backdrop true
    }

    include "${dmsNiriDir}/colors.kdl"
    include "${dmsNiriDir}/layout.kdl"
    include "${dmsNiriDir}/alttab.kdl"
    include "${dmsNiriDir}/binds.kdl"
    include "${dmsNiriDir}/wpblur.kdl"
  '';

  dmsGreeterNiriConfig = ''
    input {
        keyboard {
            xkb {}
        }
    }

    output "HDMI-A-1" {
        mode "2560x1440@319.999"
        scale 1.25
    }

    output "DP-1" {
        scale 2.0
    }
  '';
in
{
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # QQ 在 Wayland 下默认会退回 X11；开启 Ozone 后才能正常启动。
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    NIRI_CONFIG = "/etc/niri/config.kdl";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

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

  environment.systemPackages = with pkgs; [
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
    preferences = {
      "intl.accept_languages" = "zh-CN,zh,en-US,en";
      "intl.locale.requested" = "zh-CN";
    };
  };

  programs.niri.enable = true;
  programs.dms-shell = {
    enable = true;
    quickshell.package = quickshell.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = userSettings.name;
  };

  services.displayManager.defaultSession = "niri";

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    compositor.customConfig = dmsGreeterNiriConfig;
    configHome = userSettings.home;
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-gtk
        fcitx5Rime
      ];
      settings = {
        globalOptions = {
          "Hotkey"."EnumerateWithTriggerKeys" = "True";
          "Hotkey"."EnumerateSkipFirst" = "True";
          "Hotkey/TriggerKeys"."0" = "Control+space";
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
          "Groups/0/Items/0" = { Name = "keyboard-us"; Layout = ""; };
          "Groups/0/Items/1" = { Name = "rime"; Layout = ""; };
          GroupOrder = { "0" = "Default"; };
        };
      };
    };
  };

} // mkUserActivation {
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
} // mkUserActivation {
  name = "zeusDmsFiles";
  dryMessage = "would initialize ${userSettings.name} dms files";
  seedFiles = [
    {
      source = ./dms-settings.json;
      target = ".config/DankMaterialShell/settings.json";
    }
  ];
  emptyFiles = map (name: {
    target = ".config/niri/dms/${name}.kdl";
    createOnly = true;
  }) dmsNiriFiles;
}
