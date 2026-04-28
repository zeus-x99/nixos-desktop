{ config, lib, pkgs, ... }:
let
  hostName = config.networking.hostName;
  mqttPasswordFile = "/run/secrets/ha-system-ronitor-mqtt-password";
  mqttPasswordPlaceholder = "__HA_SYSTEM_RONITOR_MQTT_PASSWORD__";
  settings = {
    mqtt = {
      host = "10.0.0.1";
      port = 1883;
      username = "homeassistant";
    };

    device = {
      node_id = hostName;
      name = "${hostName} System Monitor";
    };

    disk.include_paths = [ "/" ];
  };
  renderedConfig = (pkgs.formats.toml { }).generate "ha-system-ronitor-config.toml" (
    lib.recursiveUpdate settings {
      mqtt.password = mqttPasswordPlaceholder;
    }
  );
in
{
  services.ha-system-ronitor = {
    enable = true;
    inherit mqttPasswordFile;
    inherit settings;
  };

  systemd.services.ha-system-ronitor = {
    unitConfig.ConditionPathExists = mqttPasswordFile;
    preStart = lib.mkForce ''
      install -d -m 0750 /run/ha-system-ronitor
      cp ${renderedConfig} /run/ha-system-ronitor/config.toml
      ${pkgs.python3}/bin/python - <<'PY'
from pathlib import Path
import json

config_path = Path("/run/ha-system-ronitor/config.toml")
password_path = Path("${mqttPasswordFile}")
placeholders = [
    '"${mqttPasswordPlaceholder}"',
    "'${mqttPasswordPlaceholder}'",
]

password = password_path.read_text(encoding="utf-8").rstrip("\r\n")
content = config_path.read_text(encoding="utf-8")
rendered = content
for placeholder in placeholders:
    rendered = rendered.replace(placeholder, json.dumps(password))

if rendered == content:
    raise RuntimeError("MQTT password placeholder was not replaced")

config_path.write_text(rendered, encoding="utf-8")
PY
    '';
  };
}
