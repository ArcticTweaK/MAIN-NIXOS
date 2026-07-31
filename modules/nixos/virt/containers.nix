{ config, lib, ... }:

let
  cfg = config.arctic.virt.podman;
in
{
  options.arctic.virt.podman = {
    enable = lib.mkEnableOption ''
      rootless Podman.

      Chosen over Docker specifically to remove a root-equivalence. Membership
      in the `docker` group is root by design — the daemon runs as root and
      will happily bind-mount / into a container for any group member, so a
      compromise of the login user is a compromise of the machine. Rootless
      Podman has no daemon and no privileged group: a container escape lands
      as your unprivileged user
    '';

    dockerCompat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Provide `docker` as an alias for podman, plus a compatible socket.

        Covers docker run/build/compose, Dockerfiles, devcontainers and
        oci-containers. The one thing it cannot do is serve something that
        genuinely requires a rootful daemon (a few kind/k8s-in-docker setups).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;

      inherit (cfg) dockerCompat;
      dockerSocket.enable = cfg.dockerCompat;

      # Containers can resolve each other by name on user-defined networks.
      defaultNetwork.settings.dns_enabled = true;

      # Prune dangling images weekly; container storage grows without bound
      # otherwise, and this box builds a lot.
      autoPrune = {
        enable = true;
        dates = "weekly";
        flags = [ "--all" ];
      };
    };

    virtualisation.oci-containers.backend = "podman";

    # netavark's firewall driver and the podman0 DNS port are configured
    # automatically from networking.nftables.enable — nothing to do here.
  };
}
