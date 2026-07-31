{ config, lib, ... }:

let
  cfg = config.arctic.shell.tmux;
in
{
  options.arctic.shell.tmux = {
    enable = lib.mkEnableOption "tmux" // { default = true; };
  };

  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      terminal = "tmux-256color";
      historyLimit = 10000;
      keyMode = "vi";
      mouse = true;
      prefix = "C-a";

      extraConfig = ''
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"
        bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
        set -g status-style bg=black,fg=white
        set -g status-left "#[bold,fg=cyan]#S "
        set -g status-right "#[fg=yellow]%H:%M %d-%b"
      '';
    };
  };
}
