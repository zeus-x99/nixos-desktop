{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    qq
    alacritty
    wl-clipboard
    pciutils
    bubblewrap
    ripgrep
    jq
    python3
  ];
}
