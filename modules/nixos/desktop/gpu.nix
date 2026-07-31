{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.gpu.nvidia;
in
{
  options.arctic.gpu.nvidia = {
    enable = lib.mkEnableOption "the NVIDIA proprietary driver stack";

    open = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use the open-source kernel module. Correct for Turing (RTX 20xx) and
        newer — this host is an RTX 3070 Ti (Ampere). Set false for Pascal and
        older, where the open module does not support the GPU at all.
      '';
    };

    branch = lib.mkOption {
      type = lib.types.enum [ "stable" "beta" "production" "latest" ];
      default = "stable";
    };

    vaapi = lib.mkEnableOption "nvidia-vaapi-driver for hardware video decode" // { default = true; };

    powerManagement = lib.mkEnableOption "suspend/resume power management (laptops)";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      # 32-bit userspace is non-negotiable for Steam, Proton and Wine.
      enable32Bit = true;
      extraPackages = lib.mkIf cfg.vaapi [ pkgs.nvidia-vaapi-driver ];
    };

    hardware.nvidia = {
      modesetting.enable = true;
      inherit (cfg) open;
      powerManagement.enable = cfg.powerManagement;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.${cfg.branch};
    };
  };
}
