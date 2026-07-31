{ config, lib, ... }:

let
  cfg = config.arctic.core.shell;
in
{
  options.arctic.core.shell = {
    enable = lib.mkEnableOption "system shell and editor defaults" // { default = true; };

    fish = lib.mkEnableOption "fish system-wide" // { default = true; };
    neovim = lib.mkEnableOption "neovim system-wide as $EDITOR" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    # fish must be enabled at the SYSTEM level for it to be a valid login
    # shell, even though home-manager owns its actual configuration.
    programs.fish.enable = cfg.fish;

    programs.neovim = lib.mkIf cfg.neovim {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
    };

    environment.homeBinInPath = true;

    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # Only aliases that make sense for EVERY user including root live here.
    # Interactive conveniences (ls -> eza, cat -> bat) belong in home-manager:
    # putting them in /etc/profile means `sudo -i; grep -r` silently behaves
    # differently from `grep -r`, which is a genuine footgun during an incident.
    environment.shellAliases = {
      manage = "bash ~/nixos-config/nix-manage.sh";
      cls = "clear";
    };
  };
}
