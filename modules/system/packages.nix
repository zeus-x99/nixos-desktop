{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    mangohud
    bubblewrap
    ffmpeg
    fastfetch
    playerctl
  ];
}
