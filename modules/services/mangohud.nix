{ pkgs, ... }:
let
  steamGamescopeConfigPath = "/etc/mangohud/steam-gamescope.conf";

  steamGamescopeConfig = pkgs.writeText "zeus-steam-gamescope-mangohud.conf" ''
    position=top-center
    offset_x=0
    offset_y=8
    horizontal
    horizontal_stretch
    hud_no_margin
    round_corners=0
    background_alpha=0
    alpha=1
    font_size=20
    no_small_font
    table_columns=6
    toggle_hud=Shift_R+F12

    fps
    frametime
    fps_metrics=avg,0.01,0.001

    gpu_stats
    gpu_temp
    gpu_power
    gpu_core_clock
    gpu_mem_clock
    vram

    cpu_stats
    cpu_temp
    ram

    gamemode
    wine
    winesync
    resolution
    engine_version
    present_mode
    refresh_rate
    arch
    display_server
  '';
in
{
  environment.etc."mangohud/steam-gamescope.conf".source = steamGamescopeConfig;

  programs.steam.gamescopeSession = {
    env.MANGOHUD_CONFIGFILE = steamGamescopeConfigPath;
  };
}
