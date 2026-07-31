{ config, lib, ... }:

let
  cfg = config.arctic.security.secrets;
  users = config.arctic.core.users;
in
{
  options.arctic.security.secrets = {
    enable = lib.mkEnableOption "sops-nix secret decryption";

    ageKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sops-nix/key.txt";
      description = ''
        The age identity that decrypts ./secrets/*.yaml.

        This file is the root of trust for the whole config and it is NOT in
        git. Lose it and every encrypted value is unrecoverable; leak it and
        they are all public. Back it up somewhere off this machine before you
        depend on it.

        On a fresh install it must be in place BEFORE the first activation —
        `disko-install --extra-files` puts it there at the right moment. See
        README.md.
      '';
    };

    defaultSopsFile = lib.mkOption {
      type = lib.types.path;
      default = ../../../secrets/arctic.yaml;
      description = "Encrypted file that secrets are read from by default.";
    };

    managePasswords = lib.mkEnableOption ''
      sourcing account passwords from sops.

      READ BEFORE ENABLING. This points users.users.*.hashedPasswordFile at a
      decrypted secret. If decryption fails, the affected accounts get "!"
      (locked) and you are locked out with no recovery except a live USB.

      Turn this on only once `sops secrets/arctic.yaml` contains REAL yescrypt
      hashes under arctic-password and root-password, and verify with
      `sudo cat /etc/shadow` before you log out
    '';
  };

  config = lib.mkIf cfg.enable {
    sops = {
      inherit (cfg) defaultSopsFile;
      defaultSopsFormat = "yaml";

      # An explicit age identity, deliberately NOT sops.age.sshKeyPaths (this
      # host runs no sshd, so there is no host key to derive one from) and
      # deliberately NOT sops.age.generateKey — that creates a FRESH key when
      # the file is missing, which cannot decrypt anything encrypted earlier.
      # A missing key here should be a loud failure, not a silent new identity.
      age.keyFile = cfg.ageKeyFile;

      secrets = lib.mkIf cfg.managePasswords {
        # neededForUsers moves decryption ahead of user creation in the
        # activation order (the secret lands in /run/secrets-for-users, not
        # /run/secrets). Without it, users are created before the hash exists.
        # sops-nix asserts these must be root-owned.
        "arctic-password".neededForUsers = true;
        "root-password".neededForUsers = true;
      };
    };

    arctic.core.users.primary.hashedPasswordFile =
      lib.mkIf cfg.managePasswords config.sops.secrets."arctic-password".path;

    users.users.root.hashedPasswordFile =
      lib.mkIf cfg.managePasswords config.sops.secrets."root-password".path;

    assertions = [
      {
        # With mutableUsers = false a failed decryption re-asserts "!" on every
        # activation and `passwd` cannot rescue you. With true, the sops hash
        # seeds the account on first creation and passwd still works after.
        assertion = cfg.managePasswords -> users.mutableUsers;
        message = ''
          arctic.security.secrets.managePasswords with users.mutableUsers = false
          is a lockout risk: if the sops secret ever fails to decrypt, every
          account is set to "!" on activation and `passwd` cannot recover it.
        '';
      }
    ];
  };
}
