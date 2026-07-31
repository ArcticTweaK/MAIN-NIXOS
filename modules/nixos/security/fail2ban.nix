{ config, lib, ... }:

let
  cfg = config.arctic.security.fail2ban;
in
{
  options.arctic.security.fail2ban = {
    enable = lib.mkEnableOption ''
      fail2ban.

      Only worth enabling if this host actually runs a network service that
      accepts authentication. With no sshd and no open ports there is nothing
      for it to watch
    '';
  };

  # FIXME(commit 6): the only jail is sshd, and there is no sshd on this host
  # (services.openssh is not enabled anywhere and port 22 is closed). Deleted
  # in commit 6.
  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 3;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
      jails.sshd.settings = {
        enabled = true;
        port = "22";
        filter = "sshd";
        maxretry = 3;
      };
    };
  };
}
