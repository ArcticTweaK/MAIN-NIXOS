{ config, lib, ... }:

let
  cfg = config.arctic.security.usbguard;
in
{
  options.arctic.security.usbguard = {
    enable = lib.mkEnableOption ''
      USBGuard (BadUSB / rogue-HID defence).

      Real friction on a desktop with a Wooting, a Pico and controllers: every
      new device is blocked until explicitly allowed. Only meaningful with
      insertedDevicePolicy = "block" AND a generated allowlist committed to the
      repo — anything less is decoration
    '';
  };

  # FIXME(commit 6): currently off, and even if switched on both policies are
  # "allow", so it would block nothing. Deleted in commit 6.
  config = lib.mkIf cfg.enable {
    services.usbguard = {
      enable = true;
      presentDevicePolicy = "allow";
      insertedDevicePolicy = "allow";
    };
  };
}
