{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.core.users;
in
{
  options.arctic.core.users = {
    enable = lib.mkEnableOption "declarative user accounts" // { default = true; };

    primary = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "arctic";
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "arctic";
      };

      shell = lib.mkOption {
        type = lib.types.raw;
        default = pkgs.fish;
        defaultText = "pkgs.fish";
        description = ''
          Login shell. Must match the shell home-manager configures, or the
          interactive config never loads.
        '';
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = ''
          Supplementary groups.

          NixOS silently DROPS groups that don't exist, so a typo here fails
          open and looks like it worked. Groups created by a `programs.*.enable`
          (wireshark, ydotool) only exist once that option is on.
        '';
      };

      hashedPassword = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          NOTE the difference, it is not cosmetic:
            null  -> no password login via this mechanism (correct default)
            ""    -> EMPTY PASSWORD; anyone at the console gets a shell

          Prefer `hashedPasswordFile` fed from sops — see
          modules/nixos/security/secrets.nix.
        '';
      };

      hashedPasswordFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
      };
    };

    mutableUsers = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Kept TRUE deliberately, and it composes correctly with sops.

        With mutableUsers = true, a declared hash SEEDS the account when it is
        first created (i.e. on a fresh install) and `passwd` still works and
        survives rebuilds afterwards. With false, the hash is re-asserted on
        every activation and `passwd` is futile — which turns a failed secret
        decryption into a lockout.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.mutableUsers = cfg.mutableUsers;

    users.users.${cfg.primary.name} = {
      isNormalUser = true;
      inherit (cfg.primary) description shell extraGroups hashedPassword hashedPasswordFile;
    };

    # On the RUNNING machine this is harmless — mutableUsers = true means the
    # password set by `passwd` is already in /etc/shadow and is left alone.
    #
    # On a FRESH INSTALL it is not harmless: the account is created with "!"
    # and there is no way in. That failure appears only after the reboot, by
    # which point fixing it means booting the ISO again.
    warnings = lib.optional
      (cfg.primary.hashedPassword == null && cfg.primary.hashedPasswordFile == null) ''
      No password source for user "${cfg.primary.name}"
      (both hashedPassword and hashedPasswordFile are null).

      Existing installs are fine — `passwd` already set one and
      users.mutableUsers = true preserves it.

      But a FRESH INSTALL from this config will create a LOCKED account.
      Before reinstalling, do one of:
        - set arctic.security.secrets.managePasswords = true, with real
          hashes in secrets/arctic.yaml (see README phase 0), or
        - run `nixos-enter --root /mnt -- passwd ${cfg.primary.name}`
          during install, BEFORE the first reboot (README phase 4).
    '';
  };
}
