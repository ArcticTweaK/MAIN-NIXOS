{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.media;
in
{
  options.arctic.apps.media = {
    enable = lib.mkEnableOption "media applications";

    creation = lib.mkEnableOption "recording and image editing" // { default = true; };
    server = lib.mkEnableOption "self-hosted media server tooling";
    torrent = lib.mkEnableOption "BitTorrent client" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vlc
    ]
    ++ lib.optionals cfg.creation [
      obs-studio
      gimp
    ]
    ++ lib.optionals cfg.server [
      navidrome # Subsonic-compatible music server
      jellyfin-desktop
    ]
    ++ lib.optionals cfg.torrent [
      qbittorrent
    ];
  };
}
