{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;
      args = [
        "-O"
        "HDMI-A-1"
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
  };
}
