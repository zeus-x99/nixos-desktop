{ config, lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };
  gamemodeEventDir = "${userSettings.home}/.local/state/gamemode";
  gamemodeEventLog = "${gamemodeEventDir}/events.log";
  narakaAppId = "1203220";
  narakaLaunchOptions = "gamemoderun %command%";
  steamOutputWidth = "2560";
  steamOutputHeight = "1440";
  steamOutputRefresh = "320";
  steamLaunchOptionsUpdater = pkgs.writeText "steam-launch-options-updater.pl" ''
    use strict;
    use warnings;

    my ($path) = @ARGV;
    my $app_id = $ENV{STEAM_APP_ID} // die "STEAM_APP_ID is required\n";
    my $launch_options = $ENV{STEAM_LAUNCH_OPTIONS} // die "STEAM_LAUNCH_OPTIONS is required\n";

    sub vdf_quote {
      my ($value) = @_;
      $value =~ s/\\/\\\\/g;
      $value =~ s/"/\\"/g;
      return qq{"$value"};
    }

    sub matching_brace {
      my ($text, $open) = @_;
      my $depth = 0;
      my $in_string = 0;
      my $escaped = 0;
      my $length = length($text);

      for (my $i = $open; $i < $length; $i++) {
        my $char = substr($text, $i, 1);

        if ($in_string) {
          if ($escaped) {
            $escaped = 0;
          } elsif ($char eq '\\') {
            $escaped = 1;
          } elsif ($char eq '"') {
            $in_string = 0;
          }
          next;
        }

        if ($char eq '"') {
          $in_string = 1;
        } elsif ($char eq '{') {
          $depth++;
        } elsif ($char eq '}') {
          $depth--;
          return $i if $depth == 0;
        }
      }

      return undef;
    }

    sub named_block {
      my ($text, $key, $from, $until) = @_;
      $from //= 0;
      $until //= length($text);
      my $needle = vdf_quote($key);
      my $pos = $from;

      while (($pos = index($text, $needle, $pos)) >= 0 && $pos < $until) {
        my $after_key = $pos + length($needle);
        if (substr($text, $after_key, $until - $after_key) =~ /\G\s*\{/gc) {
          my $open = $after_key + $+[0] - 1;
          my $close = matching_brace($text, $open);
          return ($open, $close) if defined($close) && $close <= $until;
        }
        $pos = $after_key;
      }

      return;
    }

    sub last_named_block {
      my ($text, $key) = @_;
      my $from = 0;
      my @last;

      while (my @block = named_block($text, $key, $from)) {
        @last = @block;
        $from = $block[1] + 1;
      }

      return @last;
    }

    open my $in, '<', $path or die "open $path: $!\n";
    local $/;
    my $text = <$in>;
    close $in;

    my $quoted_options = vdf_quote($launch_options);
    my ($apps_open, $apps_close) = last_named_block($text, 'apps');

    if (!defined($apps_open)) {
      my $apps_block = qq{\t"apps"\n\t{\n\t\t"$app_id"\n\t\t{\n\t\t\t"LaunchOptions"\t\t$quoted_options\n\t\t}\n\t}\n};
      $text =~ s/\n\}\s*$/\n$apps_block}/s or die "failed to add apps block to $path\n";
    } else {
      my ($app_open, $app_close) = named_block($text, $app_id, $apps_open + 1, $apps_close);

      if (!defined($app_open)) {
        substr($text, $apps_close, 0) = qq{\t\t"$app_id"\n\t\t{\n\t\t\t"LaunchOptions"\t\t$quoted_options\n\t\t}\n};
      } else {
        my $app_body_start = $app_open + 1;
        my $app_body = substr($text, $app_body_start, $app_close - $app_body_start);

        if ($app_body =~ s/^([ \t]*)"LaunchOptions"\s*"(?:\\.|[^"])*"/$1"LaunchOptions"\t\t$quoted_options/m) {
          substr($text, $app_body_start, $app_close - $app_body_start) = $app_body;
        } else {
          substr($text, $app_close, 0) = qq{\t\t\t"LaunchOptions"\t\t$quoted_options\n};
        }
      }
    }

    open my $out, '>', $path or die "write $path: $!\n";
    print {$out} $text;
    close $out;
  '';
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

  system.activationScripts = (mkUserActivation {
    name = "steam-launch-options";
    dryMessage = "would configure Steam launch options for NARAKA: BLADEPOINT";
    commands = [
      ''
        seen_configs=""
        for steam_config in \
          ${lib.escapeShellArg "${userSettings.home}/.local/share/Steam/userdata"}/*/config/localconfig.vdf \
          ${lib.escapeShellArg "${userSettings.home}/.steam/steam/userdata"}/*/config/localconfig.vdf; do
          if [ ! -e "$steam_config" ]; then
            continue
          fi

          real_config="$(${pkgs.coreutils}/bin/readlink -f "$steam_config")"
          case " $seen_configs " in
            *" $real_config "*) continue ;;
          esac
          seen_configs="$seen_configs $real_config"

          STEAM_APP_ID=${lib.escapeShellArg narakaAppId} \
          STEAM_LAUNCH_OPTIONS=${lib.escapeShellArg narakaLaunchOptions} \
            ${pkgs.perl}/bin/perl ${steamLaunchOptionsUpdater} "$real_config"
          chown ${lib.escapeShellArg "${userSettings.name}:${userSettings.group}"} "$real_config"
        done
      ''
    ];
  }).system.activationScripts;
}
