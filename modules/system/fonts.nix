{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    lxgw-wenkai-screen
    lxgw-wenkai
    nerd-fonts.symbols-only
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    sarasa-gothic
  ];

  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>LXGW WenKai Mono</family>
        <prefer>
          <family>Symbols Nerd Font Mono</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

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
      "Symbols Nerd Font Mono"
      "Sarasa Mono SC"
      "Fira Code"
      "Noto Sans Mono CJK SC"
    ];
    emoji = [ "Noto Color Emoji" ];
  };
}
