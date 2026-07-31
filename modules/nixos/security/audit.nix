{ config, lib, ... }:

let
  cfg = config.arctic.security.audit;
in
{
  options.arctic.security.audit = {
    enable = lib.mkEnableOption "the kernel audit framework";
  };

  # FIXME(commit 6): security.audit alone loads rules into the kernel with NO
  # userspace consumer — there is no auditd, no /var/log/audit/audit.log and
  # no ausearch workflow. The `-S connect` and unlink/rename rules also flood
  # the journal on a desktop (every socket, every nix build). Fixed in commit 6.
  config = lib.mkIf cfg.enable {
    security.audit = {
      enable = true;
      rules = [
        # identity / privilege files
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
        "-w /etc/sudoers -p wa -k sudoers"
        # privilege escalation
        "-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k privesc"
        # network connections
        "-a always,exit -F arch=b64 -S connect -k network_connect"
        # file deletion
        "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete"
      ];
    };
  };
}
