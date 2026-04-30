{ ... }:

{
  boot.extraModprobeConfig = ''
    # MT7922 在这块主板上关闭 ASPM 往往更稳定。
    options mt7921e disable_aspm=Y
  '';

  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
    settings.keyfile.unmanaged-devices = "type:wifi-p2p";

    ensureProfiles.profiles."eno1-static" = {
      connection = {
        id = "eno1-static";
        type = "ethernet";
        interface-name = "eno1";
        autoconnect = true;
        autoconnect-priority = 100;
      };

      ipv4 = {
        method = "manual";
        address1 = "10.0.0.3/24,10.0.0.1";
        dns = "10.0.0.1;";
      };

      ipv6.method = "auto";
    };
  };
}
