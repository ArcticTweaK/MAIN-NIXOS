{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.virt;
in
{
  options.arctic.virt = {
    # FIXME(commit 4): replaced by rootless podman with dockerCompat.
    # Membership in the `docker` group is root-equivalent by design: the
    # daemon runs as root and will happily bind-mount / into a container.
    docker.enable = lib.mkEnableOption "the Docker daemon (root-equivalent — prefer podman)";
    docker.rootless = lib.mkEnableOption "the rootless Docker daemon" // { default = true; };
  };

  config = lib.mkIf cfg.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = false;
      rootless = lib.mkIf cfg.docker.rootless {
        enable = true;
        setSocketVariable = true;
      };
    };

    environment.systemPackages = [ pkgs.docker ];
  };
}
