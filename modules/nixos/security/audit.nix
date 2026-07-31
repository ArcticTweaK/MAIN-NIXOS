{ config, lib, ... }:

let
  cfg = config.arctic.security.audit;
in
{
  options.arctic.security.audit = {
    enable = lib.mkEnableOption ''
      the kernel audit framework AND the auditd userspace daemon.

      Note it needs both. security.audit alone loads rules into the kernel
      with no consumer: no /var/log/audit/audit.log and no ausearch, with
      records going only to the kernel ring buffer
    '';
  };

  config = lib.mkIf cfg.enable {
    # The daemon. Without this there is no audit.log and ausearch has nothing
    # to read — which was the previous state of this config.
    security.auditd.enable = true;

    security.auditd.settings = {
      max_log_file = 50; # MB per file
      num_logs = 5; # 250 MB ceiling total
      max_log_file_action = "ROTATE";
      space_left = "15%";
      space_left_action = "syslog";
      admin_space_left = "5%";
      admin_space_left_action = "syslog";
      # Never halt or go single-user on a full disk. On a workstation that is
      # a self-inflicted denial of service, not a security control.
      disk_full_action = "syslog";
      disk_error_action = "syslog";
    };

    security.audit = {
      enable = true;
      backlogLimit = 8192;

      rules = [
        # Identity and privilege files.
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/sudoers -p wa -k sudoers"
        "-w /etc/sudoers.d -p wa -k sudoers"

        # The two directories that hold this machine's roots of trust.
        "-w /var/lib/sops-nix -p wa -k secrets"
        "-w /var/lib/sbctl -p wa -k secureboot"

        # Privilege escalation. -F auid!=-1 skips records with an unset audit
        # ID (daemons), which otherwise dominate the log.
        "-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=-1 -k privesc"

        # Kernel module loading.
        "-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k modules"
      ];

      # Two rules from the previous config are deliberately gone, both because
      # they made the log unreadable rather than because they were wrong:
      #
      #   -S connect
      #       one record per outbound socket. With a browser, Tor and
      #       containers running, that is tens of thousands per minute.
      #
      #   -S unlink -S unlinkat -S rename -S renameat
      #       nearly as bad on a Nix machine specifically: every build, every
      #       GC and every nixos-rebuild generates thousands of records.
      #
      # An audit log nobody can read is worse than no audit log, because it
      # looks like coverage.
    };
  };
}
