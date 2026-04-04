{ pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
#  HOME MANAGER — entropy (0xentropy ghost persona)
#  Offensive security, CTF, ML-sec, anonymity. No gaming. No personal traces.
# ─────────────────────────────────────────────────────────────────────────────

let
  # Python environment with security + ML packages
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    # ML / adversarial
    torch
    torchvision
    numpy
    scipy
    scikit-learn
    pandas
    matplotlib
    jupyterlab
    ipython
    # Offensive / CTF
    pwntools
    requests
    httpx
    beautifulsoup4
    scapy
    paramiko
    cryptography
    pycryptodome
    impacket        # Windows protocol attacks
    # Misc
    click
    rich
    tqdm
  ]);
in
{
  home.username      = "entropy";
  home.homeDirectory = "/home/entropy";
  home.stateVersion  = "24.11";

  # ─── PACKAGES ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # ── Recon ─────────────────────────────────────────────────────────────────
    nmap
    masscan
    subfinder
    dnsx
    #httpx

    # ── Web ───────────────────────────────────────────────────────────────────
    burpsuite
    gobuster
    ffuf
    sqlmap
    nikto

    # ── Exploitation ──────────────────────────────────────────────────────────
    metasploit
    exploitdb
    netcat-openbsd
    socat

    # ── Reversing / Binary ────────────────────────────────────────────────────
    ghidra
    radare2
    gdb
    binwalk
    file
    xxd
    ltrace
    strace

    # ── Crypto ────────────────────────────────────────────────────────────────
    hashcat
    john
    steghide
    openssl

    # ── Networking ────────────────────────────────────────────────────────────
    wireshark-cli
    tcpdump
    proxychains-ng
    iproute2
    traceroute
    mitmproxy

    # ── Anonymity / Privacy ───────────────────────────────────────────────────
    tor
    torsocks

    # ── Encryption / Secrets ──────────────────────────────────────────────────
    gnupg
    age
    pass
    veracrypt

    # ── Metadata ─────────────────────────────────────────────────────────────
    exiftool
    mat2

    # ── Python ────────────────────────────────────────────────────────────────
    pythonEnv
    python3Packages.pip

    # ── Dev / Shell ───────────────────────────────────────────────────────────
    direnv
    fzf
    ripgrep
    bat
    fd
    jq
    git
    gnumake
    gcc
    rustup
    go
    nodejs_22
    tmux
    rlwrap
    patchelf
    upx
  ];

  # ─── SHELL: ZSH ──────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.config/zsh/history";
      extended = true;
      ignoreDups = true;
      share = false;           # Don't share history across sessions
    };

    # Prompt — clearly distinct from arctic's fish/starship prompt
    # [entropy] in bold red, path in cyan, git branch in yellow
    initExtra = ''
      # ── Prompt ───────────────────────────────────────────────────────────────
      autoload -Uz vcs_info
      precmd() { vcs_info }
      zstyle ':vcs_info:git:*' formats ' %F{yellow}(%b)%f'
      setopt PROMPT_SUBST
      PROMPT='%B%F{red}[entropy]%f%b %F{cyan}%~%f''${vcs_info_msg_0_} %F{red}❯%f '

      # ── direnv hook ──────────────────────────────────────────────────────────
      eval "$(direnv hook zsh)"

      # ── fzf ──────────────────────────────────────────────────────────────────
      source ${pkgs.fzf}/share/fzf/completion.zsh
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh

      # ── zoxide ───────────────────────────────────────────────────────────────
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"

      # ── GPG TTY (needed for pinentry in terminal) ─────────────────────────────
      export GPG_TTY=$(tty)

      # ── No history for sensitive commands ────────────────────────────────────
      # Commands prefixed with a space are not saved
      setopt HIST_IGNORE_SPACE

      # ── Tor check on shell start ──────────────────────────────────────────────
      if systemctl --user is-active --quiet tor-proxy.service 2>/dev/null; then
        echo "[entropy] tor: active"
      else
        echo "[entropy] tor: not running — traffic not anonymized"
      fi
    '';

    shellAliases = {
      # ── Navigation ─────────────────────────────────────────────────────────
      ls   = "eza --icons --group-directories-first";
      ll   = "eza -la --icons --group-directories-first";
      cat  = "bat --style=plain";
      grep = "rg";
      cd   = "z";

      # ── Meta strip ─────────────────────────────────────────────────────────
      strip-meta  = "exiftool -all= --";          # Usage: strip-meta file.jpg
      strip-meta2 = "mat2 --inplace --";          # mat2 variant

      # ── Network / Tor ──────────────────────────────────────────────────────
      myip        = "curl -s https://check.torproject.org/api/ip | jq .";
      tor-curl    = "torsocks curl";
      tor-check   = "torsocks curl -s https://check.torproject.org/api/ip | jq .IsTor";
      vpn-status  = "ip route | grep -E '(tun|wg)[0-9]' || echo 'no VPN tunnel detected'";
      dns-check   = "resolvectl status | grep -E '(DNS Server|DNS over TLS)'";

      # ── CTF / Hacking ──────────────────────────────────────────────────────
      serve       = "python3 -m http.server";     # Quick HTTP server
      b64d        = "base64 -d";
      b64e        = "base64";
      hexd        = "xxd";
      rlnc        = "rlwrap nc";                  # nc with readline
      py          = "python3";

      # ── Security shortcuts ─────────────────────────────────────────────────
      ports       = "ss -tulnp";
      listen      = "ss -tlnp";
      conns       = "ss -tp";

      # ── Git ────────────────────────────────────────────────────────────────
      g           = "git";
      ga          = "git add";
      gc          = "git commit -S";              # Always GPG-sign
      gp          = "git push";
      gl          = "git log --oneline --graph --decorate --all";
      gs          = "git status -sb";
    };
  };

  # ─── GIT (0xentropy identity) ────────────────────────────────────────────────
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name       = "0xentropy";
      user.email      = "PLACEHOLDER@proton.me";   # TODO: set ghost proton address
      user.signingKey = "PLACEHOLDER_GPG_FINGERPRINT";  # TODO: set GPG key ID

      commit.gpgsign  = true;
      tag.gpgsign     = true;
      gpg.program     = "${pkgs.gnupg}/bin/gpg2";

      alias = {
        lg   = "log --oneline --graph --decorate --all";
        st   = "status -sb";
        co   = "checkout";
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
      " No swap files — forensics hygiene
      set noswapfile
      set nobackup
    '';
  };

  # ─── TMUX ────────────────────────────────────────────────────────────────────
  programs.tmux = {
    enable       = true;
    terminal     = "tmux-256color";
    historyLimit = 50000;
    keyMode      = "vi";
    mouse        = true;
    prefix       = "C-b";
    extraConfig  = ''
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind r source-file ~/.config/tmux/tmux.conf \; display "Reloaded!"
      # Red status bar — visually distinct from arctic's
      set -g status-style bg=colour1,fg=white
      set -g status-left "#[bold,fg=white]#S "
      set -g status-right "#[fg=white]%H:%M %d-%b"
      set -g status-left-length 20
    '';
  };

  # ─── SSH CLIENT (0xentropy separate keypair) ─────────────────────────────────
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

      # 0xentropy GitHub — uses dedicated key, not the GPG SSH key
      Host github-0xentropy
        HostName github.com
        User git
        IdentityFile ~/.ssh/0xentropy_ed25519
        IdentitiesOnly yes
        # Route through Tor
        ProxyCommand torsocks nc %h %p
    '';
  };

  # ─── GPG AGENT ───────────────────────────────────────────────────────────────
  services.gpg-agent = {
    enable              = true;
    enableZshIntegration = true;
    enableSshSupport    = true;    # Use GPG key as SSH key (optional — comment if using separate ed25519)
    pinentryPackage     = pkgs.pinentry-curses;  # Terminal pinentry — no GUI dep
    defaultCacheTtl     = 3600;    # 1 hour
    maxCacheTtl         = 14400;   # 4 hours max
    extraConfig         = ''
      allow-loopback-pinentry
    '';
  };

  # ─── FIREFOX HARDENED PROFILE ────────────────────────────────────────────────
  programs.firefox = {
    enable = true;
    profiles."entropy" = {
      id        = 0;
      isDefault = true;
      settings  = {
        # ── Network: SOCKS5 → Tor ──────────────────────────────────────────────
        "network.proxy.type"            = 1;       # Manual proxy
        "network.proxy.socks"           = "127.0.0.1";
        "network.proxy.socks_port"      = 9050;    # Tor SOCKS5
        "network.proxy.socks_version"   = 5;
        "network.proxy.socks_remote_dns" = true;   # Resolve DNS through Tor
        "network.proxy.no_proxies_on"   = "";      # Proxy everything

        # ── Security: HTTPS-only ───────────────────────────────────────────────
        "dom.security.https_only_mode"  = true;
        "dom.security.https_only_mode_ever_enabled" = true;

        # ── Fingerprinting resistance ──────────────────────────────────────────
        "privacy.resistFingerprinting"              = true;
        "privacy.resistFingerprinting.block_mozAddonManager" = true;
        "privacy.fingerprintingProtection"          = true;
        "privacy.fingerprintingProtection.pbmode"   = true;

        # ── Telemetry — all off ────────────────────────────────────────────────
        "toolkit.telemetry.unified"                 = false;
        "toolkit.telemetry.enabled"                 = false;
        "toolkit.telemetry.server"                  = "";
        "toolkit.telemetry.archive.enabled"         = false;
        "toolkit.telemetry.newProfilePing.enabled"  = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled"      = false;
        "toolkit.telemetry.bhrPing.enabled"         = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.coverage.opt-out"        = true;
        "toolkit.coverage.opt-out"                  = true;
        "toolkit.coverage.endpoint.base"            = "";
        "datareporting.healthreport.uploadEnabled"  = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "app.shield.optoutstudies.enabled"          = false;
        "browser.discovery.enabled"                 = false;
        "browser.ping-centre.telemetry"             = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;

        # ── Crash reporting ────────────────────────────────────────────────────
        "breakpad.reportURL"                        = "";
        "browser.tabs.crashReporting.sendReport"    = false;

        # ── Pocket + Sponsored content ─────────────────────────────────────────
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "extensions.pocket.enabled"                = false;
        "browser.topsites.useRemoteSetting"         = false;
        "browser.topsites.contile.enabled"          = false;

        # ── Geolocation ────────────────────────────────────────────────────────
        "geo.enabled"                               = false;
        "geo.provider.network.url"                  = "";
        "browser.region.network.url"                = "";
        "browser.region.update.enabled"             = false;

        # ── Safe browsing (phones home to Google) ─────────────────────────────
        "browser.safebrowsing.malware.enabled"      = false;
        "browser.safebrowsing.phishing.enabled"     = false;
        "browser.safebrowsing.downloads.enabled"    = false;
        "browser.safebrowsing.downloads.remote.enabled" = false;

        # ── DNS (all goes through Tor proxy, disable DoH override) ─────────────
        "network.trr.mode"                          = 5;   # Disable DoH — Tor handles DNS
        "network.dns.disablePrefetch"               = true;

        # ── Tracking / cookies / storage ──────────────────────────────────────
        "network.cookie.cookieBehavior"             = 5;   # Block all 3rd party
        "privacy.purge_trackers.enabled"            = true;
        "browser.contentblocking.category"          = "strict";
        "privacy.firstparty.isolate"                = true;  # First-party isolation
        "privacy.socialtracking.block_cookies.enabled" = true;

        # ── Prefetch / speculation ─────────────────────────────────────────────
        "network.prefetch-next"                     = false;
        "network.dns.disableIPv6"                   = true;  # Avoid IPv6 leaks through Tor
        "network.http.speculative-parallel-limit"   = 0;
        "browser.send_pings"                        = false;

        # ── WebRTC (CRITICAL — leaks real IP even through proxy) ───────────────
        "media.peerconnection.enabled"              = false;
        "media.peerconnection.ice.no_host"          = true;
        "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;

        # ── Canvas / audio fingerprinting ──────────────────────────────────────
        # resistFingerprinting handles these, but belt-and-suspenders:
        "canvas.poisondata"                         = true;

        # ── Misc hardening ─────────────────────────────────────────────────────
        "browser.sessionstore.privacy_level"        = 2;
        "security.ssl.require_safe_negotiation"     = true;
        "security.tls.enable_0rtt_data"             = false;   # Disable TLS 1.3 0-RTT
        "security.OCSP.require"                     = true;
        "security.family_safety.mode"               = 0;
        "dom.event.clipboardevents.enabled"         = false;
        "dom.vibrator.enabled"                      = false;
        "dom.battery.enabled"                       = false;
        "dom.gamepad.enabled"                       = false;
        "beacon.enabled"                            = false;   # Disable navigator.sendBeacon
        "browser.uitour.enabled"                    = false;
        "browser.fixup.alternate.enabled"           = false;
        "browser.urlbar.speculativeConnect.enabled" = false;

        # ── New tab / UI ───────────────────────────────────────────────────────
        "browser.startup.homepage"                  = "about:blank";
        "browser.newtabpage.enabled"                = false;
        "browser.newtabpage.activity-stream.enabled" = false;
        "browser.startup.page"                      = 0;

        # ── Updates (auto-update silently, security-critical for opsec) ────────
        "app.update.auto"                           = true;
        "app.update.silent"                         = true;
      };
    };
  };

  # ─── PROTONMAIL BRIDGE (systemd user service) ────────────────────────────────
  # Bridge must be started and configured interactively on first run:
  #   protonmail-bridge --cli  → login, then it runs as daemon
  # After initial setup, the service below keeps it running.
  systemd.user.services.protonmail-bridge = {
    Unit = {
      Description = "ProtonMail Bridge (entropy inbox)";
      After       = [ "network.target" ];
    };
    Service = {
      Type      = "simple";
      ExecStart = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive --log-level info";
      Restart   = "on-failure";
      RestartSec = "5s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # ─── NEOMUTT CONFIG (reads from protonmail-bridge IMAP) ──────────────────────
  # Bridge exposes:
  #   IMAP: 127.0.0.1:1143  SMTP: 127.0.0.1:1025  (check bridge for exact ports)
  programs.neomutt = {
    enable = true;
    extraConfig = ''
      set imap_user  = "PLACEHOLDER@proton.me"  # TODO: ghost proton address
      set imap_pass  = `pass entropy/proton-bridge`  # from pass store
      set folder     = "imap://127.0.0.1:1143"
      set spoolfile  = "+INBOX"
      set smtp_url   = "smtp://PLACEHOLDER@proton.me@127.0.0.1:1025"
      set smtp_pass  = `pass entropy/proton-bridge`
      set ssl_starttls = yes
      set ssl_force_tls = yes
      set certificate_file = ~/.local/share/protonmail/bridge/cert.pem

      # GPG
      set crypt_autosign  = yes
      set crypt_autoencrypt = no
      set crypt_use_gpgme = yes
      set pgp_default_key = "PLACEHOLDER_GPG_FINGERPRINT"
    '';
  };

  # ─── ISYNC / MBSYNC (offline IMAP mirror) ────────────────────────────────────
  accounts.email.accounts."0xentropy" = {
    address         = "PLACEHOLDER@proton.me";  # TODO
    userName        = "PLACEHOLDER@proton.me";
    realName        = "0xentropy";
    primary         = true;
    imap = {
      host = "127.0.0.1";
      port = 1143;
      tls.enable = true;
      tls.useStartTls = true;
    };
    smtp = {
      host = "127.0.0.1";
      port = 1025;
      tls.enable = true;
      tls.useStartTls = true;
    };
    mbsync = {
      enable       = true;
      create       = "maildir";
      expunge      = "none";
      patterns     = [ "INBOX" "Sent" "Drafts" ];
    };
    neomutt.enable = true;
    gpg = {
      key        = "PLACEHOLDER_GPG_FINGERPRINT";
      signByDefault = true;
    };
    passwordCommand = "pass entropy/proton-bridge";
  };

  programs.mbsync.enable = true;

  # ─── DIRENV ──────────────────────────────────────────────────────────────────
  programs.direnv = {
    enable            = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  # ─── KITTY (entropy instance — dark red accent) ──────────────────────────────
  # Separate kitty config for entropy so the terminal is visually distinct
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 18;
    };
    settings = {
      background_opacity = "0.95";
      foreground   = "#cdd6f4";
      background   = "#0d0d0d";       # Near-black — distinct from arctic's #1a1b26

      # Red accent scheme instead of arctic's blue
      color0  = "#181825";  color8  = "#585b70";
      color1  = "#f38ba8";  color9  = "#f38ba8";
      color2  = "#a6e3a1";  color10 = "#a6e3a1";
      color3  = "#f9e2af";  color11 = "#f9e2af";
      color4  = "#89b4fa";  color12 = "#89b4fa";
      color5  = "#cba6f7";  color13 = "#cba6f7";
      color6  = "#89dceb";  color14 = "#89dceb";
      color7  = "#bac2de";  color15 = "#cdd6f4";

      cursor            = "#f38ba8";  # Red cursor — can't mistake this terminal
      cursor_text_color = "#0d0d0d";
      cursor_shape      = "beam";

      shell                 = "${pkgs.zsh}/bin/zsh";
      editor                = "nvim";
      scrollback_lines      = 50000;
      copy_on_select        = "clipboard";
      tab_bar_style         = "powerline";
      active_tab_background = "#f38ba8";   # Red active tab
      active_tab_foreground = "#000000";
    };
  };

  programs.home-manager.enable = true;
}