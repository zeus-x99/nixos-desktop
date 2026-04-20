{ config, userSettings, ... }:

{
  services.webdav = {
    enable = true;
    user = userSettings.name;
    group = userSettings.group;
    environmentFile = config.sops.templates."webdav.env".path;
    settings = {
      address = "0.0.0.0";
      port = 6065;
      directory = "/srv/webdav";
      permissions = "CRUD";
      users = [
        {
          username = "{env}WEBDAV_USERNAME";
          password = "{env}WEBDAV_PASSWORD";
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 6065 ];

  systemd.tmpfiles.rules = [
    "d /srv/webdav 0755 ${userSettings.name} ${userSettings.group} -"
    "L+ ${userSettings.home}/webdav - - - - /srv/webdav"
  ];
}
