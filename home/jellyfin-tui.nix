{
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  q = lib.escapeShellArg;
  passwordPath = "${userSettings.home}/.config/jellyfin-tui/password";
  yaml = pkgs.formats.yaml { };
  configFile = yaml.generate "jellyfin-tui-config.yaml" {
    servers = [
      {
        name = "router";
        url = "https://jf.imagic.wiki";
        username = userSettings.name;
        password_file = passwordPath;
        default = true;
      }
    ];

    art = true;
    persist = true;
    auto_color = true;
    lyrics = "auto";
    rounded_corners = true;
    window_title = true;
  };
in
{
  home.packages = [ pkgs.jellyfin-tui ];

  xdg.configFile."jellyfin-tui/config.yaml".source = configFile;

  home.activation.jellyfinTuiPasswordFile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    password_file=${q passwordPath}

    ${pkgs.coreutils}/bin/install -d -m 0700 "$HOME/.config/jellyfin-tui"

    if [ -e "$password_file" ]; then
      ${pkgs.coreutils}/bin/chmod 0600 "$password_file"
    else
      echo "jellyfin-tui: missing password file at $password_file"
    fi
  '';
}
