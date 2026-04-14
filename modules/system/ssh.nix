{ ... }:

{
  programs.ssh.extraConfig = ''
    Host *
      ServerAliveInterval 60
      ServerAliveCountMax 3
      ForwardAgent no
      AddKeysToAgent no
      Compression no
      HashKnownHosts no
      UserKnownHostsFile ~/.ssh/known_hosts
      ControlMaster no
      ControlPath ~/.ssh/master-%r@%n:%p
      ControlPersist no
  '';
}

