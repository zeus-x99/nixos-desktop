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
    language-server.rust-analyzer = {
      command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      environment = {
        PATH = lib.makeBinPath [
          pkgs.cargo
          pkgs.clippy
          pkgs.gcc
          pkgs.git
          pkgs.pkg-config
          pkgs.rustc
          pkgs.rustfmt
        ];
        RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
      };
    };
    language = [
      {
        name = "nix";
        auto-format = true;
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        language-servers = [ "nil" ];
      }
      {
        name = "rust";
        auto-format = true;
        language-servers = [ "rust-analyzer" ];
        formatter = {
          command = "${pkgs.rustfmt}/bin/rustfmt";
          args = [ "--emit=stdout" ];
        };
        # Pin Rust debugging to the system-provided LLDB DAP binary so the
        # setup does not depend on Helix runtime defaults.
        debugger = {
          name = "lldb-dap";
          transport = "stdio";
          command = "${pkgs.lldb}/bin/lldb-dap";
          templates = [
            {
              name = "binary";
              request = "launch";
              completion = [
                {
                  name = "binary";
                  completion = "filename";
                }
              ];
              args = { program = "{0}"; };
            }
            {
              name = "binary (terminal)";
              request = "launch";
              completion = [
                {
                  name = "binary";
                  completion = "filename";
                }
              ];
              args = {
                program = "{0}";
                runInTerminal = true;
              };
            }
            {
              name = "attach";
              request = "attach";
              completion = [ "pid" ];
              args = { pid = "{0}"; };
            }
          ];
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
