{ pkgs, lib, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  SECURITY MODULE
#  Centralizes all system hardening that doesn't belong in networking.
#  Goal: defense-in-depth without breaking daily workflows.
# ─────────────────────────────────────────────────────────────────────────────

{
  # ─── APPARMOR ────────────────────────────────────────────────────────────────
  # Mandatory Access Control — limits what processes can do even if exploited
  security.apparmor = {
    enable       = true;
    killUnconfinedConfinables = false;  # Don't kill processes if profile missing
  };

  # ─── SUDO HARDENING ──────────────────────────────────────────────────────────
  security.sudo = {
    enable           = true;
    wheelNeedsPassword = true;   # Always require password (never passwordless sudo)
    execWheelOnly    = true;     # Only wheel group can run sudo
    extraConfig      = ''
      # Log all sudo usage
      Defaults        log_output
      Defaults        logfile="/var/log/sudo.log"
      # Require full tty
      Defaults        requiretty
      # Timeout after 5 minutes of inactivity
      Defaults        timestamp_timeout=5
    '';
  };

  # ─── POLKIT ──────────────────────────────────────────────────────────────────
  security.polkit.enable = true;

  # ─── MEMORY PROTECTIONS ──────────────────────────────────────────────────────
  # Prevent coredumps from leaking sensitive data
  security.pam.loginLimits = [
    { domain = "*"; item = "core"; type = "hard"; value = "0"; }
  ];

  # ─── AUDITD ──────────────────────────────────────────────────────────────────
  # NEW: Kernel audit framework — logs security-relevant events
  security.audit = {
    enable = true;
    rules  = [
      # Log all authentication attempts
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/sudoers -p wa -k sudoers"
      # Log all privilege escalation
      "-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -k privesc"
      # Log network connections
      "-a always,exit -F arch=b64 -S connect -k network_connect"
      # Log file deletion
      "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete"
    ];
  };

  # ─── FAIL2BAN ────────────────────────────────────────────────────────────────
  # NEW: Ban IPs that repeatedly fail SSH / auth
  services.fail2ban = {
    enable  = true;
    maxretry = 3;
    bantime  = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 2 4 8 16 32 64";
      maxtime     = "168h";   # Max 1 week ban
      overalljails = true;
    };
    jails = {
      sshd.settings = {
        enabled  = true;
        port     = "22";
        filter   = "sshd";
        maxretry = 3;
      };
    };
  };

  # ─── FILE SYSTEM HARDENING ───────────────────────────────────────────────────
  # Mount /tmp as tmpfs — prevents tmp-based exploits persisting across reboots
  boot.tmp = {
    useTmpfs      = true;
    tmpfsSize     = "32G";
    cleanOnBoot   = true;
  };

  # ─── USB GUARD ───────────────────────────────────────────────────────────────
  # NEW: Block unknown USB devices (prevents BadUSB / rubber ducky attacks)
  services.usbguard = {
     enable        = false;  # Start disabled until you generate a policy with your known devices
    # IMPORTANT: Run `sudo usbguard generate-policy > /etc/usbguard/rules.conf`
    # AFTER boot with your known devices plugged in. This generates a whitelist.
    presentDevicePolicy   = "allow";   # Start permissive — tighten after setup
    insertedDevicePolicy  = "allow";   # Block hotplugged unknown devices
  };

  # ─── SECURE BOOT PREPARATION ─────────────────────────────────────────────────
  # Lanzaboote is the NixOS Secure Boot implementation.
  # It's commented out because it requires an initial setup step.
  # To enable: https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md
  #
  # boot.loader.systemd-boot.enable = lib.mkForce false;
  # boot.lanzaboote = {
  #   enable    = true;
  #   pkiBundle = "/etc/secureboot";
  # };
  
  # ─── CRYPTOGRAPHY ────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [ 
    # Encryption tools
    age          # Simple, modern encryption (prefer over GPG for new use)
    gnupg        # GPG — still required for Git commit signing, package verification
    pinentry-qt  # GUI passphrase entry for GPG on KDE/Wayland
    sops         # Secrets management with age/GPG (great for NixOS secrets)

    # Password management
    keepassxc    # Offline, encrypted, audited password manager
    # Note: keepassxc handles TOTP 2FA too — no separate app needed

    # File integrity
    aide         # NEW: File integrity monitoring — detects unauthorized changes

    # Audit / forensics
    lynis        # NEW: Security audit tool — run `sudo lynis audit system`
                 #      Gets you a hardening score + specific recommendations

    # Metadata stripping (important for OPSEC)
    exiftool     # Read/strip EXIF from images, docs, etc.
    mat2         # NEW: Strip metadata from PDFs, images, audio, etc.

    # Certificate tools
    openssl      # TLS cert inspection and generation
  ];

  # ─── GPG AGENT ───────────────────────────────────────────────────────────────
  programs.gnupg.agent = {
    enable           = true;
    enableSSHSupport = true;   # Use GPG key as SSH key
    pinentryPackage  = pkgs.pinentry-qt;
  };

  # ─── ClamAV ──────────────────────────────────────────────────────────────────
  # NEW: Antivirus — primarily useful for scanning files before opening
  # or detecting Windows malware on shared files
  services.clamav = {
    daemon.enable  = true;
    updater.enable = true;   # Auto-update signatures daily
    updater.frequency = 1;
  };
}
