{ config, lib, ... }:

let
  cfg = config.arctic.gaming;
  nvidia = config.arctic.gpu.nvidia.enable;
in
{
  options.arctic.gaming = {
    gamescope.enable = lib.mkEnableOption "gamescope, Valve's micro-compositor";
    gamemode.enable = lib.mkEnableOption "feral gamemode";

    nofileLimit = lib.mkOption {
      type = lib.types.int;
      default = 1048576;
      description = ''
        Hard RLIMIT_NOFILE. Several Proton titles and Steam itself exhaust the
        default 1024 and fail with confusing "too many open files" errors.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.gamescope.enable {
      programs.gamescope = {
        enable = true;
        # Lets gamescope raise its own scheduling priority, which is most of
        # where its frame-pacing advantage comes from.
        capSysNice = true;
      };
    })

    (lib.mkIf cfg.gamemode.enable {
      programs.gamemode = {
        enable = true;
        settings = {
          general = {
            renice = 10;
            ioprio = 0;
          };

          gpu = lib.mkIf nvidia {
            apply_gpu_optimisations = "accept-responsibility";
            gpu_device = 0;
            nv_powermizer_mode = 1; # prefer maximum performance
            nv_powermizermode_game = 1;
          };

          cpu = {
            park_cores = "no";
            pin_cores = "yes";
          };
        };
      };
    })

    (lib.mkIf cfg.enable {
      security.pam.loginLimits = [
        {
          domain = "*";
          type = "hard";
          item = "nofile";
          value = toString cfg.nofileLimit;
        }
      ];
    })
  ];
}
