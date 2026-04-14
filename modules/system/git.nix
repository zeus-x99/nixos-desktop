{ userSettings, ... }:

{
  programs.git = {
    enable = true;
    config = {
      user = {
        name = userSettings.name;
        email = "zeus1999@vip.qq.com";
      };
      init.defaultBranch = "main";
    };
  };
}
