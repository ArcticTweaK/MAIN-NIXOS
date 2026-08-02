{ config, lib, osConfig ? null, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  KDE Plasma 6 — the whole look and feel of the desktop, declared.
#
#  Plasma keeps its state in ~/.config/*rc INI files that System Settings
#  rewrites live. plasma-manager (wired in by lib/mkHost.nix) writes those same
#  keys from Nix at home-manager activation time.
#
#  ── Namespace ──────────────────────────────────────────────────────────────
#  `arctic.plasma`, NOT `arctic.desktop`. The NixOS side already owns
#  `arctic.desktop.*` (SDDM, plasma6, Wayland env vars). These are two separate
#  module fixpoints, so both COULD be called `arctic.desktop` without an eval
#  error — but then `config.arctic.desktop` would mean two different things
#  depending on which file you had open. Disjoint leaf names is the rule.
#
#      modules/nixos/desktop/plasma.nix   installs Plasma, runs SDDM  (system)
#      modules/home/desktop/plasma.nix    what Plasma looks like      (user)
#
#  ── The contract: null means "not managed" ─────────────────────────────────
#  Every option here defaults to null, and a null is never written. So enabling
#  this module changes NOTHING on its own — it only takes ownership of the keys
#  the host actually names in hosts/<name>/default.nix. Anything you set by
#  hand in System Settings and never declare here keeps working.
#
#  That stops being true if you set `overrideConfig`. See its description.
# ─────────────────────────────────────────────────────────────────────────────

let
  cfg = config.arctic.plasma;

  # Reading system state from a home-manager module goes through `osConfig`.
  # There is no supported path in the other direction. The `? null` default
  # keeps this module usable in a standalone home-manager setup, where
  # home-manager does not pass osConfig at all.
  systemHasPlasma =
    osConfig != null
    && osConfig.arctic.desktop.enable
    && osConfig.arctic.desktop.plasma;

  # plasma-manager's font submodule REQUIRES `family`, so a font is only
  # emitted once both a family and a size exist to build it from.
  mkFont = family: size:
    if family == null || size == null then null else { inherit family; pointSize = size; };

  mouseType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        example = "Logitech USB Receiver";
        description = ''
          The device name libinput reports — which for a wireless mouse is
          usually the RECEIVER, not the model on the box.

          Read the three identity fields off the live system with:
              grep -B1 -A5 -i mouse /proc/bus/input/devices
          or, definitively, from the group name Plasma itself already uses:
              grep '^\[Libinput' ~/.config/kcminputrc
          which is `[Libinput][<vendor-dec>][<product-dec>][<name>]`.
        '';
      };

      vendorId = lib.mkOption {
        type = lib.types.str;
        example = "046d";
        description = ''
          USB vendor ID, in HEX. Note that `/proc/bus/input/devices` prints hex
          and `kcminputrc` prints the same number in DECIMAL (046d = 1133).
        '';
      };

      productId = lib.mkOption {
        type = lib.types.str;
        example = "c547";
        description = "USB product ID, in HEX (c547 = 50503 decimal).";
      };

      sensitivity = lib.mkOption {
        type = lib.types.nullOr (lib.types.numbers.between (-1) 1);
        default = null;
        example = 0.2;
        description = ''
          How fast the pointer moves — the "Pointer speed" slider in
          System Settings → Mouse, written as `PointerAcceleration`.

          -1 is slowest, 0 is the middle of the slider, 1 is fastest. It is a
          scale factor, not an acceleration curve; the curve is
          `accelerationProfile`.
        '';
      };

      accelerationProfile = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "none" "default" ]);
        default = null;
        example = "none";
        description = ''
          The acceleration CURVE.

          - `none`    — flat. Pointer distance is a fixed multiple of mouse
                        distance, no matter how fast you move. This is what
                        "raw input" / "no mouse acceleration" means, and it is
                        what you want if you aim in games.
          - `default` — adaptive. Moving faster travels disproportionately
                        further. Better for large desktops, worse for muscle
                        memory.
        '';
      };

      naturalScroll = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Invert scroll direction (content follows fingers).";
      };

      scrollSpeed = lib.mkOption {
        type = lib.types.nullOr (lib.types.numbers.between 0.1 20);
        default = null;
        example = 1.0;
        description = "Scroll wheel multiplier. 1.0 is unmodified.";
      };

      leftHanded = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Swap the left and right mouse buttons.";
      };

      middleButtonEmulation = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Emulate a middle click by pressing left and right together.";
      };
    };
  };
