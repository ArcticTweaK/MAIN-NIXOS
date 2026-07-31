{ config, lib, ... }:

let
  cfg = config.arctic.shell.fish;
in
{
  options.arctic.shell.fish = {
    enable = lib.mkEnableOption "fish shell configuration" // { default = true; };

    modernCliAliases = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Alias ls/cat/grep to eza/bat/ripgrep.

        Deliberately scoped to the interactive user shell rather than
        /etc/profile: putting them at system level means a root shell silently
        behaves differently from a user shell, which is exactly the wrong time
        to discover that `grep` isn't grep.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;

      shellAliases = lib.mkMerge [
        (lib.mkIf cfg.modernCliAliases {
          ls = "eza --icons --group-directories-first";
          ll = "eza -la --icons --group-directories-first";
          la = "eza -a --icons --group-directories-first";
          lt = "eza --tree --level=2 --icons";
          cat = "bat --style=plain";
          grep = "rg";
          cd = "z";
        })
        {
          # Personal scripts, kept out of /etc so root's PATH stays clean.
          sys-check = "$HOME/scripts/sys-check";
          net-scan = "$HOME/scripts/net-scan";
          net-quick = "$HOME/scripts/net-scan quick";
          net-full = "$HOME/scripts/net-scan full";
          net-net = "$HOME/scripts/net-scan net";
          net-ls = "$HOME/scripts/net-scan ls";
        }
      ];

      interactiveShellInit = ''
        zoxide init fish | source
        set fish_greeting ""
        bind \cl 'clear; commandline -f repaint'
        # Stop commands from opening a pager
        set -x PAGER cat
        fish_add_path $HOME/.npm-global/bin
      '';
    };

    # Was environment.variables.PATH at system level, which also put
    # user-writable directories ahead of /run/wrappers/bin in ROOT's PATH.
    home.sessionPath = [
      "$HOME/scripts"
      "$HOME/.cargo/bin"
    ];
  };
}
