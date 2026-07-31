_:

# ─────────────────────────────────────────────────────────────────────────────
#  arctic — CURRENT (pre-wipe) disk layout: hand-partitioned LUKS + ext4.
#
#  This file describes the machine as it exists today. It is merged only while
#  `arctic.disk.useDisko = false`. After the reinstall described in README.md,
#  flip that boolean and disko generates all of this from ./disko.nix instead —
#  at which point this file can be deleted.
#
#  Layout:  nvme0n1p1  1G      vfat  ESP  -> /boot
#           nvme0n1p2  896.2G  LUKS  ext4 -> /
#           nvme0n1p3  34.3G   LUKS  swap
# ─────────────────────────────────────────────────────────────────────────────

{
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
