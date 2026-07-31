{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.office;
in
{
  options.arctic.apps.office = {
    enable = lib.mkEnableOption "office and note-taking applications";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      libreoffice
      obsidian
    ];
  };
}
