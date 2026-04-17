{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    qq
    alacritty
    fuzzel
    mangohud
    obs-studio
    wl-clipboard
    xsel
    pciutils
    bubblewrap
    ripgrep
    gh
    jq
  ];
}
