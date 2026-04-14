{ lib, userSettings, ... }:

{
  users.users.${userSettings.name} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  security.sudo.extraRules = lib.mkAfter [
    {
      users = [ userSettings.name ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
