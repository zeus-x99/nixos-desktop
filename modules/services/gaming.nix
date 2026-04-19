{ config, lib, pkgs, userSettings, ... }:
let
  gamemodeEventDir = "${userSettings.home}/.local/state/gamemode";
  gamemodeEventLog = "${gamemodeEventDir}/events.log";
  steamOutputWidth = "2560";
  steamOutputHeight = "1440";
  steamOutputRefresh = "320";
  gamemodeEventLogger = pkgs.writeShellScriptBin "gamemode-event-log" ''
    set -eu

    event="$1"

    ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg gamemodeEventDir}
    ${pkgs.coreutils}/bin/printf '%s %s\n' "$(${pkgs.coreutils}/bin/date --iso-8601=seconds)" "$event" >> ${lib.escapeShellArg gamemodeEventLog}
  '';
  steamArgs = lib.escapeShellArgs config.programs.steam.gamescopeSession.steamArgs;
  gamescopeEnvExports = builtins.concatStringsSep "\n" (
    builtins.attrValues (
      builtins.mapAttrs (name: value: "export ${name}=${lib.escapeShellArg value}")
      config.programs.steam.gamescopeSession.env
    )
  );
  steamGamescopeNestedArgs = lib.escapeShellArgs [
    "--backend"
    "wayland"
    "--xwayland-count"
    "2"
    "-w"
    steamOutputWidth
    "-h"
    steamOutputHeight
    "-W"
    steamOutputWidth
    "-H"
    steamOutputHeight
    "-r"
    steamOutputRefresh
    "--rt"
    "--mangoapp"
    "-f"
    "-b"
    "--force-windows-fullscreen"
  ];

  steamGamescopeNiri = pkgs.writeShellScriptBin "steam-gamescope-niri" ''
    set -eu

    export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
    ${gamescopeEnvExports}

    if ${pkgs.procps}/bin/pgrep -u "$(${pkgs.coreutils}/bin/id -u)" -f "/gamescope .* -- steam" >/dev/null; then
      exit 0
    fi

    (
      register_attempt=0
      while [ "$register_attempt" -lt 20 ]; do
        if ${pkgs.systemd}/bin/busctl --user call com.feralinteractive.GameMode /com/feralinteractive/GameMode com.feralinteractive.GameMode RegisterGameByPID ii "$$" "$$" >/dev/null; then
          exit 0
        fi

        register_attempt=$((register_attempt + 1))
        ${pkgs.coreutils}/bin/sleep 0.25
      done

      echo "warning: failed to register gamescope with gamemode"
    ) &

    exec ${config.security.wrapperDir}/gamescope --steam ${steamGamescopeNestedArgs} -- steam ${steamArgs}
  '';
  steamGamescopeNiriDesktop = pkgs.makeDesktopItem {
    name = "steam-gamescope-niri";
    desktopName = "Steam (gamescope)";
    exec = "${steamGamescopeNiri}/bin/steam-gamescope-niri";
    icon = "steam";
    terminal = false;
    categories = [ "Game" ];
    keywords = [ "steam" "gamescope" "mangohud" ];
  };
  hiddenSteamDesktopEntry = pkgs.writeText "steam.desktop" ''
    [Desktop Entry]
    Name=Steam
    Exec=steam %U
    Icon=steam
    Type=Application
    NoDisplay=true
    MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
  '';

in
{
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true;
    };
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        # This desktop does not expose the powercap paths GameMode uses for
        # iGPU power balancing, so disable that probe to avoid noisy errors.
        igpu_power_threshold = -1;
        # The current kernel / scheduler combination reports "none" ionice and
        # GameMode logs a warning when trying to force BE/0, so disable it.
        ioprio = "off";
      };

      custom = {
        start = "${gamemodeEventLogger}/bin/gamemode-event-log gamemode-start";
        end = "${gamemodeEventLogger}/bin/gamemode-event-log gamemode-end";
      };
    };
  };

  programs.gamescope = {
    enable = true;
    # Keep realtime scheduling support for the nested Steam gamescope wrapper.
    capSysNice = true;
  };

  environment.systemPackages = [
    steamGamescopeNiri
    steamGamescopeNiriDesktop
  ];

  environment.etc."xdg/applications/steam.desktop".source = hiddenSteamDesktopEntry;
}
