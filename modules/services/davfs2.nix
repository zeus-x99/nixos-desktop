{ config, userSettings, ... }:
let
  davfsMountPoint = "/mnt/webdav";
in
{
  services.davfs2 = {
    enable = true;
    settings = {
      globalSection = {
        cache_dir = "/var/cache/davfs2";
        cache_size = 16384;
        table_size = 4096;
        buf_size = 256;
        connect_timeout = 30;
        read_timeout = 300;
        retry = 30;
        max_retry = 300;
        max_upload_attempts = 8;
        file_refresh = 2;
        backup_dir = ".davfs-backup";
        minimize_mem = true;
      };

      sections.${davfsMountPoint} = {
        use_locks = true;
        lock_owner = "x-zeus-davfs";
        gui_optimize = true;
        dir_refresh = 15;
        delay_upload = 2;
      };
    };
  };

  environment.etc."davfs2/secrets".source = config.sops.templates."davfs2-secrets".path;

  fileSystems.${davfsMountPoint} = {
    device = "https://ol.imagic.wiki/dav/";
    fsType = "davfs";
    options = [
      "uid=${userSettings.name}"
      "gid=${userSettings.group}"
      "dir_mode=0775"
      "file_mode=0664"
      "rw"
      "x-systemd.automount"
      "noauto"
      "_netdev"
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${davfsMountPoint} 0755 ${userSettings.name} ${userSettings.group} -"
    "L+ ${userSettings.home}/webdav-davfs - - - - ${davfsMountPoint}"
  ];
}
