{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.gaming.launchers;
in
{
  options.arctic.gaming.launchers = {
    enable = lib.mkEnableOption "third-party game launchers and Wine tooling";

    minecraft = lib.mkEnableOption "PrismLauncher and the JDKs it needs" // { default = true; };

    wine = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Wine + winetricks from nixpkgs.

        Pick ONE lane for Wine and Bottles — nixpkgs or Flatpak. Running both
        means two wineprefix managers pointed at different data directories,
        and every "my prefix disappeared" bug traces back to that.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lutris # non-Steam / retail games
      heroic # Epic, GOG, Amazon
      cartridges # unified launcher frontend
      mangohud # FPS / frametime / temps overlay

      # Vulkan runtime + diagnostics (vulkaninfo, vkcube)
      vulkan-loader
      vulkan-tools
      dxvk
    ]
    ++ lib.optionals cfg.minecraft [
      prismlauncher
      jdk21 # MC 1.20.5+
      jdk17 # MC 1.17-1.20.4
    ]
    ++ lib.optionals cfg.wine [
      wine
      wine-wayland
      winetricks
      bottles
    ];
  };
}
