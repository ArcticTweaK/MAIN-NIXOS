{ config, lib, ... }:

let
  cfg = config.arctic.gaming.peripherals;
in
{
  options.arctic.gaming.peripherals = {
    wooting = lib.mkEnableOption "Wooting analog keyboards";
    pico = lib.mkEnableOption "Raspberry Pi Pico / RP2040 (udev access for flashing)";
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.wooting {
      # This already installs pkgs.wooting-udev-rules via services.udev.packages.
      # FIXME(commit 2): the hand-written Wooting rules currently in the legacy
      # gaming module duplicate exactly what this provides. Dropped in commit 2.
      hardware.wooting.enable = true;
    })

    (lib.mkIf cfg.pico {
      # TAG+="uaccess" grants access to whoever is logged in at the seat.
      # This is the correct modern idiom — no group, no world-writable mode.
      services.udev.extraRules = ''
        # Raspberry Pi Pico (RP2040) — normal mode
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0005", TAG+="uaccess"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0005", TAG+="uaccess"

        # Raspberry Pi Pico — bootloader mode (BOOTSEL)
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="0003", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", TAG+="uaccess"
      '';
    })
  ];
}
