{ lib, pkgs, ... }:
let
  defaultCursorTheme = pkgs.runCommand "zeus-default-cursor-theme" { } ''
    mkdir -p $out/share/icons/default
    cat >$out/share/icons/default/index.theme <<'EOF'
    [Icon Theme]
    Inherits=Bibata-Modern-Ice
    EOF
  '';
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
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = "24";
    EDITOR = "${pkgs.helix}/bin/hx";
    VISUAL = "${pkgs.helix}/bin/hx";
    TERMINAL = "${pkgs.foot}/bin/foot";
  };

  systemd.user.extraConfig = ''
    DefaultEnvironment="EDITOR=${pkgs.helix}/bin/hx" "VISUAL=${pkgs.helix}/bin/hx" "TERMINAL=${pkgs.foot}/bin/foot" "XCURSOR_THEME=Bibata-Modern-Ice" "XCURSOR_SIZE=24"
  '';

  qt.enable = true;
  qt.platformTheme = "qt5ct";

  environment.etc."xdg/qt5ct/qt5ct.conf".text = ''
    [Appearance]
    icon_theme=Papirus
  '';
  environment.etc."xdg/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme=Papirus
  '';

  environment.systemPackages = with pkgs; [
    bibata-cursors
    defaultCursorTheme
    mpv
    papirus-icon-theme
    xwayland-satellite
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
}
