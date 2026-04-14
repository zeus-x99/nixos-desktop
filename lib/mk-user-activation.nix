{
  lib,
  userSettings,
}:
{
  name,
  dryMessage ? "would install ${userSettings.name} ${name} files",
  dirs ? [ ],
  files ? [ ],
  commands ? [ ],
  deps ? [ "users" ],
}:
let
  q = lib.escapeShellArg;

  mkTargetPath =
    path:
    let
      pathString = toString path;
    in
    if lib.hasPrefix "/" pathString then pathString else "${userSettings.home}/${pathString}";

  mkDirCommand = dir:
    "install -d -m 0755 -o ${q userSettings.name} -g ${q userSettings.group} ${q (mkTargetPath dir)}";

  mkFileCommand =
    {
      source,
      target,
      mode ? "0644",
    }:
    "install -m ${mode} -o ${q userSettings.name} -g ${q userSettings.group} ${q (toString source)} ${q (mkTargetPath target)}";

  activationCommands =
    (map mkDirCommand dirs)
    ++ commands
    ++ (map mkFileCommand files);

  activationBody =
    if builtins.length activationCommands == 0 then
      ":"
    else
      lib.concatStringsSep "\n        " activationCommands;
in
{
  system.activationScripts.${name} = {
    inherit deps;
    text = ''
      if [ "$NIXOS_ACTION" = "dry-activate" ]; then
        echo ${q dryMessage}
      else
        ${activationBody}
      fi
    '';
  };
}
