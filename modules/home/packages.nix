{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.home.packages;
in
{
  options.arctic.home.packages = {
    enable = lib.mkEnableOption "per-user packages" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.home-manager.enable = true;

    # User-scoped only. The CLI workhorses (eza, bat, ripgrep, fd, fzf,
    # zoxide, tmux) are declared once at SYSTEM level instead, so they also
    # exist in a root shell or a recovery console — declaring them in both
    # places just builds two profiles containing the same store paths.
    home.packages = with pkgs; [
      jq
      just
      yt-dlp
    ];
  };
}
