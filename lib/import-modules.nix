{ lib }:
dir:
let
  files = builtins.readDir dir;
  nixFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
  ) files;
in
map (name: dir + "/${name}") (builtins.attrNames nixFiles)

