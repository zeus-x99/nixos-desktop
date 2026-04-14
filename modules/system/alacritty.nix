{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  obsoleteTheme = "${userSettings.home}/.config/alacritty/dank-theme.toml";

  alacrittyConfig = pkgs.writeText "zeus-alacritty.toml" ''
    [general]
    live_config_reload = true

    [window]
    opacity = 0.95
    dynamic_padding = true
    decorations = "None"

    [window.padding]
    x = 20
    y = 18

    [scrolling]
    history = 20000
    multiplier = 4

    [font]
    size = 13.5
    builtin_box_drawing = true

    [font.normal]
    family = "LXGW WenKai Mono"
    style = "Regular"

    [font.bold]
    family = "LXGW WenKai Mono"
    style = "Medium"

    [font.italic]
    family = "LXGW WenKai Mono"
    style = "Regular"

    [font.bold_italic]
    family = "LXGW WenKai Mono"
    style = "Medium"

    [font.offset]
    x = 0
    y = 2

    [font.glyph_offset]
    x = 0
    y = 1

    [colors.primary]
    background = "#faf7ff"
    foreground = "#241e2d"

    [colors.cursor]
    text = "#faf7ff"
    cursor = "#755fd0"

    [colors.vi_mode_cursor]
    text = "#faf7ff"
    cursor = "#b98e34"

    [colors.selection]
    text = "#241e2d"
    background = "#ddd0fa"

    [colors.search.matches]
    foreground = "#5b4e71"
    background = "#eee6ff"

    [colors.search.focused_match]
    foreground = "#241e2d"
    background = "#d1beff"

    [colors.footer_bar]
    foreground = "#4c4063"
    background = "#dfd2fa"

    [colors.hints.start]
    foreground = "#4a3107"
    background = "#ffdeab"

    [colors.hints.end]
    foreground = "#594d6a"
    background = "#e5dcfa"

    [selection]
    save_to_clipboard = true

    [cursor]
    unfocused_hollow = true
    thickness = 0.18

    [cursor.style]
    shape = "Beam"
    blinking = "On"

    [keyboard]
    bindings = [
      { key = "C", mods = "Control|Shift", action = "Copy" },
      { key = "V", mods = "Control|Shift", action = "Paste" },
      { key = "Insert", mods = "Control", action = "Copy" },
      { key = "Insert", mods = "Shift", action = "PasteSelection" },
    ]

    [mouse]
    hide_when_typing = true
    bindings = [
      { mouse = "Right", action = "Paste" },
      { mouse = "Middle", action = "PasteSelection" },
    ]

    [colors.normal]
    black = "#241e2d"
    red = "#b45270"
    green = "#4e8664"
    yellow = "#aa8333"
    blue = "#6963d4"
    magenta = "#9e6ed1"
    cyan = "#4a92b1"
    white = "#756b82"

    [colors.bright]
    black = "#948aa2"
    red = "#cd6988"
    green = "#69a07e"
    yellow = "#bc9446"
    blue = "#837cf0"
    magenta = "#b585e4"
    cyan = "#66a9c7"
    white = "#faf7ff"
  '';
in
mkUserActivation {
  name = "zeusAlacrittyFiles";
  dryMessage = "would install ${userSettings.name} alacritty files";
  dirs = [ ".config/alacritty" ];
  files = [
    {
      source = alacrittyConfig;
      target = ".config/alacritty/alacritty.toml";
    }
  ];
  commands = [ "rm -f ${lib.escapeShellArg obsoleteTheme}" ];
}
