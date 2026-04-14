{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    lxgw-wenkai-screen
    lxgw-wenkai
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    sarasa-gothic
  ];

  fonts.fontconfig.defaultFonts = {
    sansSerif = [
      "LXGW WenKai Screen"
      "Noto Sans CJK SC"
      "Inter"
    ];
    serif = [
      "LXGW WenKai"
      "Noto Serif CJK SC"
    ];
    monospace = [
      "LXGW WenKai Mono"
      "Sarasa Mono SC"
      "Fira Code"
      "Noto Sans Mono CJK SC"
    ];
    emoji = [ "Noto Color Emoji" ];
  };
}
