{ pkgs, ... }:
let
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
in
{
  environment.sessionVariables = {
    QT_IM_MODULE = "fcitx";
    QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
  };

  environment.etc."xdg/fcitx5/conf/classicui.conf".source = fcitx5ClassicUi;

  systemd.user.services."app-org.fcitx.Fcitx5@autostart" = {
    description = "Disable Fcitx 5 XDG autostart";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
    };
  };

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
          "Groups/0/Items/0" = {
            Name = "rime";
            Layout = "";
          };
          GroupOrder = {
            "0" = "Default";
          };
        };
      };
    };
  };
}
