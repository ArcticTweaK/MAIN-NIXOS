{ config, lib, ... }:

let
  cfg = config.arctic.security.secureboot;
in
{
  options.arctic.security.secureboot = {
    enable = lib.mkEnableOption ''
      UEFI Secure Boot via lanzaboote.

      Replaces systemd-boot with a bootloader that signs the kernel, initrd
      and stub with YOUR keys, so firmware refuses to boot anything you did
      not build. This is the control that closes the evil-maid gap left open
      by full-disk encryption: LUKS protects data at rest, but /boot is
      unencrypted and an attacker with physical access can otherwise swap in
      a kernel that captures your passphrase.

      SAFE WITH NVIDIA ON THIS SYSTEM. The usual worry — Secure Boot engaging
      kernel lockdown and refusing the unsigned out-of-tree NVIDIA module —
      cannot happen here: nixpkgs' kernel is built with
      CONFIG_SECURITY_LOCKDOWN_LSM unset (and CONFIG_MODULE_SIG unset), so
      there is no lockdown LSM for Secure Boot to trigger.

      Requires a one-time firmware step. See README.md
    '';

    pkiBundle = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/sbctl";
      description = ''
        Where sbctl keeps the platform keys.

        NOT in git, and not recoverable — if you lose these with Secure Boot
        enforcing, recovery means clearing the keys in firmware. Back the
        directory up alongside the sops age key, and note it is on the
        impermanence persist list.
      '';
    };

    autoProvision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Let lanzaboote generate and stage the keys itself on first boot,
        instead of running `sbctl create-keys && sbctl enroll-keys` by hand.

        This also flips `allowUnsigned`, which is what makes a fresh install
        possible at all: the very first nixos-install has to write bootloader
        artifacts to the ESP before any keys exist.
      '';
    };

    includeMicrosoftKeys = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Also enroll Microsoft's certificates.

        Keep this true. Many boards ship option ROMs (notably on discrete
        GPUs) signed only by Microsoft's UEFI CA; excluding them can leave you
        with a machine that will not POST to a display. lanzaboote asserts
        this unless you explicitly acknowledge the brick risk.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # lanzaboote replaces systemd-boot rather than sitting alongside it.
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      inherit (cfg) pkiBundle;

      autoGenerateKeys.enable = cfg.autoProvision;

      autoEnrollKeys = lib.mkIf cfg.autoProvision {
        enable = true;
        inherit (cfg) includeMicrosoftKeys;
        # Requires a manual reboot into firmware to complete enrollment, which
        # is the point at which you get to change your mind.
        autoReboot = false;
      };
    };
  };
}
