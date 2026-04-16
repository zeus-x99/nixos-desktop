{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    firefox
    qq
    alacritty
    fuzzel
    wl-clipboard
    xsel
    pciutils
    bubblewrap
    ripgrep
    gh
    jq
  ];
}
