{ config, ... }:
let
  hostName = config.networking.hostName;
  mqttPasswordFile = "/run/secrets/ha-system-ronitor-mqtt-password";
in
{
  services.ha-system-ronitor = {
    enable = true;
    inherit mqttPasswordFile;

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
  };

  systemd.services.ha-system-ronitor.unitConfig.ConditionPathExists = mqttPasswordFile;
}
