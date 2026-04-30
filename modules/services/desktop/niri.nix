{
  config,
  lib,
  pkgs,
  ...
}:
let
  clipboardBridge = pkgs.writeShellScript "zeus-clipboard-bridge.sh" ''
    #!/usr/bin/env bash
    set -eu

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export XDG_RUNTIME_DIR="$runtime_dir"
    export DISPLAY="''${DISPLAY:-:0}"

    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      attempt=0
      while [ "$attempt" -lt 10 ]; do
        for socket in "$runtime_dir"/wayland-*; do
          if [ -S "$socket" ]; then
            export WAYLAND_DISPLAY="$(basename "$socket")"
            break 2
          fi
        done
        attempt=$((attempt + 1))
        ${pkgs.coreutils}/bin/sleep 1
      done
    fi

    if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
      echo "clipboard bridge: unable to find WAYLAND_DISPLAY in $runtime_dir" >&2
      exit 1
    fi

    state_dir="$runtime_dir/clipboard-bridge"
    mkdir -p "$state_dir"

    state_data() {
      printf '%s/%s.data\n' "$state_dir" "$1"
    }

    state_type() {
      printf '%s/%s.type\n' "$state_dir" "$1"
    }

    state_matches() {
      local side="$1"
      local type="$2"
      local file="$3"
      local data_file
      local type_file
      data_file="$(state_data "$side")"
      type_file="$(state_type "$side")"

      [ -f "$data_file" ] \
        && [ -f "$type_file" ] \
        && [ "$(cat "$type_file")" = "$type" ] \
        && cmp -s "$file" "$data_file"
    }

    save_state() {
      local side="$1"
      local type="$2"
      local file="$3"

      cp "$file" "$(state_data "$side")"
      printf '%s\n' "$type" >"$(state_type "$side")"
    }

    pick_from_lines() {
      local lines="$1"
      shift

      local wanted
      for wanted in "$@"; do
        if printf '%s\n' "$lines" | ${pkgs.gnugrep}/bin/grep -Fxq "$wanted"; then
          printf '%s\n' "$wanted"
          return 0
        fi
      done

      return 1
    }

    first_with_prefix() {
      local prefix="$1"
      local line

      while IFS= read -r line; do
        case "$line" in
          "$prefix"*)
            printf '%s\n' "$line"
            return 0
            ;;
        esac
      done

      return 1
    }

    first_line() {
      local line

      while IFS= read -r line; do
        if [ -n "$line" ]; then
          printf '%s\n' "$line"
          return 0
        fi
      done

      return 1
    }

    pick_wayland_type() {
      local types
      types="$(${pkgs.wl-clipboard}/bin/wl-paste --list-types 2>/dev/null || true)"
      [ -n "$types" ] || return 1

      pick_from_lines "$types" "image/png" "image/jpeg" "image/jpg" "image/webp" "image/bmp" "image/tiff" \
        || printf '%s\n' "$types" | first_with_prefix "image/" \
        || pick_from_lines "$types" "text/plain;charset=utf-8" "text/plain" "UTF8_STRING" "TEXT" "STRING" \
        || printf '%s\n' "$types" | first_with_prefix "text/" \
        || printf '%s\n' "$types" | first_line
    }

    pick_x_target() {
      local targets
      targets="$(${pkgs.xclip}/bin/xclip -selection clipboard -out -target TARGETS 2>/dev/null || true)"
      [ -n "$targets" ] || return 1

      pick_from_lines "$targets" "image/png" "image/jpeg" "image/jpg" "image/webp" "image/bmp" "image/tiff" \
        || printf '%s\n' "$targets" | first_with_prefix "image/" \
        || pick_from_lines "$targets" "text/plain;charset=utf-8" "UTF8_STRING" "text/plain" "TEXT" "STRING" \
        || printf '%s\n' "$targets" | first_with_prefix "text/"
    }

    wayland_type_to_x_target() {
      case "$1" in
        text/plain*)
          printf '%s\n' "UTF8_STRING"
          ;;
        *)
          printf '%s\n' "$1"
          ;;
      esac
    }

    x_target_to_wayland_type() {
      case "$1" in
        UTF8_STRING|TEXT|STRING)
          printf '%s\n' "text/plain;charset=utf-8"
          ;;
        *)
          printf '%s\n' "$1"
          ;;
      esac
    }

    sync_wl_to_x() {
      case "''${CLIPBOARD_STATE:-data}" in
        data|sensitive)
          ;;
        *)
          cat >/dev/null || true
          return 0
          ;;
      esac

      cat >/dev/null &
      local drain_pid="$!"
      local tmp
      local type
      local x_target
      tmp="$(mktemp "$state_dir/wl.XXXXXX")"

      if ! type="$(pick_wayland_type)"; then
        rm -f "$tmp"
        wait "$drain_pid" 2>/dev/null || true
        return 0
      fi

      if ! ${pkgs.wl-clipboard}/bin/wl-paste --no-newline --type "$type" >"$tmp" 2>/dev/null; then
        rm -f "$tmp"
        wait "$drain_pid" 2>/dev/null || true
        return 0
      fi

      if state_matches "wayland" "$type" "$tmp"; then
        rm -f "$tmp"
        wait "$drain_pid" 2>/dev/null || true
        return 0
      fi

      save_state "wayland" "$type" "$tmp"

      if state_matches "x11" "$type" "$tmp"; then
        rm -f "$tmp"
        wait "$drain_pid" 2>/dev/null || true
        return 0
      fi

      x_target="$(wayland_type_to_x_target "$type")"
      case "$type" in
        text/*|UTF8_STRING|TEXT|STRING)
          ${pkgs.xsel}/bin/xsel -ib <"$tmp" || true
          ;;
        *)
          ${pkgs.xclip}/bin/xclip -selection clipboard -target "$x_target" -in "$tmp" || true
          ;;
      esac
      save_state "x11" "$type" "$tmp"
      rm -f "$tmp"
      wait "$drain_pid" 2>/dev/null || true
    }

    sync_x_to_wl() {
      while true; do
        ${pkgs.clipnotify}/bin/clipnotify

        local tmp
        local x_target
        local type
        tmp="$(mktemp "$state_dir/x.XXXXXX")"

        x_target="$(pick_x_target || true)"
        x_target="''${x_target:-UTF8_STRING}"
        type="$(x_target_to_wayland_type "$x_target")"

        case "$x_target" in
          text/*|UTF8_STRING|TEXT|STRING)
            type="text/plain;charset=utf-8"
            if ! ${pkgs.xsel}/bin/xsel -ob >"$tmp" 2>/dev/null; then
              rm -f "$tmp"
              continue
            fi
            ;;
          *)
            if ! ${pkgs.xclip}/bin/xclip -selection clipboard -out -target "$x_target" >"$tmp" 2>/dev/null; then
              type="text/plain;charset=utf-8"
              if ! ${pkgs.xsel}/bin/xsel -ob >"$tmp" 2>/dev/null; then
                rm -f "$tmp"
                continue
              fi
            fi
            ;;
        esac

        if state_matches "x11" "$type" "$tmp"; then
          rm -f "$tmp"
          continue
        fi

        save_state "x11" "$type" "$tmp"

        if state_matches "wayland" "$type" "$tmp"; then
          rm -f "$tmp"
          continue
        fi

        ${pkgs.wl-clipboard}/bin/wl-copy --type "$type" <"$tmp" || true
        save_state "wayland" "$type" "$tmp"
        rm -f "$tmp"
      done
    }

    case "''${1:-}" in
      wl-to-x)
        sync_wl_to_x
        ;;
      *)
        sync_x_to_wl &
        exec ${pkgs.wl-clipboard}/bin/wl-paste --watch "$0" wl-to-x
        ;;
    esac
  '';
in
{
  environment.sessionVariables = {
    NIRI_CONFIG = "/etc/niri/config.kdl";
  };

  environment.etc."niri/config.kdl".source = ../niri-config.kdl;
  environment.etc."niri/clipboard-bridge.sh".source = clipboardBridge;

  systemd.user.services.niri-clipboard-bridge = {
    description = "Bridge clipboard between Wayland and Xwayland";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    path = with pkgs; [
      coreutils
      diffutils
    ];
    serviceConfig = {
      ExecStart = "/etc/niri/clipboard-bridge.sh";
      Restart = "always";
      RestartSec = 1;
    };
  };

  # Auto-mount removable drives for the logged-in desktop user.
  systemd.user.services.udiskie = {
    description = "Auto-mount removable media";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "niri.service"
    ];
    path = with pkgs; [ xdg-utils ];
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "zeus-udiskie-session" ''
        set -eu

        runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        export XDG_RUNTIME_DIR="$runtime_dir"

        if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
          attempt=0
          while [ "$attempt" -lt 10 ]; do
            for socket in "$runtime_dir"/wayland-*; do
              if [ -S "$socket" ]; then
                export WAYLAND_DISPLAY="$(basename "$socket")"
                break 2
              fi
            done
            attempt=$((attempt + 1))
            ${pkgs.coreutils}/bin/sleep 1
          done
        fi

        exec ${pkgs.udiskie}/bin/udiskie \
          --automount \
          --notify \
          --tray \
          --file-manager ${pkgs.xdg-utils}/bin/xdg-open
      '';
      Environment = [ "LC_ALL=C.UTF-8" ];
      Restart = "on-failure";
      RestartSec = 1;
    };
  };

  programs.niri = {
    enable = true;
    useNautilus = true;
  };
  services.displayManager.ly.enable = true;
  services.displayManager.defaultSession = "niri";

  services.dbus.packages =
    let
      filteredSystemDbus = pkgs.runCommand "filtered-system-dbus" { } ''
        copy_dir() {
          local source_dir="$1"
          local target_dir="$2"

          if [ -d "$source_dir" ]; then
            mkdir -p "$target_dir"
            for entry in "$source_dir"/*; do
              [ -e "$entry" ] || continue
              ln -s "$entry" "$target_dir/"
            done
          fi
        }

        copy_dir ${config.system.path}/etc/dbus-1/system.d $out/etc/dbus-1/system.d
        copy_dir ${config.system.path}/share/dbus-1/system.d $out/share/dbus-1/system.d
        copy_dir ${config.system.path}/share/dbus-1/system-services $out/share/dbus-1/system-services

        rm -f $out/share/dbus-1/system-services/org.freedesktop.resolve1.service
      '';
    in
    lib.mkForce [
      config.services.dbus.dbusPackage
      filteredSystemDbus
      pkgs.gcr
      pkgs.nautilus
    ];
}
