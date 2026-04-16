{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;
      args = [
        "-O"
        "HDMI-A-1"
        "--adaptive-sync"
        "--rt"
      ];
    };
  };

  programs.gamemode.enable = true;

  programs.gamescope = {
    enable = true;
    # Use the official gamescope session integration when Steam is launched
    # as its own session instead of a nested compositor inside niri.
    capSysNice = true;
    args = [ ];
  };

  environment.etc."MangoHud/MangoHud.conf".text = ''
    legacy_layout=0
    position=top-right
    font_size=24
    background_alpha=0.4
    round_corners=10
    gpu_stats
    gpu_temp
    gpu_power
    vram
    cpu_stats
    cpu_temp
    ram
    fps
    frametime
    gamemode
    resolution
  '';

  environment.sessionVariables.MANGOHUD_CONFIGFILE = "/etc/MangoHud/MangoHud.conf";

  environment.systemPackages = with pkgs; [
    mangohud
  ];
}
