{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.reverseEngineering;
in
{
  options.arctic.apps.reverseEngineering = {
    enable = lib.mkEnableOption "reverse engineering and binary analysis tools";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ghidra
      imhex
    ];
  };
}
