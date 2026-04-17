{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };
  starshipInit = pkgs.runCommandLocal "zeus-starship-init.nu" {
    nativeBuildInputs = [ pkgs.starship ];
  } ''
    starship init nu > "$out"
  '';
in

mkUserActivation {
  name = "zeusStarshipFiles";
  dryMessage = "would install ${userSettings.name} starship files";
  files = [
    {
      source = starshipInit;
      target = ".cache/starship/init.nu";
    }
  ];
}
