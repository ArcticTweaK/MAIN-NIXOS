{ config, lib, ... }:

let
  cfg = config.arctic.virt.libvirt;
in
{
  options.arctic.virt.libvirt = {
    enable = lib.mkEnableOption ''
      libvirt/QEMU virtual machines.

      Note that the `libvirtd` group is effectively root-equivalent: a member
      can define a VM with arbitrary host device passthrough and disk access
    '';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
  };
}
