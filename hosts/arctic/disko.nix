# ─────────────────────────────────────────────────────────────────────────────
#  arctic — TARGET disk layout: LUKS + btrfs subvolumes.
#
#  INERT TODAY. This file is not applied to the running ext4 machine; it is
#  gated by `arctic.disk.useDisko`, which is false, so disko.enableConfig is
#  false and no fileSystems/swapDevices/luks entries are generated from it.
#  Verified: the built system is unchanged with this present.
#
#  It is still live in two useful senses:
#    - `nix flake check` type-checks the layout
#    - `disko-install --flake .#arctic` builds the whole disk from it
#
#  Consumed at reinstall time. See README.md. After the reinstall, flip
#  arctic.disk.useDisko to true and delete ./filesystems.nix.
#
#  The device is a PLACEHOLDER on purpose. This repo is public, and a disk
#  by-id path contains the drive's serial number — a unique hardware
#  identifier tied to a purchase and warranty record. Nothing exploitable,
#  but nothing worth publishing either.
#
#  Pass the real device at install time instead, which disko-install accepts
#  and which OVERRIDES this value:
#
#      ls -l /dev/disk/by-id/ | grep -v part      # find it
#      disko-install ... --disk main /dev/disk/by-id/nvme-Samsung_SSD_...
#
#  That is strictly better than hardcoding: the one destructive operation in
#  this whole config now requires you to name the target explicitly, rather
#  than trusting a string committed months earlier.
#
#  Deliberately plain: no attribute is a "clever" default.
#    by-id at install  survives a wipe, and cannot be reordered the way
#                      /dev/nvme0n1 can when a second drive is added
#    1G ESP            room for several signed generations plus Secure Boot keys
#    subvolumes     @root can be wiped for impermanence without touching @home
#    zstd:3         near-free on a 12600K, and less write wear on the SSD
#    swapfile       inside LUKS, so paged-out secrets are never on disk in
#                   the clear. 34G to leave room for hibernation later.
# ─────────────────────────────────────────────────────────────────────────────

{
  disko.devices.disk.main = {
    type = "disk";
    # PLACEHOLDER — override at install time with `--disk main <device>`.
    # Deliberately not a real path: if you ever run disko without the flag,
    # it should fail loudly rather than format whatever this happens to name.
    device = "/dev/disk/by-id/SET-ME-AT-INSTALL-TIME";

    content = {
      type = "gpt";

      partitions = {
        ESP = {
          priority = 1;
          name = "ESP";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            # The ESP holds unencrypted kernels and initrds. 0077 keeps them
            # unreadable by anyone but root once the system is up.
            mountOptions = [ "umask=0077" "fmask=0077" "dmask=0077" ];
          };
        };

        luks = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";

            settings = {
              allowDiscards = true; # SSD; accepts the usual metadata leak
              crypttabExtraOpts = [ "x-initrd.attach" ];
            };

            content = {
              type = "btrfs";
              extraArgs = [ "-f" "-L" "nixos" ];

              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "compress=zstd:3" "noatime" ];
                };
                "@swap" = {
                  mountpoint = "/.swapvol";
                  # No compression on a swapfile — btrfs will not allow it,
                  # and it would defeat the point anyway.
                  mountOptions = [ "noatime" ];
                  swap.swapfile.size = "34G";
                };
              };
            };
          };
        };
      };
    };
  };
}
