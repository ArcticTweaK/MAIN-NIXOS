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

      # Event log only: who ran what, when. Deliberately NOT `log_output`,
      # which records full terminal transcripts into an unrotated, unbounded
      # /var/log/sudo-io/ — including the output of anything you
      # `sudo cat /run/secrets/*`. That turns the audit trail into the single
      # richest secret store on the box.
      #
      # Also deliberately absent:
      #   requiretty        breaks sudo from systemd units, scripts and pipes
      #   timestamp_timeout=5   already sudo's compiled-in default; a no-op
      extraConfig = ''
        Defaults        logfile="/var/log/sudo.log"
      '';
    };

    security.polkit.enable = true;

    # Coredumps can contain decrypted secrets, session keys and passwords.
    security.pam.loginLimits = [
      { domain = "*"; item = "core"; type = "hard"; value = "0"; }
    ];
  };
}
