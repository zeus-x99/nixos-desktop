{ userSettings, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = {
      inherit userSettings;
    };
    users.${userSettings.name} = import ../../home/${userSettings.name}.nix;
  };
}
