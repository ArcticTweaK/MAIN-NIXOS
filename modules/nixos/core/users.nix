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
  };
}
