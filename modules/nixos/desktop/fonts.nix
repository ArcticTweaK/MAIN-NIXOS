{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.desktop.fonts;
in
{
  options.arctic.desktop.fonts = {
    enable = lib.mkEnableOption "a system font set" // { default = true; };

    monospace = lib.mkOption {
      type = lib.types.str;
      default = "JetBrainsMono Nerd Font";
    };
  };

  config = lib.mkIf (config.arctic.desktop.enable && cfg.enable) {
    fonts = {
      enableDefaultPackages = true;

      packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        liberation_ttf # metric-compatible with Arial/Times, for Office docs
      ];

      fontconfig.defaultFonts = {
        monospace = [ cfg.monospace ];
        sansSerif = [ "Noto Sans" ];
        serif = [ "Noto Serif" ];
      };
    };
  };
}
