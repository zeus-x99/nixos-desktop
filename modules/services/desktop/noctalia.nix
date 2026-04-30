{ config, pkgs, ... }:
let
  noctaliaDesktopEntry = pkgs.makeDesktopItem {
    name = "dev.noctalia.noctalia-qs";
    desktopName = "Noctalia Shell";
    genericName = "Desktop Shell";
    comment = "Noctalia desktop shell";
    exec = "${config.services.noctalia-shell.package}/bin/noctalia-shell";
    icon = "nix-snowflake";
    categories = [ "Utility" ];
    startupNotify = false;
  };
in
{
  environment.systemPackages = [
    noctaliaDesktopEntry
    config.services.noctalia-shell.package
  ];
}
