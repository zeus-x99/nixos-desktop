{ pkgs, userSettings, ... }:

{
  environment.shells = [ pkgs.nushell ];

  users.users.${userSettings.name} = {
    shell = pkgs.nushell;
  };
}
