{ config, lib, ... }:

let
  cfg = config.arctic.security.clamav;
in
{
  options.arctic.security.clamav = {
    enable = lib.mkEnableOption "ClamAV antivirus";
  };

  # FIXME(commit 6): the resident daemon holds ~1 GB of signatures in RAM and
  # nothing ever asks it to scan anything. Replaced in commit 6 with
  # freshclam updates plus a weekly on-demand `clamscan` timer.
  config = lib.mkIf cfg.enable {
    services.clamav = {
      daemon.enable = true;
      updater.enable = true;
      updater.frequency = 1;
    };
  };
}
