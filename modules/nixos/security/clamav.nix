{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.security.clamav;
in
{
  options.arctic.security.clamav = {
    enable = lib.mkEnableOption ''
      ClamAV signature updates plus a scheduled on-demand scan.

      Chiefly useful for catching Windows malware in downloads before it goes
      near Wine/Proton, and for not passing an infected file on to someone else
    '';

    scanPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "/home/arctic/Downloads" ];
      description = "Directories swept by the scheduled scan.";
    };

    interval = lib.mkOption {
      type = lib.types.str;
      default = "Sun 03:00";
      description = "systemd OnCalendar expression for the scheduled scan.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.clamav = {
      # Daemon OFF. clamd is a resident process holding the entire signature
      # database (~1 GB) in RAM permanently, and nothing on a desktop asks it
      # to scan anything — there is no mail gateway and no file server here.
      #
      # Note you cannot instead use services.clamav.scanner: nixpkgs asserts
      # `scanner.enable -> daemon.enable`, because that scanner shells out to
      # `clamdscan --fdpass` and needs a live socket. Hence the timer below,
      # which runs standalone `clamscan` and loads signatures itself.
      daemon.enable = false;

      updater.enable = true;
      updater.frequency = 12; # freshclam checks per day
    };

    systemd.services.clamav-scheduled-scan = {
      description = "Scheduled ClamAV scan of ${lib.concatStringsSep ", " cfg.scanPaths}";
      after = [ "clamav-freshclam.service" ];

      serviceConfig = {
        Type = "oneshot";

        ExecStart = ''
          ${pkgs.clamav}/bin/clamscan --recursive --infected --stdout \
            ${lib.escapeShellArgs cfg.scanPaths}
        '';

        # clamscan exits 1 when it FINDS something. Without this the unit is
        # marked failed on a successful detection, which is backwards.
        SuccessExitStatus = [ 1 ];

        # Never compete with anything interactive.
        Nice = 19;
        IOSchedulingClass = "idle";

        # It reads untrusted files by definition, so give it as little as
        # possible: no network, read-only view of the system, nothing but the
        # scan paths and the signature database.
        PrivateNetwork = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        MemoryDenyWriteExecute = false; # clamav JITs bytecode signatures
        ReadOnlyPaths = cfg.scanPaths ++ [ "/var/lib/clamav" ];
      };
    };

    systemd.timers.clamav-scheduled-scan = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.interval;
        Persistent = true; # run on next boot if the machine was off
        RandomizedDelaySec = "30m";
      };
    };

    # Ad-hoc scanning, which is the common case: `scan ~/Downloads/thing.exe`
    environment.systemPackages = [ pkgs.clamav ];
    environment.shellAliases.scan = "clamscan --recursive --infected --stdout";
  };
}
