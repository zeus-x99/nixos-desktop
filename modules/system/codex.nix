{ ... }:

{
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/bwrap - - - - /run/current-system/sw/bin/bwrap"
  ];
}
