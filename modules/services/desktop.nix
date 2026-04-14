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
    Theme=default
    Font="LXGW WenKai Screen 14"
    MenuFont="LXGW WenKai Screen 14"
    TrayFont="LXGW WenKai Screen 11"
    UseInputMethodLangaugeToDisplayText=True
  '';

  fcitx5Profile = pkgs.writeText "zeus-fcitx5-profile" ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=rime

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=rime
    Layout=

    [GroupOrder]
    0=Default
  '';

  rimeDefaultCustom = pkgs.writeText "zeus-rime-default.custom.yaml" ''
    patch:
      schema_list:
        - schema: rime_ice
      menu/page_size: 9
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

  environment.etc."niri/config.kdl".source = ./niri-config.kdl;

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

  programs.niri.enable = true;
  programs.dms-shell.enable = true;

  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "niri";
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
  dirs = [
    ".config/fcitx5/conf"
    ".local/share/fcitx5/rime"
  ];
  files = [
    {
      source = fcitx5Profile;
      target = ".config/fcitx5/profile";
    }
    {
      source = fcitx5ClassicUi;
      target = ".config/fcitx5/conf/classicui.conf";
    }
    {
      source = rimeDefaultCustom;
      target = ".local/share/fcitx5/rime/default.custom.yaml";
    }
  ];
  commands = [
    "rm -f ${lib.escapeShellArg "${userSettings.home}/.config/niri/config.kdl"}"
    "rm -f ${lib.escapeShellArg "${userSettings.home}/.config/fcitx5/config"}"
    "rm -f ${lib.escapeShellArg "${userSettings.home}/.config/fcitx5/conf/pinyin.conf"}"
    "rm -rf ${lib.escapeShellArg "${userSettings.home}/.local/share/fcitx5/pinyin"}"
  ];
}
