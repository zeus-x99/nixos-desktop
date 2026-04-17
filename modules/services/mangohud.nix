{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  steamGamescopeConfigPath = "/etc/mangohud/steam-gamescope.conf";

  mangoHudConfig = pkgs.writeText "zeus-steam-gamescope-mangohud.conf" ''
    position=top-right
    offset_x=24
    offset_y=24
    round_corners=8
    background_alpha=0.35
    alpha=0.95
    font_size=22
    no_small_font
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
    cpu_power
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
  environment.etc."mangohud/steam-gamescope.conf".source = mangoHudConfig;

  programs.steam.gamescopeSession = {
    # Use gamescope's mangoapp integration for the dedicated Steam session.
    args = lib.mkAfter [ "--mangoapp" ];
    env.MANGOHUD_CONFIGFILE = steamGamescopeConfigPath;
  };
} // mkUserActivation {
  name = "zeusMangoHudSteamCleanup";
  dryMessage = "would remove ${userSettings.name} desktop MangoHud config";
  removePaths = [ ".config/MangoHud/MangoHud.conf" ];
}
