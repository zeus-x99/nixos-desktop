{ lib, ... }:
let
  importModules = import ../../lib/import-modules.nix { inherit lib; };
in
{
  imports = importModules ./.;
}

