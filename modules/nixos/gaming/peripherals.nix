{ config, lib, ... }:

let
  cfg = config.arctic.gaming.peripherals;
in
{
  options.arctic.gaming.peripherals = {
    wooting = lib.mkEnableOption "Wooting analog keyboards";
    pico = lib.mkEnableOption "Raspberry Pi Pico / RP2040 (udev access for flashing)";

    logitech = lib.mkEnableOption ''
      Logitech wireless devices — Unifying, Lightspeed and Nano receivers.

      Gives battery level, DPI and per-device settings for peripherals that
      talk over a receiver rather than as a plain HID mouse. This is the
      Logitech USB Receiver already named in the plasma input config
    '';

    logitechGui = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install Solaar, the GUI/CLI manager, alongside the udev rules.

        Off leaves you the rules and `ltunify` only, which is enough for the
        device to work but not to inspect or configure it. Only meaningful
        when `logitech` is on.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.wooting {
      # This installs pkgs.wooting-udev-rules via services.udev.packages,
      # which covers every Wooting VID/PID including the legacy 03eb ones.
      # The config previously carried eight hand-written rules duplicating
      # exactly that; they are gone.
      hardware.wooting.enable = true;
    })

    (lib.mkIf cfg.logitech {
      # Same reasoning as wooting above: the module, not the bare package.
      # `solaar` on its own needs root to reach the receiver — the working
      # setup is the udev rules, which live in a separate derivation
      # (logitech-udev-rules) that this option wires into services.udev.
      # `enableGraphical` is what actually adds pkgs.solaar; without it you
      # get ltunify and the rules only.
      hardware.logitech.wireless = {
        enable = true;
        enableGraphical = cfg.logitechGui;
      };
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
