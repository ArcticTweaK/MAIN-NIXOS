{ config, lib, ... }:

let
  cfg = config.arctic.core.nix;
in
{
  options.arctic.core.nix = {
    enable = lib.mkEnableOption "nix daemon settings and GC" // { default = true; };

    trustedUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "root" ];
      description = ''
        Users granted `trusted-user` status on the nix daemon.

        Be careful here: a trusted user is ROOT-EQUIVALENT. They can set
        `post-build-hook` / `builders` per invocation (which the daemon runs as
        root) and import unsigned paths into the store. Do not add your login
        user "for convenience" — if you need a third-party cache, add it to
        `trustedSubstituters` below instead, which is the narrow version of the
        same permission.
      '';
    };

    trustedSubstituters = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "https://nix-community.cachix.org" ];
      description = "Caches a non-trusted user is allowed to opt into.";
    };

    trustedPublicKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Signing keys matching `trustedSubstituters`.";
    };

    allowUnfree = lib.mkEnableOption "unfree packages" // { default = true; };

    permittedInsecurePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Every entry here MUST carry a comment saying what needs it and why the
        risk is accepted. Unexplained entries outlive their reason.
      '';
    };

    gc = {
      enable = lib.mkEnableOption "automatic garbage collection" // { default = true; };
      dates = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
      };
      keepDays = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Generations younger than this survive GC. This is also your rollback window.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config = {
      allowUnfree = cfg.allowUnfree;
      permittedInsecurePackages = cfg.permittedInsecurePackages;
    };

    nix.settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      sandbox = true;
      max-jobs = "auto";
      cores = 0;

      trusted-users = cfg.trustedUsers;
      trusted-substituters = cfg.trustedSubstituters;
      trusted-public-keys = cfg.trustedPublicKeys;

      # Keep build inputs of the current system around so `nix develop` and
      # rebuilds after a GC don't re-download the world.
      keep-outputs = true;
      keep-derivations = true;
    };

    nix.gc = lib.mkIf cfg.gc.enable {
      automatic = true;
      dates = cfg.gc.dates;
      options = "--delete-older-than ${toString cfg.gc.keepDays}d";
    };
  };
}
