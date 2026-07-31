{ config, lib, ... }:

let
  cfg = config.arctic.security.sudo;
in
{
  options.arctic.security.sudo = {
    harden = lib.mkEnableOption "sudo hardening" // { default = true; };
  };

  config = lib.mkIf cfg.harden {
    security.sudo = {
      enable = true;

      # Both of these are real and both are free.
      wheelNeedsPassword = true;
      execWheelOnly = true;

      # FIXME(commit 2):
      #   requiretty        breaks sudo from systemd units, pipes and scripts
      #   log_output        writes FULL terminal transcripts (including anything
      #                     you `sudo cat`) to an unrotated /var/log/sudo-io/
      #   timestamp_timeout 5 is already sudo's compiled-in default — a no-op
      extraConfig = ''
        # Log all sudo usage
        Defaults        log_output
        Defaults        logfile="/var/log/sudo.log"
        # Require full tty
        Defaults        requiretty
        # Timeout after 5 minutes of inactivity
        Defaults        timestamp_timeout=5
      '';
    };

    security.polkit.enable = true;

    # Coredumps can contain decrypted secrets, session keys and passwords.
    security.pam.loginLimits = [
      { domain = "*"; item = "core"; type = "hard"; value = "0"; }
    ];
  };
}
