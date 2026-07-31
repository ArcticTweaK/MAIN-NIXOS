{ config, lib, modulesPath, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  arctic — hardware facts
#
#  Derived from nixos-generate-config, MINUS everything filesystem-related.
#  Disk layout lives in ./filesystems.nix (today's ext4 machine) and
#  ./disko.nix (the declarative target), selected by arctic.disk.useDisko.
#
#  Machine: Intel i5-12600K (Alder Lake) / NVIDIA RTX 3070 Ti (Ampere)
#           Samsung 980 PRO 1TB NVMe / Intel I225-V + Intel CNVi WiFi
# ─────────────────────────────────────────────────────────────────────────────

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
