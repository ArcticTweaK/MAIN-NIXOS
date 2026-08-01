{ config, lib, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  arctic — CURRENT (pre-wipe) disk layout: hand-partitioned LUKS + ext4.
#
#  This describes the machine as it exists today, and is merged ONLY while
#  `arctic.disk.useDisko = false`. Once that flips, disko generates all of it
#  from ./disko.nix instead and this file goes quiet — after the reinstall it
#  can be deleted outright, along with its line in ./default.nix's imports.
#
#  Note the gate is on the CONFIG, not the import. A NixOS module's `imports`
#  list is evaluated before `config` exists, so it cannot branch on an option;
#  wrapping the body in mkIf is the way to make a file conditional. Getting
#  this wrong produces a conflicting-definition error for fileSystems."/" that
#  only appears once useDisko is true — i.e. at install time, from the ISO.
#
#  Layout:  nvme0n1p1  1G      vfat  ESP  -> /boot
#           nvme0n1p2  896.2G  LUKS  ext4 -> /
#           nvme0n1p3  34.3G   LUKS  swap
# ─────────────────────────────────────────────────────────────────────────────

lib.mkIf (!config.arctic.disk.useDisko) {
  fileSystems."/" = {
    device = "/dev/mapper/luks-d61205ad-265f-44e3-ba4b-9b3de51370ad";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B4EA-0A8E";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # Root container.
  boot.initrd.luks.devices."luks-d61205ad-265f-44e3-ba4b-9b3de51370ad".device =
    "/dev/disk/by-uuid/d61205ad-265f-44e3-ba4b-9b3de51370ad";

  # Swap container. Encrypted swap matters: without it, anything paged out of
  # RAM — including decrypted secrets — lands on disk in the clear.
  boot.initrd.luks.devices."luks-224f9649-1173-4a89-befc-0807579fa011".device =
    "/dev/disk/by-uuid/224f9649-1173-4a89-befc-0807579fa011";

  swapDevices = [
    { device = "/dev/mapper/luks-224f9649-1173-4a89-befc-0807579fa011"; }
  ];
}
