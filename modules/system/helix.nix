{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  tomlFormat = pkgs.formats.toml { };

  helixConfig = tomlFormat.generate "zeus-helix-config.toml" {
    theme = "darcula";
    editor = {
      line-number = "relative";
      mouse = false;
      auto-info = true;
      lsp.display-messages = true;
      lsp.auto-signature-help = true;
      lsp.display-inlay-hints = true;
      lsp.display-signature-help-docs = true;
      inline-diagnostics = {
        cursor-line = "hint";
        other-lines = "error";
      };
      statusline = {
        left = [
          "mode"
          "spinner"
        ];
        center = [ "file-name" ];
        right = [
          "diagnostics"
          "selections"
          "position"
          "file-encoding"
          "file-line-ending"
          "file-type"
        ];
      };
      gutters = [
        "diagnostics"
        "spacer"
        "line-numbers"
        "spacer"
        "diff"
      ];
      soft-wrap.enable = true;
      completion-replace = true;
      auto-save = true;
    };
    keys.normal.space = {
      w = ":write";
      q = ":quit";
      x = ":write-quit";
    };
  };

  helixLanguages = tomlFormat.generate "zeus-helix-languages.toml" {
    language-server.nil.command = "${pkgs.nil}/bin/nil";
    language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        language-servers = [ "nil" ];
      }
      {
        name = "python";
        auto-format = true;
        formatter = {
          command = "ruff";
          args = [
            "format"
            "--stdin-filename"
            "%{buffer_name}"
            "-"
          ];
        };
      }
      {
        name = "rust";
        auto-format = true;
        formatter = {
          command = "rustfmt";
          args = [ "--emit=stdout" ];
        };
      }
    ];
  };
in
{
  users.users.${userSettings.name}.packages = with pkgs; [ helix ];
} // mkUserActivation {
  name = "zeusHelixFiles";
  dryMessage = "would install ${userSettings.name} helix files";
  dirs = [ ".config/helix" ];
  files = [
    {
      source = helixConfig;
      target = ".config/helix/config.toml";
    }
    {
      source = helixLanguages;
      target = ".config/helix/languages.toml";
    }
  ];
}
