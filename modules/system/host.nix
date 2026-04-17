{ ... }:

{
  system.stateVersion = "25.11";

  networking.hostName = "x";

  time.timeZone = "Asia/Shanghai";

  console.useXkbConfig = true;

  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  services.xserver.xkb = {
    layout = "us";
    model = "pc104";
    options = "terminate:ctrl_alt_bksp";
  };

  environment.variables = {
    COLORTERM = "truecolor";
    TERM = "xterm-256color";
  };
}
