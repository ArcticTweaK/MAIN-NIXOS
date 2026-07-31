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
#  Deliberately plain: no attribute is a "clever" default.
#    by-id device   survives a wipe and cannot be reordered like /dev/nvme0n1
#    1G ESP         room for several signed generations plus Secure Boot keys
#    subvolumes     @root can be wiped for impermanence without touching @home
#    zstd:3         near-free on a 12600K, and less write wear on the SSD
#    swapfile       inside LUKS, so paged-out secrets are never on disk in
#                   the clear. 34G to leave room for hibernation later.
# ─────────────────────────────────────────────────────────────────────────────

{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5P2NL0T829360K";

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
