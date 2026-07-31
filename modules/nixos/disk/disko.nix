{ config, lib, ... }:

let
  cfg = config.arctic.disk;
in
{
  options.arctic.disk.useDisko = lib.mkEnableOption ''
    generating fileSystems / swapDevices / boot.initrd.luks from the host's
    disko.nix.

    THE reinstall flip, and the only line that has to change:

      false  today's hand-partitioned ext4 machine. disko.devices is still
             declared — so `nix flake check` and `disko-install` both work —
             but disko.enableConfig is false and it generates nothing.

      true   post-reinstall. Set this in the commit you install FROM, and do
             not `nixos-rebuild switch` afterwards on the old machine: the
             running system would point at partitions that do not exist yet.

    The mechanism is disko's own `enableConfig`, which wraps its generated
    fileSystems/boot/swapDevices in mkIf. Verified: with this false and the
    LUKS+btrfs layout declared alongside the legacy ext4 fileSystems, the
    built system is byte-identical to not having disko at all
  '';

  config = {
    disko.enableConfig = cfg.useDisko;
  };
}
