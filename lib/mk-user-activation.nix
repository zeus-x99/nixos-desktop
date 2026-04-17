{
  lib,
  userSettings,
}:
{
  name,
  dryMessage ? "would install ${userSettings.name} ${name} files",
  dirs ? [ ],
  files ? [ ],
  seedFiles ? [ ],
  emptyFiles ? [ ],
  removePaths ? [ ],
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
    let
      targetPath = mkTargetPath target;
      parentPath = builtins.dirOf targetPath;
    in
    ''
      install -d -m 0755 -o ${q userSettings.name} -g ${q userSettings.group} ${q parentPath}
      install -m ${mode} -o ${q userSettings.name} -g ${q userSettings.group} ${q (toString source)} ${q targetPath}
    '';

  mkSeedFileCommand =
    file:
    let
      targetPath = mkTargetPath file.target;
    in
    ''
      if [ ! -e ${q targetPath} ]; then
        ${mkFileCommand file}
      fi
    '';

  mkEmptyFileCommand =
    {
      target,
      mode ? "0644",
      createOnly ? false,
    }:
    let
      targetPath = mkTargetPath target;
      parentPath = builtins.dirOf targetPath;
      createCommand =
        if createOnly then
          ''
            if [ ! -e ${q targetPath} ]; then
              : > ${q targetPath}
            fi
          ''
        else
          ": > ${q targetPath}";
    in
    ''
      install -d -m 0755 -o ${q userSettings.name} -g ${q userSettings.group} ${q parentPath}
      ${createCommand}
      chown ${q "${userSettings.name}:${userSettings.group}"} ${q targetPath}
      chmod ${mode} ${q targetPath}
    '';

  mkRemovePathCommand = path: "rm -rf ${q (mkTargetPath path)}";

  activationCommands =
    (map mkDirCommand dirs)
    ++ (map mkRemovePathCommand removePaths)
    ++ commands
    ++ (map mkEmptyFileCommand emptyFiles)
    ++ (map mkSeedFileCommand seedFiles)
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
