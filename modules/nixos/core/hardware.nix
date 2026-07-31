{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.core.hardware;
in
{
  options.arctic.core.hardware = {
    enable = lib.mkEnableOption "baseline hardware support" // { default = true; };

    i2c = lib.mkEnableOption "I2C, for DDC/CI monitor brightness control" // { default = true; };
    mtp = lib.mkEnableOption "MTP, for phones mounting as storage" // { default = true; };
    android = lib.mkEnableOption "udev rules for Android/Google (18d1) USB devices";

    appimage = lib.mkEnableOption "AppImage execution via binfmt" // { default = true; };

    nixLd = lib.mkEnableOption "nix-ld, so unpatched foreign ELF binaries run" // { default = true; };
    nixLdLibraries = lib.mkOption {
      type = lib.types.functionTo (lib.types.listOf lib.types.package);
      default = p: with p; [ curl openssl stdenv.cc.cc.lib ];
      defaultText = "p: with p; [ curl openssl stdenv.cc.cc.lib ]";
      description = ''
        Libraries exposed to foreign binaries.

        Keep this list SHORT. nix-ld is a deliberate hole in the "everything is
        a derivation" guarantee: it lets arbitrary downloaded ELF binaries link
        against a curated library set and run unaudited.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.i2c.enable = cfg.i2c;
    hardware.enableRedistributableFirmware = true;

    services.gvfs.enable = cfg.mtp;

    programs.appimage = lib.mkIf cfg.appimage {
      enable = true;
      binfmt = true;
    };

    programs.nix-ld = lib.mkIf cfg.nixLd {
      enable = true;
      libraries = cfg.nixLdLibraries pkgs;
    };

    # TAG+="uaccess" hands the device to whoever is logged in at the seat,
    # via systemd-logind ACLs. The alternative you'll find in most guides —
    # MODE="0666" plus GROUP="plugdev" — is wrong twice over on NixOS: 0666
    # makes the device world-writable to every process on the machine, and
    # `plugdev` is a Debian-ism that does not exist here, so the GROUP= is
    # silently ignored rather than restricting anything.
    services.udev.extraRules = lib.mkIf cfg.android ''
      # Android / Google devices (adb, fastboot, MTP)
      SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", TAG+="uaccess"
    '';
  };
}
