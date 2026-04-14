{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  initFile = "${userSettings.home}/.cache/starship/init.nu";
in

{
  users.users.${userSettings.name}.packages = with pkgs; [ starship ];
} // mkUserActivation {
  name = "zeusStarshipFiles";
  dryMessage = "would install ${userSettings.name} starship files";
  dirs = [ ".cache/starship" ];
  commands = [
    "tmp=\"$(${pkgs.coreutils}/bin/mktemp)\""
    "${pkgs.starship}/bin/starship init nu > \"$tmp\""
    "install -m 0644 -o ${lib.escapeShellArg userSettings.name} -g ${lib.escapeShellArg userSettings.group} \"$tmp\" ${lib.escapeShellArg initFile}"
    "rm -f \"$tmp\""
  ];
}
