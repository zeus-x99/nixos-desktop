{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    languagePacks = [ "zh-CN" ];
    policies = {
      SearchEngines = {
        Default = "Google";
        Remove = [
          "百度"
          "Baidu"
        ];
      };
    };
    preferences = {
      "browser.translations.automaticallyPopup" = false;
      "intl.accept_languages" = "zh-CN,zh,en-US,en";
      "intl.locale.requested" = "zh-CN";
      "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
      "privacy.clearOnShutdown_v2.formdata" = false;
      "privacy.sanitize.pending" = "[]";
      "privacy.sanitize.sanitizeOnShutdown" = false;
      "services.sync.prefs.sync.privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
      "services.sync.prefs.sync.privacy.clearOnShutdown_v2.formdata" = false;
      "services.sync.prefs.sync.privacy.sanitize.sanitizeOnShutdown" = false;
    };
  };

  programs.nano.enable = false;

  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "LXGW WenKai Mono:size=13.5, Symbols Nerd Font Mono:size=13.5";
        pad = "20x18 center";
        "bold-text-in-bright" = "palette-based";
        "selection-target" = "both";
      };
      mouse = {
        "hide-when-typing" = true;
      };
      "mouse-bindings" = {
        "select-extend" = "none";
        "clipboard-paste" = "BTN_RIGHT";
      };
      cursor = {
        style = "beam";
        "unfocused-style" = "hollow";
        blink = true;
        "beam-thickness" = "2px";
      };
      "colors-dark" = {
        foreground = "faf7ff";
        background = "1b1623";
        cursor = "1b1623 837cf0";
        "selection-foreground" = "faf7ff";
        "selection-background" = "4a3d63";
        regular0 = "241e2d";
        regular1 = "b45270";
        regular2 = "4e8664";
        regular3 = "aa8333";
        regular4 = "6963d4";
        regular5 = "9e6ed1";
        regular6 = "4a92b1";
        regular7 = "756b82";
        bright0 = "948aa2";
        bright1 = "cd6988";
        bright2 = "69a07e";
        bright3 = "bc9446";
        bright4 = "837cf0";
        bright5 = "b585e4";
        bright6 = "66a9c7";
        bright7 = "faf7ff";
        alpha = 0.5;
        blur = true;
      };
      "key-bindings" = {
        "clipboard-copy" = "Control+Shift+c Control+Insert XF86Copy";
        "clipboard-paste" = "Control+Shift+v Shift+Insert XF86Paste";
        "primary-paste" = "none";
      };
      "search-bindings" = {
        "clipboard-paste" = "Control+v Control+y Control+Shift+v XF86Paste";
        "primary-paste" = "Shift+Insert";
      };
    };
  };

  programs.yazi = {
    enable = true;
    plugins = {
      "smart-enter" = pkgs.yaziPlugins.smart-enter;
    };
    settings = {
      yazi = {
        opener.edit = [
          {
            run = ''${pkgs.helix}/bin/hx "$@"'';
            block = true;
            "for" = "unix";
            desc = "Helix";
          }
        ];
        opener.play = [
          {
            run = "mpv %s";
            orphan = true;
            "for" = "unix";
            desc = "mpv";
          }
        ];
        open.prepend_rules = [
          {
            mime = "text/*";
            use = "edit";
          }
          {
            mime = "video/*";
            use = "play";
          }
          {
            mime = "audio/*";
            use = "play";
          }
          {
            mime = "image/*";
            use = "play";
          }
        ];
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = "<Enter>";
            run = "plugin smart-enter";
            desc = "Enter directory or open file";
          }
        ];
      };
    };
  };
}
