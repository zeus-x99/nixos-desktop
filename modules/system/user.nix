{ lib, pkgs, userSettings, ... }:

{
  users.users.${userSettings.name} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
    ];
    packages = with pkgs; [
      qq
      wechat
      alacritty
      fuzzel
      obs-studio
      codex
      helix
      nushell
      starship
      wl-clipboard
      xsel
      pciutils
      ripgrep
      gh
      jq
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
