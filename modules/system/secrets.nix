{
  config,
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  secretsFile = ../../secrets/secrets.yaml;
  hasSecretsFile = builtins.pathExists secretsFile;
  codexEnvPath = "/run/secrets/rendered/codex-api.env";
in
{
  environment.systemPackages = with pkgs; [
    age
    sops
    ssh-to-age
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    defaultSopsFile = lib.mkIf hasSecretsFile secretsFile;
    defaultSopsFormat = lib.mkIf hasSecretsFile "yaml";

    secrets = lib.mkIf hasSecretsFile {
      cliproxyapi_api_key = { };
      ha-system-ronitor-mqtt-password = { };
    };

    templates = lib.mkIf hasSecretsFile {
      "codex-api.env" = {
        path = codexEnvPath;
        owner = userSettings.name;
        group = userSettings.group;
        mode = "0400";
        content = ''
          CLIPROXYAPI_API_KEY=${config.sops.placeholder.cliproxyapi_api_key}
        '';
      };
    };
  };
}
