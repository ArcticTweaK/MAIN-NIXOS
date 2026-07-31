{ config, lib, ... }:

let
  cfg = config.arctic.terminal.kitty;
in
{
  options.arctic.terminal.kitty = {
    enable = lib.mkEnableOption "the kitty terminal" // { default = true; };

    fontFamily = lib.mkOption {
      type = lib.types.str;
      default = "JetBrainsMono Nerd Font";
    };

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 19;
    };

    opacity = lib.mkOption {
      type = lib.types.str;
      default = "0.90";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.kitty = {
      enable = true;

      font = {
        name = cfg.fontFamily;
        size = cfg.fontSize;
      };

      settings = {
        # ── Transparency ────────────────────────────────────────────────────
        background_opacity = cfg.opacity;
        dynamic_background_opacity = true;

        # ── Tokyo Night ─────────────────────────────────────────────────────
        foreground = "#c0caf5";
        background = "#1a1b26";
        selection_foreground = "#c0caf5";
        selection_background = "#33467c";

        color0 = "#15161e"; # black
        color8 = "#414868";
        color1 = "#f7768e"; # red
        color9 = "#f7768e";
        color2 = "#9ece6a"; # green
        color10 = "#9ece6a";
        color3 = "#e0af68"; # yellow
        color11 = "#e0af68";
        color4 = "#7aa2f7"; # blue
        color12 = "#7aa2f7";
        color5 = "#bb9af7"; # magenta
        color13 = "#bb9af7";
        color6 = "#7dcfff"; # cyan
        color14 = "#7dcfff";
        color7 = "#a9b1d6"; # white
        color15 = "#c0caf5";

        cursor = "#c0caf5";
        cursor_text_color = "#000000";
        cursor_shape = "beam";
        cursor_blink_interval = "0";

        url_color = "#7aa2f7";
        url_style = "curly";

        # ── Window ──────────────────────────────────────────────────────────
        window_padding_width = 8;
        hide_window_decorations = "no";
        confirm_os_window_close = 0;

        # ── Tabs ────────────────────────────────────────────────────────────
        tab_bar_edge = "bottom";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        tab_title_template = "{index}: {title}";
        active_tab_foreground = "#000000";
        active_tab_background = "#7aa2f7";
        active_tab_font_style = "bold";
        inactive_tab_foreground = "#545c7e";
        inactive_tab_background = "#000000";
        inactive_tab_font_style = "normal";

        # ── Performance ─────────────────────────────────────────────────────
        repaint_delay = 8;
        input_delay = 1;
        sync_to_monitor = "yes";

        # ── Font rendering ──────────────────────────────────────────────────
        font_features = "JetBrainsMono-Regular +liga +calt";
        disable_ligatures = "never";
        text_rendering_engine = "harfbuzz";

        # ── Bell ────────────────────────────────────────────────────────────
        enable_audio_bell = false;
        visual_bell_duration = "0";

        scrollback_lines = 10000;

        # ── Misc ────────────────────────────────────────────────────────────
        shell = "/run/current-system/sw/bin/fish";
        editor = "nvim";
        copy_on_select = "clipboard";
        strip_trailing_spaces = "smart";
        detect_urls = true;
      };

      keybindings = {
        # Splits
        "ctrl+shift+enter" = "new_window_with_cwd";
        "ctrl+shift+\\" = "launch --location=vsplit --cwd=current";
        "ctrl+shift+-" = "launch --location=hsplit --cwd=current";

        # Navigate splits
        "ctrl+shift+h" = "neighboring_window left";
        "ctrl+shift+l" = "neighboring_window right";
        "ctrl+shift+k" = "neighboring_window up";
        "ctrl+shift+j" = "neighboring_window down";

        # Tabs
        "ctrl+shift+t" = "new_tab_with_cwd";
        "ctrl+shift+w" = "close_tab";
        "ctrl+shift+right" = "next_tab";
        "ctrl+shift+left" = "previous_tab";

        # Font size
        "ctrl+shift+scroll_up" = "change_font_size all +1.0";
        "ctrl+shift+scroll_down" = "change_font_size all -1.0";
        "ctrl+shift+0" = "change_font_size all 0";

        # Transparency on the fly
        "ctrl+shift+a>m" = "set_background_opacity +0.1";
        "ctrl+shift+a>l" = "set_background_opacity -0.1";
        "ctrl+shift+a>1" = "set_background_opacity 1";
        "ctrl+shift+a>d" = "set_background_opacity default";

        # Scrollback
        "ctrl+shift+up" = "scroll_line_up";
        "ctrl+shift+down" = "scroll_line_down";
        "ctrl+shift+page_up" = "scroll_page_up";
        "ctrl+shift+page_down" = "scroll_page_down";

        # Clear
        "ctrl+shift+delete" = "clear_terminal scroll active";
      };
    };
  };
}
