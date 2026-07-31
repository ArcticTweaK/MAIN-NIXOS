{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.core.boot;
in
{
  options.arctic.core.boot = {
    enable = lib.mkEnableOption "core boot configuration" // { default = true; };

    kernelPackage = lib.mkOption {
      type = lib.types.raw;
      default = pkgs.linuxPackages_6_12;
      defaultText = "pkgs.linuxPackages_6_12";
      description = ''
        Kernel package set. Pinned rather than `linuxPackages_latest` because the
        NVIDIA out-of-tree module regularly lags the newest kernel by a release
        or two, and a kernel the driver won't build against is an unbootable GPU.
      '';
    };

    tmpfsSize = lib.mkOption {
      type = lib.types.str;
      default = "50%";
      description = ''
        Size of the /tmp tmpfs.

        Percentages, not absolutes: the nix daemon builds in /tmp, and a fixed
        size at or near total RAM lets one large Chromium/Electron build OOM the
        whole machine.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    boot.loader.efi.canTouchEfiVariables = true;

    boot.kernelPackages = cfg.kernelPackage;

    # systemd in the initrd: better LUKS handling, proper unit ordering,
    # and a prerequisite for TPM/FIDO2 unlock should we ever want it.
    boot.initrd.systemd.enable = true;

    boot.tmp = {
      useTmpfs = true;
      tmpfsSize = cfg.tmpfsSize;
      cleanOnBoot = true;
    };
  };
}
