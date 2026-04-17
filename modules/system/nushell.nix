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

  nushellConfig = pkgs.writeText "zeus-config.nu" ''
    $env.config = {
      show_banner: false
      edit_mode: vi
    }

    alias dev = nix develop /etc/nixos#default -c nu -l
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
  };
} // mkUserActivation {
  name = "zeusNushellFiles";
  dryMessage = "would install ${userSettings.name} nushell files";
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
  emptyFiles = [
    {
      target = ".config/nushell/login.nu";
      createOnly = true;
    }
  ];
}
