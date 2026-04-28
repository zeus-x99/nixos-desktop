{ lib, userSettings, ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = lib.mkForce [
        "https://mirrors.ustc.edu.cn/nix-channels/store?priority=39"
        "https://cache.nixos.org/"
      ];
      auto-optimise-store = true;
      trusted-users = [
        "root"
        userSettings.name
      ];
    };
  };
}
