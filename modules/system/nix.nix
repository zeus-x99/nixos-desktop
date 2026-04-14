{ userSettings, ... }:

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
      auto-optimise-store = true;
      trusted-users = [
        "root"
        userSettings.name
      ];
    };
  };
}
