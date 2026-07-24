{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  HOME MANAGER — arctic
# ─────────────────────────────────────────────────────────────────────────────

{
  home.username      = "arctic";
  home.homeDirectory = "/home/arctic";
  home.stateVersion  = "24.11";

  # ─── SHELL: FISH ─────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;
    shellAliases = {
      ls   = "eza --icons --group-directories-first";
      ll   = "eza -la --icons --group-directories-first";
      cat  = "bat --style=plain";
      grep = "rg";
      cd   = "z";
    };
    interactiveShellInit = ''
      zoxide init fish | source
      set fish_greeting ""
      bind \cl 'clear; commandline -f repaint'
      # Stop commands from opening a pager
      set -x PAGER cat
      fish_add_path $HOME/.npm-global/bin
    '';
  };

  # ─── STARSHIP PROMPT ─────────────────────────────────────────────────────────
  programs.starship = {
    enable                = true;
    enableFishIntegration = true;
    settings = {
      format = "$username$hostname$directory$git_branch$git_status$nix_shell$cmd_duration$line_break$character";
      username = {
        show_always = true;
        format      = "[$user]($style)@";
        style_user  = "bold cyan";
      };
      hostname = {
        ssh_only = false;
        format   = "[$hostname]($style) ";
        style    = "bold green";
      };
      directory = {
        truncation_length = 3;
        style             = "bold blue";
      };
      git_branch.style = "bold purple";
      git_status.style = "bold red";
      nix_shell = {
        format = "[$symbol$state]($style) ";
        symbol = "❄️ ";
      };
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };
    };
  };

  # ─── GIT ─────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
      user.name  = "arctic";
      user.email = "";
      alias = {
        lg   = "log --oneline --graph --decorate --all";
        st   = "status -sb";
        co   = "checkout";
        br   = "branch";
        undo = "reset --soft HEAD~1";
      };
      init.defaultBranch   = "main";
      pull.rebase          = true;
      push.autoSetupRemote = true;
      core.autocrlf        = false;
    };
  };

  # ─── NEOVIM ──────────────────────────────────────────────────────────────────
  programs.neovim = {
    enable        = true;
    defaultEditor = true;
    vimAlias      = true;
    extraConfig   = ''
      set number relativenumber
      set tabstop=4 shiftwidth=4 expandtab
      set clipboard=unnamedplus
      set ignorecase smartcase
      set termguicolors
      set undofile
    '';
  };

  # ─── TMUX ────────────────────────────────────────────────────────────────────
  programs.tmux = {
    enable       = true;
    terminal     = "tmux-256color";
    historyLimit = 10000;
    keyMode      = "vi";
    mouse        = true;
    prefix       = "C-a";
    extraConfig  = ''
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
      set -g status-style bg=black,fg=white
      set -g status-left "#[bold,fg=cyan]#S "
      set -g status-right "#[fg=yellow]%H:%M %d-%b"
    '';
  };

  # ─── SSH CLIENT ──────────────────────────────────────────────────────────────
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        ServerAliveInterval 60
        ServerAliveCountMax 3
        HashKnownHosts yes
        IdentitiesOnly yes
        StrictHostKeyChecking ask
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
        MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
        KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
    '';
  };

  # ─── KITTY TERMINAL ──────────────────────────────────────────────────────────
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 19;
    };

    settings = {
      # ── Transparency ──────────────────────────────────────────────────────────
      background_opacity         = "0.90";
      dynamic_background_opacity = true;

      # ── Tokyo Night — True Black background ───────────────────────────────────
      foreground           = "#c0caf5";
      background           = "#1a1b26";
      selection_foreground = "#c0caf5";
      selection_background = "#33467c";

      # Black
      color0  = "#15161e";
      color8  = "#414868";
      # Red
      color1  = "#f7768e";
      color9  = "#f7768e";
      # Green
      color2  = "#9ece6a";
      color10 = "#9ece6a";
      # Yellow
      color3  = "#e0af68";
      color11 = "#e0af68";
      # Blue
      color4  = "#7aa2f7";
      color12 = "#7aa2f7";
      # Magenta
      color5  = "#bb9af7";
      color13 = "#bb9af7";
      # Cyan
      color6  = "#7dcfff";
      color14 = "#7dcfff";
      # White
      color7  = "#a9b1d6";
      color15 = "#c0caf5";

      # Cursor
      cursor                = "#c0caf5";
      cursor_text_color     = "#000000";
      cursor_shape          = "beam";
      cursor_blink_interval = "0";

      # URL style
      url_color = "#7aa2f7";
      url_style = "curly";

      # ── Window ───────────────────────────────────────────────────────────────
      window_padding_width    = 8;
      hide_window_decorations = "no";
      confirm_os_window_close = 0;

      # ── Tabs ─────────────────────────────────────────────────────────────────
      tab_bar_edge            = "bottom";
      tab_bar_style           = "powerline";
      tab_powerline_style     = "slanted";
      tab_title_template      = "{index}: {title}";
      active_tab_foreground   = "#000000";
      active_tab_background   = "#7aa2f7";
      active_tab_font_style   = "bold";
      inactive_tab_foreground = "#545c7e";
      inactive_tab_background = "#000000";
      inactive_tab_font_style = "normal";

      # ── Performance ──────────────────────────────────────────────────────────
      repaint_delay   = 8;
      input_delay     = 1;
      sync_to_monitor = "yes";

      # ── Font rendering ────────────────────────────────────────────────────────
      font_features         = "JetBrainsMono-Regular +liga +calt";
      disable_ligatures     = "never";
      text_rendering_engine = "harfbuzz";

      # ── Bell ─────────────────────────────────────────────────────────────────
      enable_audio_bell    = false;
      visual_bell_duration = "0";

      # ── Scrollback ───────────────────────────────────────────────────────────
      scrollback_lines = 10000;

      # ── Misc ─────────────────────────────────────────────────────────────────
      shell                 = "/run/current-system/sw/bin/fish";
      editor                = "nvim";
      copy_on_select        = "clipboard";
      strip_trailing_spaces = "smart";
      detect_urls           = true;
    };

    # ── Keybindings ──────────────────────────────────────────────────────────
    keybindings = {
      # Splits
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+\\"    = "launch --location=vsplit --cwd=current";
      "ctrl+shift+-"     = "launch --location=hsplit --cwd=current";

      # Navigate splits
      "ctrl+shift+h" = "neighboring_window left";
      "ctrl+shift+l" = "neighboring_window right";
      "ctrl+shift+k" = "neighboring_window up";
      "ctrl+shift+j" = "neighboring_window down";

      # Tabs
      "ctrl+shift+t"     = "new_tab_with_cwd";
      "ctrl+shift+w"     = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left"  = "previous_tab";

      # Font size
      "ctrl+shift+scroll_up"   = "change_font_size all +1.0";
      "ctrl+shift+scroll_down" = "change_font_size all -1.0";
      "ctrl+shift+0"           = "change_font_size all 0";

      # Transparency on the fly
      "ctrl+shift+a>m" = "set_background_opacity +0.1";
      "ctrl+shift+a>l" = "set_background_opacity -0.1";
      "ctrl+shift+a>1" = "set_background_opacity 1";
      "ctrl+shift+a>d" = "set_background_opacity default";

      # Scrollback
      "ctrl+shift+up"        = "scroll_line_up";
      "ctrl+shift+down"      = "scroll_line_down";
      "ctrl+shift+page_up"   = "scroll_page_up";
      "ctrl+shift+page_down" = "scroll_page_down";

      # Clear
      "ctrl+shift+delete" = "clear_terminal scroll active";
    };
  };

  # ─── USER PACKAGES ───────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    eza
    bat
    ripgrep
    fd
    fzf
    zoxide
    jq
    httpie
    just
    yt-dlp
  ];

  programs.home-manager.enable = true;
}
