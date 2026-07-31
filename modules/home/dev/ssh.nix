{ config, lib, ... }:

let
  cfg = config.arctic.dev.ssh;
in
{
  options.arctic.dev.ssh = {
    enable = lib.mkEnableOption "a hardened SSH client configuration" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      # Opt out of home-manager's implicit defaults and state every value
      # explicitly. The implicit set is deprecated upstream, and for a client
      # config "what exactly is in effect" should never require reading
      # someone else's module to find out.
      enableDefaultConfig = false;

      settings."*" = {
        # ── Connection ────────────────────────────────────────────────────
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        Compression = false;

        # ── Host verification ─────────────────────────────────────────────
        # Hash hostnames so a stolen known_hosts doesn't enumerate everywhere
        # you connect.
        HashKnownHosts = true;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        StrictHostKeyChecking = "ask";

        # ── Key handling ──────────────────────────────────────────────────
        # Offer ONLY the key configured for a host. Without this, ssh walks the
        # whole agent and leaks every public key you hold to every server you
        # touch — a free fingerprint of your identity across unrelated hosts.
        IdentitiesOnly = true;

        # Never forward the agent by default: it lets whoever controls the
        # remote host use your keys for as long as you stay connected.
        ForwardAgent = false;
        AddKeysToAgent = "no";

        # ── Cryptography ──────────────────────────────────────────────────
        # AEAD ciphers only.
        Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
        # Encrypt-then-MAC only.
        MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com";
        # Curve25519 key exchange only.
        KexAlgorithms = "curve25519-sha256,curve25519-sha256@libssh.org";
        # Ed25519 and RSA-SHA2 only — excludes ssh-rsa (SHA-1).
        HostKeyAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256";
        PubkeyAcceptedAlgorithms = "ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256";

        # ── Multiplexing ──────────────────────────────────────────────────
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
    };
  };
}
