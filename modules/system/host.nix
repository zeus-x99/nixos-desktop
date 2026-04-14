{ ... }:

{
  system.stateVersion = "25.11";

  networking.hostName = "nixos";

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  environment.variables = {
    COLORTERM = "truecolor";
    TERM = "xterm-256color";
  };
}