in
{
  options.arctic.plasma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = systemHasPlasma;
      defaultText = lib.literalExpression "osConfig.arctic.desktop.plasma";
      description = ''
        Manage Plasma settings declaratively.

        Follows the system: if this host runs Plasma, home-manager configures
        it. On its own this writes nothing — see the module header.
      '';
    };

    overrideConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Make this config the SOLE authority over Plasma's settings.

        false (default) — additive. Keys named here are written; every other
        key keeps whatever System Settings last wrote. Safe, and it means you
        can still tune things in the GUI.

        true — DESTRUCTIVE, and deliberately so. On every generation
        plasma-manager DELETES the KDE config files listed in `resetFiles`
        (kdeglobals, kwinrc, kcminputrc, dolphinrc, katerc, the panel layout,
        …) and rebuilds them from this file alone. Anything you changed in the
        GUI and did not declare here is gone at next login.

        That is the actually-reproducible mode, and the right end state. Get
        there by capturing what you have first — `rc2nix` (see the
        EMPYREAN.md discovery section) prints your live config as Nix — rather
        than by flipping this and finding out what you forgot.
      '';
    };

    # ── Theme ───────────────────────────────────────────────────────────────
    theme = {
      lookAndFeel = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "org.kde.breezedark.desktop";
        description = ''
          The Global Theme — the umbrella preset that sets colour scheme,
          Plasma style, icons, cursors and splash in one go.

          Because it sets all of those, it is applied FIRST and the individual
          options below override it. List installed values with
          `plasma-apply-lookandfeel --list`.
        '';
      };

      colorScheme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "BreezeDark";
        description = ''
          The colour palette. `plasma-apply-colorscheme --list-schemes`.
        '';
      };

      plasmaStyle = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "default";
        description = ''
          The Plasma style — how the panel, widgets and popups are drawn.
          Distinct from `widgetStyle`, which is about application windows.
          `plasma-apply-desktoptheme --list-themes`.
        '';
      };

      widgetStyle = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Breeze";
        description = ''
          The Qt widget style — how buttons, checkboxes and scrollbars are
          drawn INSIDE application windows. "Union" is the Plasma 6.5+ default,
          "Breeze" the classic one, "Oxygen" and "Fusion" also ship.
        '';
      };

      iconTheme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Papirus";
        description = ''
          Icon theme. The theme's PACKAGE must be installed for this to resolve
          — Papirus comes from `papirus-icon-theme` in
          modules/nixos/apps/utilities.nix. Naming a theme whose package is
          absent silently falls back to Breeze.
        '';
      };

      soundTheme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "freedesktop";
        description = "System sound theme (`ocean` is Plasma's own).";
      };

      splashScreen = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "None";
        description = ''
          The splash shown between login and desktop. "None" disables it — on
          an NVMe box it is most of the perceived boot time and displays
          nothing you need.
        '';
      };

      windowDecoration = {
        library = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "org.kde.breeze";
          description = ''
            Titlebar/border engine. `org.kde.breeze` for the built-in one,
            `org.kde.kwin.aurorae` for downloaded Aurorae themes.

            plasma-manager ASSERTS that library and theme are set together —
            half a decoration is an eval error, not a broken desktop.

            Setting this alongside `lookAndFeel` produces a build WARNING, and
            the warning is right: the Global Theme is applied first and carries
            its own decoration, so the two race. Pick one — either let the
            Global Theme supply the decoration, or drop `lookAndFeel` and
            assemble the parts yourself.
          '';
        };

        theme = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "Breeze";
          description = "Decoration theme name, matching `library` above.";
        };
      };

      titlebarButtons = {
        left = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          example = [ "on-all-desktops" "keep-above-windows" ];
          description = "Titlebar buttons on the left, in order.";
        };

        right = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          example = [ "minimize" "maximize" "close" ];
          description = "Titlebar buttons on the right, in order.";
        };
      };

      wallpaper = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.path (lib.types.listOf lib.types.path));
        default = null;
        example = lib.literalExpression "../../../assets/wallpapers/basement.jpg";
        description = ''
          Desktop wallpaper. A single path applies to every screen; a LIST
          assigns per screen, indexed by Plasma's screen number — element 0 to
          screen 0, element 1 to screen 1, and so on.

          Per-screen is applied through Plasma's own scripting API
          (`desktops()`, indexed by `desktop.screen`), not by editing
          containments in plasma-org.kde.plasma.desktop-appletsrc. That matters:
          containment numbers are imperative state that a fresh install
          renumbers, whereas screen numbers are assigned by Plasma at runtime,
          so this survives the reinstall.

          Screen number is NOT the connector name. Plasma numbers by display
          priority — the primary is 0. To see which is which:

              kscreen-doctor -o     # "priority 1" is screen 0

          These are Nix PATHS, which under flakes means they must live inside
          the repo — an absolute path like /home/arctic/Documents/wallpapers/x.jpg
          is rejected by pure evaluation, and would not survive the reinstall
          this repo exists to make possible anyway. The images live in
          `assets/wallpapers/`; they get copied into the store and the wallpaper
          becomes as reproducible as everything else.

          A list SHORTER than the screen count leaves the extra screens alone
          (the generated script skips an undefined entry), so a two-element list
          is safe if you later unplug a monitor.
        '';
      };
    };

    # ── Cursor ──────────────────────────────────────────────────────────────
    cursor = {
      theme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "breeze_cursors";
        description = ''
          Cursor theme. `plasma-apply-cursortheme --list-themes`, or look at
          the directory names under /run/current-system/sw/share/icons that
          contain a `cursors/` subdirectory — those are the installed ones.
        '';
      };

      size = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        example = 24;
        description = ''
          Cursor size in pixels. 24 is standard, 32/48 for high-DPI. Each
          theme only ships certain sizes; an unavailable one gets scaled and
          looks soft.
        '';
      };
    };

    # ── Fonts ───────────────────────────────────────────────────────────────
    #  Six separate font slots, driven from three options. Setting them
    #  individually is possible via `extraConfig`, but in practice nobody wants
    #  their menus in a different family from their toolbars.
    fonts = {
      family = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "Noto Sans";
        description = ''
          Interface font — used for general text, toolbars, menus and window
          titles. Must be a font fontconfig can resolve, so it should come from
          `fonts.packages` in modules/nixos/desktop/fonts.nix.
        '';
      };

      monospace = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "JetBrainsMono Nerd Font";
        description = "Fixed-width font, for Konsole and code views.";
      };

      size = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        example = 10;
        description = ''
          Point size for the interface font. The "small" slot is derived one
          point below this.
        '';
      };
    };

    # ── Input ───────────────────────────────────────────────────────────────
    input = {
      mice = lib.mkOption {
        type = lib.types.listOf mouseType;
        default = [ ];
        description = ''
          Per-device mouse settings, including pointer speed.

          Keyed on vendor+product+name, so settings follow the DEVICE rather
          than the port. A mouse not listed here keeps whatever System Settings
          last set for it.
        '';
      };

      keyboard = {
        numlockOnStartup = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "on" "off" "unchanged" ]);
          default = null;
          example = "on";
          description = ''
            NumLock state when the session starts.

            Note this is the SESSION's NumLock, and is separate from the SDDM
            greeter's (`autoNumlock`, set in modules/nixos/desktop/plasma.nix).
            Set both or you type your password with NumLock off and the desktop
            with it on.
          '';
        };

        repeatDelay = lib.mkOption {
          type = lib.types.nullOr (lib.types.ints.between 100 5000);
          default = null;
          example = 250;
          description = "Milliseconds a key is held before it starts repeating.";
        };

        repeatRate = lib.mkOption {
          type = lib.types.nullOr (lib.types.numbers.between 0.2 100.0);
          default = null;
          example = 40.0;
          description = "Repeats per second once repeating has started.";
        };

        options = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          example = [ "caps:escape" ];
          description = ''
            XKB options — the remapping layer. `caps:escape` makes Caps Lock an
            Escape key, `compose:ralt` makes right Alt a compose key. Full list
            in `man 7 xkeyboard-config`.
          '';
        };
      };
    };

    # ── Behaviour ───────────────────────────────────────────────────────────
    behavior = {
      clickItemTo = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "open" "select" ]);
        default = null;
        example = "open";
        description = ''
          Whether a single click on a file opens it or selects it. `select` is
          the behaviour every other OS has; `open` is the KDE default.
        '';
      };

      doubleClickInterval = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        example = 400;
        description = "Maximum milliseconds between two clicks to count as a double click.";
      };

      animationSpeed = lib.mkOption {
        type = lib.types.nullOr (lib.types.numbers.between 0 10);
        default = null;
        example = 0.5;
        description = ''
          Global animation duration multiplier.

          1.0 is normal, 0.5 is twice as fast, 0 disables animations entirely.
          This is the single highest-impact setting for how responsive the
          desktop FEELS, because it is latency you are choosing to add.
        '';
      };

      tooltipDelay = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = null;
        example = 700;
        description = "Milliseconds of hover before a tooltip appears.";
      };

      middleClickPaste = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = ''
          Whether middle click pastes the X11-style primary selection. Off is
          worth considering: it is the classic way to paste a password into a
          chat window by accident.
        '';
      };

      confirmLogout = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Show the confirmation dialog when logging out or shutting down.";
      };

      restoreSession = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [
          "onLastLogout"
          "whenSessionWasManuallySaved"
          "startWithEmptySession"
        ]);
        default = null;
        example = "startWithEmptySession";
        description = ''
          What reopens at login. `startWithEmptySession` is the one that makes
          login times predictable and stops half-dead apps from a crashed
          session coming back with it.
        '';
      };
    };

    # ── KWin (the compositor / window manager) ──────────────────────────────
    kwin = {
      virtualDesktops = {
        number = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 4;
          description = "How many virtual desktops.";
        };

        rows = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 1;
          description = "How many rows to arrange them in, in the pager and switcher.";
        };

        names = lib.mkOption {
          type = lib.types.nullOr (lib.types.listOf lib.types.str);
          default = null;
          example = [ "Main" "Games" "Dev" "Comms" ];
          description = ''
            Names for each desktop. The list length must match `number`.
          '';
        };
      };

      borderlessMaximized = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Drop the titlebar and border on maximized windows, reclaiming the row of pixels.";
      };

      edgeBarrier = lib.mkOption {
        type = lib.types.nullOr (lib.types.ints.between 0 1000);
        default = null;
        example = 0;
        description = ''
          Extra pixels of resistance before the pointer crosses between
          monitors. 0 disables it — which is what you want on a multi-monitor
          setup if you have ever tried to flick to another screen and had the
          pointer stick.
        '';
      };

      cornerBarrier = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Stop the pointer crossing screens diagonally at a shared corner.";
      };

      tilingPadding = lib.mkOption {
        type = lib.types.nullOr (lib.types.ints.between 0 36);
        default = null;
        example = 4;
        description = "Gap in pixels between windows placed by KWin's tiling.";
      };

      effects = {
        blur = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = ''
            Blur what is behind translucent windows. This is what makes a
            transparent terminal readable — kitty runs at 0.90 opacity in
            modules/home/terminal/kitty.nix.
          '';
        };

        blurStrength = lib.mkOption {
          type = lib.types.nullOr (lib.types.ints.between 1 15);
          default = null;
          example = 5;
          description = "Blur intensity, 1–15.";
        };

        dimInactive = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "Darken windows that do not have focus.";
        };

        slideBack = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "Slide windows out of the way when another is raised.";
        };

        snapHelper = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "Show a crosshair marking screen centre while dragging a window.";
        };

        shakeCursor = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = ''
            Briefly enlarge the cursor when shaken. Genuinely useful on a large
            or multi-monitor desktop for finding a lost pointer.
          '';
        };
      };

      nightLight = {
        enable = lib.mkOption {
          type = lib.types.nullOr lib.types.bool;
          default = null;
          description = "Shift the display warmer at night.";
        };

        mode = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "automatic" "constant" "location" "times" ]);
          default = null;
          example = "times";
          description = ''
            - `automatic` — sunset to sunrise, from geoclue. Needs a location
                            service to actually be running and reachable.
            - `location`  — same, but from latitude/longitude you supply.
            - `times`     — fixed clock times. No network, no geolocation,
                            always behaves the same. The predictable choice.
            - `constant`  — always on at the night temperature.
          '';
        };

        dayTemperature = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 6500;
          description = "Daytime colour temperature in Kelvin. 6500 is neutral.";
        };

        nightTemperature = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 4500;
          description = "Night colour temperature in Kelvin. Lower is warmer/oranger.";
        };

        morningTime = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "06:30";
          description = "When day starts, `HH:MM`. Only used when mode = \"times\".";
        };

        eveningTime = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "20:00";
          description = "When night starts, `HH:MM`. Only used when mode = \"times\".";
        };

        transitionTime = lib.mkOption {
          type = lib.types.nullOr lib.types.ints.positive;
          default = null;
          example = 30;
          description = "Minutes taken to fade between day and night.";
        };
      };
    };

    # ── Screen locker ───────────────────────────────────────────────────────
    screenLocker = {
      autoLock = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Lock the screen after `timeout` minutes idle.";
      };

      timeout = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.unsigned;
        default = null;
        example = 15;
        description = "Idle minutes before locking. Only meaningful with autoLock on.";
      };

      lockOnResume = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Require the password after waking from sleep.";
      };

      passwordRequired = lib.mkOption {
        type = lib.types.nullOr lib.types.bool;
        default = null;
        description = "Require a password to unlock at all.";
      };

      graceTime = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.unsigned;
        default = null;
        example = 5;
        description = ''
          Seconds after locking during which no password is asked. Covers the
          "locked it, immediately needed it again" case.
        '';
      };
    };

    # ── Power ───────────────────────────────────────────────────────────────
    #  AC only. Battery and lowBattery profiles are reachable through
    #  `extraSettings` if a laptop ever joins this config.
    power = {
      turnOffDisplayIdle = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.unsigned;
        default = null;
        example = 900;
        description = "Seconds idle before the display sleeps. 0 never sleeps.";
      };

      autoSuspendAction = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "nothing" "sleep" "hibernate" "shutDown" ]);
        default = null;
        example = "nothing";
        description = ''
          What idling does. `nothing` is the correct answer for a desktop that
          runs long game downloads or container builds unattended.
        '';
      };

      powerButtonAction = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [
          "nothing"
          "sleep"
          "hibernate"
          "shutDown"
          "lockScreen"
          "showLogoutScreen"
          "turnOffScreen"
        ]);
        default = null;
        example = "showLogoutScreen";
        description = "What pressing the physical power button does.";
      };
    };

    # ── Shortcuts ───────────────────────────────────────────────────────────
    shortcuts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf (
        lib.types.either lib.types.str (lib.types.listOf lib.types.str)
      ));
      default = { };
      example = lib.literalExpression ''
        {
          kwin."Switch Window Left" = "Meta+H";
          plasmashell."activate task manager entry 1" = [ ];   # unbind
        }
      '';
      description = ''
        Global shortcuts, written to kglobalshortcutsrc. Outer key is the
        component (kwin, plasmashell, ksmserver, kmix, …), inner key is the
        action name, value is one binding or a list of them.

        An empty list UNBINDS. The action names are not guessable — bind it in
        System Settings first, then read the name back out of
        ~/.config/kglobalshortcutsrc.
      '';
    };

    hotkeys = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Label shown in System Settings.";
          };
          key = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "Meta+Return";
            description = "The key combination.";
          };
          command = lib.mkOption {
            type = lib.types.str;
            example = "kitty";
            description = "Command to run.";
          };
        };
      });
      default = { };
      example = lib.literalExpression ''{ terminal = { key = "Meta+Return"; command = "kitty"; }; }'';
      description = ''
        Custom command hotkeys — "press this, run that".

        Distinct from `shortcuts`, which rebinds actions Plasma already has.
        Upstream has known trouble binding a few combinations, `Ctrl+Alt+T` and
        `Print` among them; use another combination if one silently fails.
      '';
    };

    # ── Panels ──────────────────────────────────────────────────────────────
    panels = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      default = [ ];
      example = lib.literalExpression ''
        [{
          location = "bottom";
          height = 44;
          widgets = [ "org.kde.plasma.kickoff" "org.kde.plasma.icontasks" "org.kde.plasma.systemtray" ];
        }]
      '';
      description = ''
        Panel layout, passed straight through to plasma-manager.

        DESTRUCTIVE when non-empty, independently of `overrideConfig`: to apply
        a layout at all, plasma-manager deletes
        plasma-org.kde.plasma.desktop-appletsrc and rebuilds it, which takes
        your existing panels, their widgets and every widget's settings with
        it. Empty (the default) leaves panels completely alone.

        Declare panels only when you are ready to declare ALL of them.
      '';
    };

    # ── Escape hatch ────────────────────────────────────────────────────────
    extraSettings = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf (lib.types.attrsOf lib.types.anything));
      default = { };
      example = lib.literalExpression ''
        {
          kwinrc.Windows.DelayFocusInterval = 0;
          dolphinrc.General.ShowFullPath = true;
        }
      '';
      description = ''
        Raw `<file>.<group>.<key> = value` writes into ~/.config, for the long
        tail this module does not wrap.

        Find the file/group/key by changing the setting in System Settings and
        diffing ~/.config — or capture the lot with `rc2nix`. Anything you set
        here that turns out to be something you tune more than once is a
        candidate for becoming a real option above.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.plasma = {
      enable = true;
      inherit (cfg) overrideConfig shortcuts panels;

      workspace = {
        inherit (cfg.theme) lookAndFeel colorScheme iconTheme soundTheme widgetStyle;

        theme = cfg.theme.plasmaStyle;
        wallpaper = cfg.theme.wallpaper;

        cursor = lib.mkIf (cfg.cursor.theme != null || cfg.cursor.size != null) {
          inherit (cfg.cursor) theme size;
        };

        # engine is left null: plasma-manager derives "none" from the "None"
        # theme and KSplashQML from anything else, and the assertion only
        # objects to an engine WITHOUT a theme.
        splashScreen.theme = cfg.theme.splashScreen;

        windowDecorations = {
          inherit (cfg.theme.windowDecoration) library theme;
        };

        inherit (cfg.behavior) clickItemTo tooltipDelay;
        enableMiddleClickPaste = cfg.behavior.middleClickPaste;
      };

      fonts = {
        general = mkFont cfg.fonts.family cfg.fonts.size;
        toolbar = mkFont cfg.fonts.family cfg.fonts.size;
        menu = mkFont cfg.fonts.family cfg.fonts.size;
        windowTitle = mkFont cfg.fonts.family cfg.fonts.size;
        fixedWidth = mkFont cfg.fonts.monospace cfg.fonts.size;
        small = mkFont cfg.fonts.family (
          if cfg.fonts.size == null then null else cfg.fonts.size - 1
        );
      };

      input = {
        mice = map (m: {
          inherit (m) name vendorId productId naturalScroll scrollSpeed leftHanded middleButtonEmulation;
          acceleration = m.sensitivity;
          inherit (m) accelerationProfile;
        }) cfg.input.mice;

        keyboard = {
          inherit (cfg.input.keyboard) numlockOnStartup repeatDelay repeatRate options;
        };
      };

      kwin = {
        titlebarButtons = {
          inherit (cfg.theme.titlebarButtons) left right;
        };

        virtualDesktops = {
          inherit (cfg.kwin.virtualDesktops) number rows names;
        };

        borderlessMaximizedWindows = cfg.kwin.borderlessMaximized;
        inherit (cfg.kwin) edgeBarrier cornerBarrier;
        tiling.padding = cfg.kwin.tilingPadding;

        effects = {
          blur = {
            enable = cfg.kwin.effects.blur;
            strength = cfg.kwin.effects.blurStrength;
          };
          dimInactive.enable = cfg.kwin.effects.dimInactive;
          slideBack.enable = cfg.kwin.effects.slideBack;
          snapHelper.enable = cfg.kwin.effects.snapHelper;
        };

        nightLight = {
          inherit (cfg.kwin.nightLight) enable mode transitionTime;
          temperature = {
            day = cfg.kwin.nightLight.dayTemperature;
            night = cfg.kwin.nightLight.nightTemperature;
          };
          time = {
            morning = cfg.kwin.nightLight.morningTime;
            evening = cfg.kwin.nightLight.eveningTime;
          };
        };
      };

      kscreenlocker = {
        inherit (cfg.screenLocker) autoLock timeout lockOnResume passwordRequired;
        passwordRequiredDelay = cfg.screenLocker.graceTime;
      };

      powerdevil.AC = {
        turnOffDisplay.idleTimeout = cfg.power.turnOffDisplayIdle;
        autoSuspend.action = cfg.power.autoSuspendAction;
        inherit (cfg.power) powerButtonAction;
      };

      session = {
        general.askForConfirmationOnLogout = cfg.behavior.confirmLogout;
        sessionRestore.restoreOpenApplicationsOnLogin = cfg.behavior.restoreSession;
      };

      # `name` and `key` are plain strings upstream with their own defaults, so
      # an unset one is omitted rather than passed through as null.
      hotkeys.commands = lib.mapAttrs
        (_: h:
          { inherit (h) command; }
          // lib.optionalAttrs (h.name != null) { inherit (h) name; }
          // lib.optionalAttrs (h.key != null) { inherit (h) key; }
        )
        cfg.hotkeys;

      # shakeCursor lives in kwinrc's plugin list rather than the effects
      # submodule, and AnimationDurationFactor is a kdeglobals key with no
      # wrapper at all — both go through the same raw path as extraSettings.
      configFile = lib.mkMerge [
        (lib.mkIf (cfg.kwin.effects.shakeCursor != null) {
          kwinrc.Plugins.shakecursorEnabled = cfg.kwin.effects.shakeCursor;
        })
        (lib.mkIf (cfg.behavior.animationSpeed != null) {
          kdeglobals.KDE.AnimationDurationFactor = cfg.behavior.animationSpeed;
        })
        (lib.mkIf (cfg.behavior.doubleClickInterval != null) {
          kdeglobals.KDE.DoubleClickInterval = cfg.behavior.doubleClickInterval;
        })
        cfg.extraSettings
      ];
    };
  };
}
