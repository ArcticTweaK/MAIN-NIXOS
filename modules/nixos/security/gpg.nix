{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.security.gpg;
in
{
  options.arctic.security.gpg = {
    enable = lib.mkEnableOption "the GnuPG agent" // { default = true; };

    sshSupport = lib.mkEnableOption "using GPG authentication subkeys as SSH keys" // { default = true; };

    pinentry = lib.mkOption {
      type = lib.types.raw;
      default = pkgs.pinentry-qt;
      defaultText = "pkgs.pinentry-qt";
      description = "Must match the desktop toolkit or the passphrase prompt never appears.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = cfg.sshSupport;
      pinentryPackage = cfg.pinentry;
    };
  };
}
