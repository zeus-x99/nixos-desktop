{
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  loginFile = "${userSettings.home}/.config/nushell/login.nu";

  nushellConfig = pkgs.writeText "zeus-config.nu" ''
    $env.config = {
      show_banner: false
      edit_mode: vi
    }

    alias shx = sudo -E hx

    source ~/.cache/starship/init.nu
  '';

  nushellEnv = pkgs.writeText "zeus-env.nu" ''
    $env.EDITOR = "${pkgs.helix}/bin/hx"

    let codex_env_file = "/run/secrets/rendered/codex-api.env"

    if ($codex_env_file | path exists) {
      for line in (open $codex_env_file | lines) {
        if ($line | str starts-with "CLIPROXYAPI_API_KEY=") {
          $env.CLIPROXYAPI_API_KEY = ($line | str replace "CLIPROXYAPI_API_KEY=" "")
        }
      }
    }
  '';
in
{
  users.users.${userSettings.name} = {
    shell = pkgs.nushell;
    packages = with pkgs; [ nushell ];
  };
} // mkUserActivation {
  name = "zeusNushellFiles";
  dryMessage = "would install ${userSettings.name} nushell files";
  dirs = [ ".config/nushell" ];
  files = [
    {
      source = nushellConfig;
      target = ".config/nushell/config.nu";
    }
    {
      source = nushellEnv;
      target = ".config/nushell/env.nu";
    }
  ];
  commands = [
    ": > ${lib.escapeShellArg loginFile}"
    "chown ${lib.escapeShellArg "${userSettings.name}:${userSettings.group}"} ${lib.escapeShellArg loginFile}"
    "chmod 0644 ${lib.escapeShellArg loginFile}"
  ];
}
