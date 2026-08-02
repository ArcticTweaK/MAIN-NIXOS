# EMPYREAN

**The total specification of the `arctic` NixOS configuration.**

This file exists so that a reader who has never seen this repository — a human
or an AI agent — can read this document plus the source and hold a complete,
correct model of what this machine is, why every decision is what it is, and
where the next change belongs.

It is written to be read **in full** by a machine. Nothing here is decorative.

| File | Role | Answers |
|---|---|---|
| `EMPYREAN.md` | **specification + manual** | What is this? How is it built? What does every option do? Why is each decision what it is? |
| `README.md` | **runbook** | How do I install / recover / verify this machine? |
| `INSTALL-CARD.txt` | **crib sheet** | Printable, offline, for the reinstall itself |

Last full audit of this document against the source: **2026-08-02**, at commit
`cd2f775`.

---

## Table of contents

| § | Section | Read it when |
|---|---|---|
| [00](#00--operating-protocol-for-an-ai-reading-this-repository) | Operating protocol for an AI | **Always. First.** |
| [01](#01--fact-sheet) | Fact sheet | You need the shape of the machine in 60 seconds |
| [02](#02--the-whole-configuration-in-one-page) | The whole configuration in one page | You have a small budget |
| [03](#03--laws-and-invariants) | Laws and invariants | Before proposing any change |
| [04](#04--verification-cookbook) | Verification cookbook | Before asserting any fact |
| [05](#05--repository-map) | Repository map | You need to find a file |
| [06](#06--the-flake) | The flake | Inputs, pins, outputs, dev shell |
| [07](#07--libmkhostnix--the-assembler) | `lib/mkHost.nix` — the assembler | You are adding a host, or asking "where does X get wired in" |
| [08](#08--the-evaluation-pipeline) | The evaluation pipeline | An error appeared and you need to know which phase produced it |
| [09](#09--anatomy-of-a-module) | Anatomy of a module | You are writing or editing a module |
| [10](#10--the-two-fixpoints) | The two fixpoints | You are unsure whether something is system or home |
| [11](#11--master-option-index) | **Master option index** | You need any option's file, type, default and live value |
| [12](#12--system-option-reference) | System option reference | You need the detail behind a system option |
| [13](#13--home-manager-option-reference) | home-manager option reference | You need the detail behind a user option |
| [14](#14--cross-module-coupling-map) | **Cross-module coupling map** | Before changing anything — this is what breaks silently |
| [15](#15--the-manifest-decoded) | The manifest decoded | You want the current state of this specific machine |
| [16](#16--package-inventory) | Package inventory | "Why is this in the closure?" |
| [17](#17--runtime-surface-units-ports-paths) | **Runtime surface: units, ports, paths** | You are reasoning about what actually runs |
| [18](#18--plasma-and-theming) | Plasma and theming | Anything about the desktop's appearance |
| [19](#19--disk-disko-impermanence-reinstall) | Disk, disko, impermanence, reinstall | Anything about storage or rebuilding the machine |
| [20](#20--security-posture-in-full) | Security posture in full | Anything about hardening |
| [21](#21--overlays-and-local-packages) | Overlays and local packages | You are packaging something |
| [22](#22--what-this-config-does-not-reproduce) | **What this config does NOT reproduce** | Before a wipe, and when judging completeness |
| [23](#23--recipes--where-do-i-put-x) | Recipes — where do I put X? | The most common question |
| [24](#24--build-test-roll-back) | Build, test, roll back | You are about to apply something |
| [25](#25--the-decisions-ledger) | **The decisions ledger** | Before suggesting an "obvious improvement" |
| [26](#26--traps-and-failure-modes) | Traps and failure modes | Something is behaving strangely |
| [27](#27--upstream-schema-notes) | **Upstream schema notes** | Your training data may be older than these renames |
| [28](#28--known-drift) | Known drift | You are about to trust a source comment |
| [29](#29--glossary) | Glossary | A term in this file is unfamiliar |
| [30](#30--further-reading) | Further reading | You need the upstream docs |
| [A](#appendix-a--complete-kernel-tunable-values) | Appendix A — complete kernel tunable values | You need exact sysctl/param values |
| [B](#appendix-b--file-inventory) | Appendix B — file inventory | You want every `.nix` file and its one-line role |

---

## 00 — Operating protocol for an AI reading this repository

Read this section before doing anything else. It is the part that keeps you
from being confidently wrong.

### 00.1 What this repository is

A **single-host, flake-based NixOS configuration** with a custom typed option
namespace (`arctic.*`) layered over the NixOS and home-manager module systems.

- It is **not an application**. There is no runtime, no server, no test suite,
  no CI. The build artifact is an operating system.
- The "tests" are `nix flake check` (does it evaluate and build) and a set of
  hand-run verification commands (§04, §20.10).
- Almost every change is a one-line edit to a single file
  (`hosts/arctic/default.nix`).

### 00.2 Authority ranking — what to believe when sources disagree

When two sources conflict, believe them in this order:

1. **A live `nix eval` against the flake.** This is ground truth; it is what
   the system actually builds.
2. **The `.nix` source.** It is what the build enforces.
3. **Comments in the `.nix` source.** These are unusually high quality in this
   repo and explain *why*, but they can drift (§28).
4. **This document.**
5. **`README.md` / `INSTALL-CARD.txt`.** These are procedure documents and go
   stale first.
6. **Your prior knowledge of NixOS.** Least reliable of all here — several
   options in this config use schemas that were renamed recently (§27), and
   several "well-known good practices" are deliberately rejected here for
   reasons documented in §25.

### 00.3 The protocol for answering a question about this repo

1. **Locate the module.** Use §11 (master option index) or §05 (repository
   map). Do not grep blindly; the namespace is regular enough to jump straight
   to the file.
2. **Read the option's `description`.** They are long and specific, and they
   are the version the build enforces.
3. **Check the live value** if the answer depends on it (§04). The module
   default and the value on `arctic` frequently differ.
4. **Check §14** for couplings before claiming a change is isolated. Several
   options silently change the meaning of others.
5. **Check §25** before proposing an improvement. Most obvious improvements
   are already there with a reason attached.
6. **Say which of the above you did.** "Per `modules/nixos/security/kernel.nix`
   line 118" is a useful answer; "NixOS usually…" is not.

### 00.4 The protocol for making a change

1. Decide whether it is a **capability** (goes in `modules/`) or a **fact about
   this machine** (goes in `hosts/arctic/default.nix`). §03, Law 1.
2. If you are writing a raw NixOS option inside `hosts/arctic/default.nix`,
   stop — that option wants to become an `arctic.*` option in a module.
3. New file? **List it in that directory's `default.nix`** — nothing globs —
   **and `git add` it** — flakes cannot see untracked files. Skipping either
   produces a silent no-op or a confusing "attribute missing".
4. Add a `description` to every new option. Explain *why you would change it*,
   not what it is.
5. Prefer `nixos-rebuild test` over `switch` for anything touching the GPU,
   boot chain, disk, or display manager. §24.
6. Never delete a comment because the code looks obvious. The comments are the
   most valuable content in this repository; they exist to stop a future reader
   re-litigating a settled decision.

### 00.5 Things you must not do without being asked explicitly

| Never, unprompted | Why |
|---|---|
| Bump `system.stateVersion` | It is a compatibility marker for stateful defaults, not a version number. Bumping it silently changes defaults for existing state |
| Add a user to `nix.settings.trusted-users` | A trusted user is root-equivalent (§12.2) |
| Set `arctic.plasma.overrideConfig = true` | Deletes every Plasma setting not declared here (§18.9) |
| Add entries to `arctic.plasma.panels` | Destructive on its own — it deletes the existing panel layout (§18.9) |
| Set `security.allowUserNamespaces = false` or `user.max_user_namespaces = 0` | Breaks every Proton title, Roblox/Sober, and nix's own build sandbox. There is an assertion (§08) |
| Enable Docker | The nftables backend blacklists `ip_tables`. There is an assertion (§08) |
| Put a real `/dev/disk/by-id/...` path in `hosts/arctic/disko.nix` | It contains the drive serial, and this repo is public (§19.1) |
| Commit anything resembling a private key | The nix store is world-readable and this repository is public |
| Set `users.mutableUsers = false` | Turns a failed secret decryption into a permanent lockout (§12.4) |
| Run a destructive `disko` command | It formats disks. It is only ever run from an installer ISO |

### 00.6 What this document is not

It is not a substitute for reading the module you are about to edit. The
per-option `description` strings in the `.nix` files are longer and more
specific than the tables here, and they are the version the build enforces.

**This document is the map. The modules are the territory.**

---

## 01 — Fact sheet

```yaml
project:        arctic — NixOS configuration
repository:     ~/nixos-config  (public: github.com/ArcticTweaK/MAIN-NIXOS)
kind:           single-host flake-based NixOS configuration
option-namespace: arctic.*
hosts:          [arctic]
users:          [arctic, root]
platform:       x86_64-linux
channel:        nixos-unstable
stateVersion:   "24.11"        # system AND home. NEVER bump.
kernel:         pkgs.linuxPackages_6_12   (pinned, not _latest — NVIDIA lag)

desktop:        KDE Plasma 6 on Wayland, SDDM greeter, X11 fallback session
theme:          Sweet Ambar Blue (assembled part-by-part, NO Global Theme)
shell:          fish  (system-enabled, home-manager-configured) + starship
terminal:       kitty, Tokyo Night, JetBrainsMono Nerd Font, 0.90 opacity
gpu:            NVIDIA proprietary, open kernel module, stable branch, VA-API
audio:          PipeWire, 32-sample quantum @ 48 kHz, rtkit

firewall:       nftables, default DROP, exactly one port open (53317 LocalSend)
dns:            systemd-resolved, Quad9, strict DoT + strict DNSSEC, NO fallback
tor:            client daemon, SOCKS5 on 127.0.0.1:9050 only
containers:     rootless Podman + Docker compatibility. NO Docker, NO docker group
vms:            libvirt/QEMU + virt-manager
secrets:        sops-nix + age, secrets/arctic.yaml (committed, encrypted)
disk:           disko-declared LUKS2 + btrfs subvolumes + 34G in-LUKS swapfile
boot:           systemd-boot today; lanzaboote/Secure Boot staged and ready
sshd:           none. Nothing listens inbound.

machine:
  board:        MSI MPG Z690 EDGE WIFI DDR4
  cpu:          Intel i5-12600K (Alder Lake)
  gpu:          NVIDIA RTX 3070 Ti (Ampere → open kernel module is correct)
  ram:          ~31.2 GiB  (drives boot.tmp.tmpfsSize = "50%")
  disk:         Samsung 980 PRO 1 TB NVMe
  net:          Intel I225-V ethernet (always used)
                Intel CNVi WiFi + Bluetooth (drivers BLACKLISTED)
  displays:
    screen 0:   DP-3, 2560x1440@240, landscape        → basement.jpg
    screen 1:   DP-4, 2560x1440@165, rotated 270°     → blackhole-abyss.jpg
  mouse:        Logitech wireless via Unifying receiver 046d:c547
  keyboard:     Wooting (analog)
  headset:      SteelSeries Arctis Pro Wireless (USB audio, NOT Bluetooth)
  other:        Raspberry Pi Pico (RP2040) over USB/serial

entrypoint:     sudo nixos-rebuild switch --flake ~/nixos-config#arctic
alias:          manage    →  bash ~/nixos-config/nix-manage.sh
check:          nix flake check          # builds system.build.toplevel
manifest:       hosts/arctic/default.nix # the ONLY file you normally edit
```

---

## 02 — The whole configuration in one page

If you read nothing else, read this.

**The generating sentence.** Everything this machine is, is a value in a Nix
expression that this repository contains. Every convention below is downstream
of that one idea. When unsure whether something belongs in the repo, ask
whether its absence would make the machine unreproducible after a disk wipe.

**The shape.** `flake.nix` calls `lib/mkHost.nix`, which assembles one
`nixosSystem` out of: a pinned nixpkgs + three overlays, five third-party NixOS
modules (sops-nix, nix-flatpak, disko, lanzaboote, impermanence), this repo's
own module tree (`modules/nixos`), the host manifest
(`hosts/arctic/default.nix`), and home-manager with `modules/home` and
plasma-manager wired in as shared modules.

**The discipline.** Every feature is a typed `arctic.*` option with a default
and a long description. Every module's `config` block is wrapped in
`lib.mkIf cfg.enable`, so importing the entire tree adds nothing. The host
manifest turns on the subset this machine wants and states the facts that are
true only of this machine. `modules/` never knows which machine it is on.

**The current machine.** Plasma 6 desktop with an NVIDIA GPU and a full gaming
stack; a hardened kernel, encrypted DNS, an nftables default-drop firewall, an
audit trail, sops-managed account passwords, rootless containers and VMs; a
declaratively partitioned LUKS+btrfs disk; and a broad application set spanning
browsers, media, office, dev, reverse-engineering and security tooling.

**What is staged but off.** Secure Boot (`lanzaboote`) needs a one-time trip
into firmware. Impermanence (ephemeral root) is written and waiting for
confidence in the persist list. AppArmor is off permanently and deliberately —
it would confine nothing on NixOS without hand-written policies.

**The three highest-leverage facts.**

1. **The manifest is one file.** `hosts/arctic/default.nix`. 95% of intended
   changes are one line in it.
2. **Nothing globs and flakes ignore untracked files.** A new module that is
   not listed in its directory's `default.nix` *and* `git add`ed is silently
   inert.
3. **Two halves are needed for a theme.** The package (system,
   `desktop/themes.nix`) and the selection (user, `arctic.plasma.theme.*`).
   Naming a theme whose package is missing does not error — Plasma silently
   falls back to Breeze. This is the single most confusing failure mode here.

---

## 03 — Laws and invariants

### 03.1 The three laws

**Law 1 — Modules declare *capability*. The host declares *facts*.**

`modules/` says "this machine COULD have Plasma / Tor / Secure Boot," and
exactly how each would be built. `hosts/arctic/default.nix` says "this machine
DOES." No file under `modules/` knows it is running on this desktop. That is
precisely what lets a second machine reuse all of it unchanged.

**Law 2 — Nothing is on unless something turns it on.**

Every module gates its `config` behind `lib.mkIf cfg.enable`. Importing all of
`modules/nixos` adds zero packages and zero services. **Importing is not
enabling.** A set of universally-correct modules default their `enable` to
`true` — `core.*`, `desktop.audio`, `desktop.fonts`, `desktop.themes`,
`desktop.wayland`, `network.manager`, `network.dns`, `network.firewall`,
`security.kernel.*`, `security.sudo`, `security.gpg`, and most home modules.
These are marked **bold true** in the tables in §11–§13.

**Law 3 — One file is the manifest.**

To change what this machine *does*, edit `hosts/arctic/default.nix` and nothing
else. Edit `modules/` only to teach the config a capability it does not have
yet. Catching yourself writing a raw NixOS option in the manifest is the signal
to go make it an `arctic.*` option in a module instead.

### 03.2 Ground rules

1. **Nothing globs.** Every `default.nix` lists its siblings by hand.
   `lib.filesystem.listFilesRecursive` is deliberately not used — it breaks the
   moment a non-module `.nix` lands in a directory, and turns an accidental
   file into a silent system change.
2. **Flakes only see git-tracked files.** `git add` before building. An
   untracked new module produces "attribute missing" with no hint of the cause.
   `nix-manage.sh` stages automatically for exactly this reason.
3. **Comments explain WHY, not what.** They are the most valuable content in
   the repo. §25 is the index of those decisions.
4. **Secrets are sops-encrypted or they are not in the repo.**
5. **Every `permittedInsecurePackages` entry carries a comment** naming what
   needs it and why the risk is accepted. Unexplained entries outlive their
   reason.

### 03.3 Invariants — properties that must hold after any change

Treat a change that breaks one of these as a bug, not a trade-off, unless the
user explicitly asks for it.

| # | Invariant | Enforced by | Breaking it looks like |
|---|---|---|---|
| I1 | `nix.settings.trusted-users == [ "root" ]` | convention + option docs | a login-user compromise becomes a root compromise |
| I2 | `security.allowUserNamespaces == true` | **assertion** in `gaming/default.nix` | every Proton title and Roblox stops launching |
| I3 | `vm.max_map_count >= 262144` | **assertion** in `security/kernel.nix` | several DX12/Proton titles hard-fail |
| I4 | `users.mutableUsers == true` while `managePasswords` is on | **assertion** in `security/secrets.nix` | a failed decryption becomes a permanent lockout |
| I5 | nftables backend implies Docker is absent | **assertion** in `network/firewall.nix` | container networking silently breaks |
| I6 | nftables backend implies `extraCommands == ""` | **assertion** in `network/firewall.nix` | eval failure |
| I7 | every DoT server string carries a `#hostname` SNI suffix | **assertion** in `network/dns.nix` | every DNS lookup fails |
| I8 | `provider == "custom"` implies non-empty `servers` | **assertion** in `network/dns.nix` | no resolvers at all |
| I9 | `hashedPassword` is `null`, never `""` | option docs + **warning** | `""` declares an EMPTY PASSWORD for a wheel/libvirtd user |
| I10 | a password source exists before a fresh install | **warning** in `core/users.nix` | fresh install creates a locked account, recoverable only from the ISO |
| I11 | `kernel.sysrq != 0` | **warning** in `security/kernel.nix` | no clean recovery from a wedged NVIDIA/Wayland session |
| I12 | every `extraGroups` entry is a group something enabled creates | convention only — **NixOS silently drops unknown groups** | a permission silently does not exist, and it looks like it worked |
| I13 | every theme named in `arctic.plasma.theme.*` has its package installed | convention only — **Plasma silently falls back to Breeze** | the desktop looks wrong with no error anywhere |
| I14 | `arctic.plasma.panels == [ ]` unless declaring the entire layout | convention only | applying a layout deletes the appletsrc, taking every panel and widget with it |
| I15 | `system.stateVersion == "24.11"` | convention only | stateful defaults silently change under existing state |
| I16 | the age private key is never in git | `.gitignore` (deliberately broad patterns) | every secret in the repo becomes public |
| I17 | `hosts/arctic/disko.nix` `device` stays a placeholder | convention only | publishes the drive serial; and lets an unflagged disko run format the wrong disk |

Note the split: **I1–I11 fail loudly at eval time. I12–I17 fail silently.** The
silent ones are where the time goes.

---

## 04 — Verification cookbook

Every factual claim in this document is checkable. Prefer checking.

### 04.1 Does an option exist, and what does it say?

```bash
# All top-level arctic.* option groups
nix eval .#nixosConfigurations.arctic.options.arctic --apply builtins.attrNames

# One option's description, type, default, and declaring file
nix eval --raw .#nixosConfigurations.arctic.options.arctic.security.kernel.sysrq.description
nix eval --json .#nixosConfigurations.arctic.options.arctic.disk.useDisko.declarations
nix eval --json .#nixosConfigurations.arctic.options.arctic.network.dns.provider.type.name
```

### 04.2 What is a value right now?

```bash
# System-level
nix eval .#nixosConfigurations.arctic.config.arctic.desktop.plasma
nix eval --json .#nixosConfigurations.arctic.config.networking.firewall.allowedTCPPorts
nix eval --json .#nixosConfigurations.arctic.config.boot.kernelParams
nix eval --json .#nixosConfigurations.arctic.config.boot.blacklistedKernelModules
nix eval --json .#nixosConfigurations.arctic.config.users.users.arctic.extraGroups

# Home-manager level — note the doubled `arctic`
nix eval .#nixosConfigurations.arctic.config.home-manager.users.arctic.arctic.plasma.theme.iconTheme
```

### 04.3 Explore interactively — the fastest way to learn anything

```bash
nix repl
nix-repl> :lf .
nix-repl> nixosConfigurations.arctic.config.arctic.<TAB>
nix-repl> nixosConfigurations.arctic.options.arctic.security.<TAB>
nix-repl> nixosConfigurations.arctic.config.home-manager.users.arctic.arctic.<TAB>
```

### 04.4 Does it still build? What would change?

```bash
nix flake check                     # evaluates AND builds system.build.toplevel

nix build .#nixosConfigurations.arctic.config.system.build.toplevel --no-link \
  --print-out-paths | xargs nvd diff /run/current-system
```

### 04.5 Inspect the running system rather than the config

```bash
systemctl list-units --state=running        # what is actually up
systemctl list-timers
resolvectl status                            # DNS posture
sudo nft list ruleset                        # firewall as loaded
ss -tulpn                                    # what is listening
nix path-info -Sh /run/current-system        # closure size
sudo nix-env -p /nix/var/nix/profiles/system --list-generations
```

### 04.6 Where does a package come from?

```bash
nix why-depends /run/current-system nixpkgs#mbrola-voices
nix path-info -rSh /run/current-system | sort -k2 -h | tail -30
```

---

## 05 — Repository map

Every file, with its role. `★` marks the two files you will edit most.

```
flake.nix                   ENTRY POINT. Inputs (pinned deps) + outputs. §06
flake.lock                  Exact commit of every input. NEVER hand-edit.
                            This file is why the build is reproducible.
.sops.yaml                  PUBLIC. age recipients allowed to decrypt secrets/.
.gitignore                  Deliberately broad patterns so an age PRIVATE key
                            can never land next to the files it opens.
.directory                  KDE folder-icon metadata. UNTRACKED, irrelevant.

lib/
  default.nix               Exports the helpers. Currently just mkHost.
  mkHost.nix                THE ASSEMBLER. Builds a machine from parts. §07

hosts/
  arctic/
    default.nix          ★  THE MANIFEST. Every arctic.* switch for this box,
                            plus the home-manager block at the bottom. §15
    hardware.nix            nixos-generate-config output MINUS filesystems.
                            Initrd modules, kvm-intel, Intel microcode.
    disko.nix               Declarative LUKS+btrfs layout. §19

modules/nixos/              SYSTEM level — one machine, all users.
  default.nix               Imports the 8 subdirectories. Nothing else.
  core/
    default.nix             boot nix locale users shell packages hardware
    boot.nix                systemd-boot, kernel pin, initrd systemd, /tmp tmpfs
    nix.nix                 daemon settings, trusted-users, GC, allowUnfree
    locale.nix              timezone, locale, timesyncd
    users.nix               the primary user, mutableUsers, password sourcing
    shell.nix               fish + neovim as system defaults, EDITOR, aliases
    packages.nix            baseline CLI at SYSTEM level (root shells get them)
    hardware.nix            i2c, gvfs/MTP, AppImage binfmt, nix-ld, android udev
  desktop/
    default.nix             plasma themes gpu fonts audio wayland
    plasma.nix              SDDM + plasma6 + the speech/orca opt-out
    themes.nix              theme PACKAGES — the "assets" half. §18
    gpu.nix                 NVIDIA stack. NOTE it declares `arctic.gpu.nvidia`,
                            NOT `arctic.desktop.*`, despite living here.
    fonts.nix               font packages + fontconfig defaults
    audio.nix               PipeWire, low-latency quantum, rtkit
    wayland.nix             session env vars, incl. NVIDIA-conditional ones
  gaming/
    default.nix             master switch + the user-namespace assertion
    steam.nix               Steam, GE-Proton, gamescope session, protontricks
    performance.nix         gamescope, gamemode, RLIMIT_NOFILE
    launchers.nix           Lutris/Heroic/Prism/Wine/Bottles/MangoHud/Vulkan
    peripherals.nix         Wooting, Logitech wireless, Pico udev
  network/
    default.nix             base dns firewall tor tools (+ the "no VPN" note)
    base.nix                NetworkManager, MAC randomisation, extraHosts
    dns.nix                 systemd-resolved, DoT, DNSSEC, mDNS/LLMNR
    firewall.nix            nftables/iptables backend, ports, LocalSend
    tor.nix                 tor client daemon, SOCKS5 127.0.0.1:9050 only
    tools.nix               diagnostics, capture (wireshark), scanning
  security/
    default.nix             kernel sudo apparmor audit clamav gpg secrets
                            secureboot tools
    kernel.nix              sysctl / kernelParams / module blacklist / radios
    sudo.nix                sudo hardening, polkit, coredump limit
    apparmor.nix            OFF by design — read the option description
    audit.nix               kernel audit + auditd + a deliberately readable ruleset
    clamav.nix              freshclam + a sandboxed weekly scan timer
    gpg.nix                 gpg-agent, pinentry-qt, SSH support
    secrets.nix             sops-nix wiring, password sourcing
    secureboot.nix          lanzaboote, staged off
    tools.nix               crypto / proton / opsec / audit / offensive bundles
  virt/
    default.nix             containers libvirt
    containers.nix          rootless podman + dockerCompat + autoprune
    libvirt.nix             libvirtd + virt-manager
  apps/
    default.nix             flatpak browsers dev media office utilities RE
    flatpak.nix             declarative Flatpak (Sober/Roblox is the reason)
    browsers.nix            Brave, Tor Browser
    dev.nix                 kitty, claude-code, devtoolbox, VSCodium, PyCharm,
                            .NET SDK
    media.nix               VLC, OBS, GIMP, Navidrome, Jellyfin, qBittorrent
    office.nix              LibreOffice, Obsidian
    utilities.nix           monitors, archives, file managers, chat, ventoy,
                            ydotool/crossmacro
    reverse-engineering.nix Ghidra, ImHex
  disk/
    default.nix             disko impermanence
    disko.nix               the arctic.disk.useDisko flip
    impermanence.nix        ephemeral root, staged off, with the persist list

modules/home/               USER level — dotfiles and session.
  default.nix               shell dev terminal desktop packages
  packages.nix              user-scoped packages (jq, just, yt-dlp)
  shell/
    default.nix             fish starship tmux
    fish.nix                fish, modern CLI aliases, sessionPath
    starship.nix            prompt format and styling
    tmux.nix                C-a prefix, vi keys, mouse, splits
  dev/
    default.nix             git neovim ssh
    git.nix                 identity, aliases, pull.rebase, defaultBranch main
    neovim.nix              defaultEditor, no Ruby/Python hosts, base settings
    ssh.nix                 hardened CLIENT config, explicit ciphers
  terminal/
    default.nix             kitty
    kitty.nix               Tokyo Night, ligatures, keybindings, opacity
  desktop/
    default.nix             plasma
    plasma.nix           ★  the entire arctic.plasma.* API over plasma-manager
                            (983 lines — the largest module in the repo)

overlays/default.nix        `additions` exposes ./pkgs; `modifications` is
                            currently EMPTY (no nixpkgs packages are patched).
pkgs/
  default.nix               One line per locally-defined package.
  sweet-ambar-blue/         Vendored KDE theme: Plasma style + Aurorae
                            decoration + colour scheme. §18
  simpletux-splash/         Vendored Plasma 6 splash screen. §18

assets/wallpapers/          basement.jpg  (screen 0)
                            blackhole-abyss-wallpaper.jpg  (screen 1)
                            nixos-wallpaper-1.png  (UNUSED — nothing references it)
secrets/arctic.yaml         sops-encrypted. Committed — ciphertext is safe.
                            Keys: arctic-password, root-password.

nix-manage.sh               Interactive TUI: rebuild, test, update, diff,
                            generations, GC, optimise, status. Alias: `manage`.
INSTALL-CARD.txt            Printable offline reinstall crib sheet.
README.md                   Runbook: install, recover, verify.
EMPYREAN.md                 This file.
.claude/settings.local.json Claude Code permissions (currently an empty allowlist).
```

**Directory-to-namespace mapping.** Mostly regular, with two deliberate
exceptions worth memorising:

| Directory | Option namespace | Note |
|---|---|---|
| `modules/nixos/desktop/gpu.nix` | `arctic.gpu.nvidia` | **not** `arctic.desktop.gpu` — GPU is not desktop-only |
| `modules/home/desktop/plasma.nix` | `arctic.plasma` | **not** `arctic.desktop` — the NixOS tree already owns that leaf (§10) |

---

## 06 — The flake

`flake.nix` is the only file Nix looks at first. Everything else is reached
through it.

### 06.1 Inputs

Every input except `impermanence`, `nix-flatpak` and `nur` sets
`inputs.nixpkgs.follows = "nixpkgs"`, so there is exactly one nixpkgs driving
the system.

| Input | Purpose | Where it lands | Inert until |
|---|---|---|---|
| `nixpkgs` | `nixos-unstable` | everything | — |
| `home-manager` | user-level module system | `mkHost` → `nixosModules.home-manager` | — |
| `plasma-manager` | declarative Plasma 6 | `mkHost` → `sharedModules` | `programs.plasma.enable` |
| `sops-nix` | encrypted secrets | `mkHost` → `nixosModules.sops` | `arctic.security.secrets.enable` |
| `disko` | declarative partitioning | `mkHost` + `diskoConfigurations` | `arctic.disk.useDisko` |
| `lanzaboote` | UEFI Secure Boot | `mkHost` | `arctic.security.secureboot.enable` |
| `impermanence` | ephemeral root | `mkHost` | `arctic.disk.impermanence.enable` |
| `nix-flatpak` | declarative Flatpak | `mkHost` — exists for Sober/Roblox | `arctic.apps.flatpak.enable` |
| `nur` | Nix User Repository overlay | `mkHost` → `nixpkgs.overlays` | — (always applied) |

**All third-party NixOS modules are imported unconditionally and are inert
until their options are set.** That is the same Law 2 discipline the local
modules follow, applied to code this repo does not own.

### 06.2 Locked revisions as of this audit

| Input | Rev (short) | Locked |
|---|---|---|
| `nixpkgs` | `148bab9c1c3c` | 2026-08-01 |
| `nur` | `b4d9d89f110d` | 2026-08-01 |
| `home-manager` | `bf9ce9fec78f` | 2026-07-31 |
| `lanzaboote` | `c191775376b8` | 2026-07-30 |
| `plasma-manager` | `c551f0687658` | 2026-07-09 |
| `nix-flatpak` | `20d42f0ee98c` | 2026-07-06 |
| `sops-nix` | `f1406619a388` | 2026-07-04 |
| `disko` | `ff8702b4de27` | 2026-06-11 |
| `impermanence` | `7b1d382faf60` | 2026-01-27 |

`flake.lock` also contains **transitive** nodes: `crane`, `rust-overlay`,
`flake-parts`, `pre-commit`, `flake-compat`, and second copies of nixpkgs
(`nixpkgs`, pinned 2026-01-16) and home-manager (`home-manager_2`) pulled in by
lanzaboote. **Those are not what the system builds against** — the root
`nixpkgs` input resolves to the node named `nixpkgs_2`. If you read `flake.lock`
by hand, check `nodes.root.inputs` before believing a revision.

### 06.3 Outputs

| Output | What it is |
|---|---|
| `nixosConfigurations.arctic` | the machine. `myLib.mkHost { hostName = "arctic"; stateVersion = "24.11"; }` |
| `diskoConfigurations.arctic` | the raw disk layout, exposed at top level so `disko-install --flake .#arctic` can read it **without evaluating the whole host** |
| `nixosModules.default` | `./modules/nixos`, so another repo could consume this module tree |
| `homeManagerModules.default` | `./modules/home`, same |
| `overlays` | `additions` (exposes `./pkgs`) and `modifications` (empty) |
| `packages.<system>` | the locally-defined packages — `nix build .#sweet-ambar-blue` |
| `checks.<system>.arctic` | `config.system.build.toplevel` — this is what makes `nix flake check` a **real** check rather than a lint |
| `formatter` | `nixfmt-tree` (`nix fmt`) |
| `devShells.default` | see below |

### 06.4 The dev shell

```bash
nix develop
```

| Group | Tools |
|---|---|
| formatting / linting | `nixfmt-tree`, `statix`, `deadnix` |
| build ergonomics | `nix-output-monitor`, `nvd` |
| secrets & boot | `sops`, `age`, `ssh-to-age`, `sbctl`, `mkpasswd` |

Its `shellHook` exports `SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"`,
which is what makes `sops secrets/arctic.yaml` work with no further setup.

---

## 07 — `lib/mkHost.nix` — the assembler

The single place a machine is assembled. Everything true for **every** host
lives here; a host file contains nothing but `arctic.*` switches and its own
hardware facts.

```nix
{ hostName
, system ? "x86_64-linux"
, stateVersion
, homeStateVersion ? stateVersion
, users ? [ "arctic" ]
, extraModules ? [ ]
}
```

It produces one `nixpkgs.lib.nixosSystem` call with
`specialArgs = { inherit inputs outputs hostName system; }` and this module
list, **in this order**:

1. **nixpkgs instance + identity** — `nixpkgs.hostPlatform`, the three overlays
   (`nur.overlays.default`, `outputs.overlays.additions`,
   `outputs.overlays.modifications`), `networking.hostName`,
   `system.stateVersion`.
2. **Third-party NixOS modules** — sops-nix, nix-flatpak, disko, lanzaboote,
   impermanence.
3. **`../modules/nixos`** — declares every `arctic.*` OPTION.
4. **`../hosts/${hostName}`** — SETS those options.
5. **home-manager**, configured with:
   - `useGlobalPkgs = true` — one nixpkgs instance, with this repo's overlays,
     shared between system and home. Without it home-manager instantiates its
     own and `pkgs.sweet-ambar-blue` would not resolve in home modules.
   - `useUserPackages = true` — user packages land in the system profile path.
   - `backupFileExtension = "hm-bak"` — **load-bearing.** Without it, activation
     hard-fails on a fresh install the moment any unmanaged dotfile exists
     (`~/.config/fish/config.fish`, `~/.gitconfig`,
     `~/.config/kitty/kitty.conf` all qualify). Reproducibility depends on this
     one line.
   - `extraSpecialArgs = { inherit inputs outputs hostName; }`
   - `sharedModules = [ ../modules/home, plasma-manager, { home.stateVersion } ]`
   - `users = genAttrs users (user: { home.username; home.homeDirectory; })`

**Module order matters for readability, not for semantics.** The NixOS module
system is order-independent: it merges all definitions and resolves conflicts
by priority (`mkForce` > normal > `mkDefault`), not by position. The order above
is chosen so a reader encounters declarations before uses.

Adding a second machine is therefore:

```nix
# flake.nix
nixosConfigurations.laptop = myLib.mkHost {
  hostName = "laptop";
  stateVersion = "25.05";
};
```

plus a `hosts/laptop/` directory. **Nothing in `modules/` is touched.**

---

## 08 — The evaluation pipeline

Understanding the order matters because it tells you where a given error came
from.

```
  sudo nixos-rebuild switch --flake ~/nixos-config#arctic
        │
        ├─ 1. Read flake.nix, resolve inputs from flake.lock
        │       ← "input not found", lock/hash errors surface here
        │       ← UNTRACKED FILES ARE INVISIBLE from this point on
        │
        ├─ 2. Call myLib.mkHost { hostName = "arctic"; ... }
        │
        ├─ 3. mkHost builds ONE module list (order in §07)
        │
        ├─ 4. The module system merges everything into one `config`
        │       ← type errors, assertions, warnings, "option does not exist",
        │         and infinite recursion all surface here
        │
        ├─ 5. Build every derivation the result references
        │       ← compile errors, broken/insecure packages surface here
        │
        └─ 6. Activate: switch /run/current-system, start/stop units, run the
              home-manager activation (dotfiles + Plasma settings)
                ← activation script failures surface here
```

Steps 1–4 are pure evaluation and cost seconds. Step 5 is where time goes.
That is why `nix flake check` before a rebuild is worth the habit: it does 1–5
without touching the running system.

### 08.1 Assertions in this config — all evaluated at step 4

| Where | Asserts | Why it exists |
|---|---|---|
| `gaming/default.nix` | `security.allowUserNamespaces` | Steam pressure-vessel and bwrap/Sober both need it; disabling it is the most common way a "hardened" NixOS silently breaks every game |
| `network/dns.nix` | `provider == "custom"` → non-empty `servers` | otherwise resolved has no upstreams at all |
| `network/dns.nix` | strict DoT → every server carries a `#hostname` SNI suffix | strict DoT has nothing to validate the certificate against otherwise |
| `network/firewall.nix` | nftables backend → `extraCommands == ""` | the iptables escape hatch does not exist in the nftables backend |
| `network/firewall.nix` | nftables backend → Docker disabled | nftables blacklists `ip_tables`, which dockerd requires |
| `security/kernel.nix` | `vm.max_map_count >= 262144` | below this several DX12/Proton titles hard-fail |
| `security/secrets.nix` | `managePasswords` → `users.mutableUsers` | otherwise a failed decryption is a permanent lockout |

Upstream also asserts things this config relies on: plasma-manager asserts that
a window decoration `library` and `theme` are set together, and nixpkgs asserts
`services.clamav.scanner.enable → daemon.enable` (which is why this config uses
a hand-written timer instead — §20.5).

### 08.2 Warnings in this config

| Where | Warns when | Consequence if ignored |
|---|---|---|
| `core/users.nix` | no password source at all (`hashedPassword` and `hashedPasswordFile` both null) | a FRESH INSTALL creates a locked account; the fix requires booting the ISO again |
| `security/kernel.nix` | `sysrq == 0` | no escape hatch from a wedged NVIDIA/Wayland compositor |

Both are `warnings`, not `assertions`, because both are correct states on an
already-running machine — they only bite at install time or during a hang.

---

## 09 — Anatomy of a module

Every module here has the same four-part shape.

```nix
{ config, lib, pkgs, ... }:          # ① module arguments

let
  cfg = config.arctic.desktop;       # ② the shorthand, ALWAYS named `cfg`
in
{
  options.arctic.desktop = {         # ③ WHAT CAN BE CONFIGURED
    enable = lib.mkEnableOption "a graphical desktop";

    xserver = lib.mkOption {
      type = lib.types.bool;         #    typed — a wrong value is an eval error
      default = true;                #    what happens if nobody says otherwise
      description = ''               #    WHY you would change it
        Run the X server alongside Wayland. ...
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.plasma) {   # ④ WHAT THAT DOES
    services.xserver.enable = cfg.xserver;
    services.desktopManager.plasma6.enable = true;
    environment.systemPackages = with pkgs; [ kdePackages.spectacle ];
  };
}
```

**① Arguments.** `config` is the *fully merged* configuration of the whole
system. `lib` is nixpkgs' function library. `pkgs` is the package set with this
repo's overlays applied. `...` swallows arguments you did not ask for. Use `_:`
when you need none — every `default.nix` in this repo does exactly that.

**② `cfg`.** A convention, but a strict one: it makes every module readable the
same way, and `cfg` always points at *this module's own* option subtree.

**③ `options`.** The declaration. This is what makes `arctic.*` a real API:
each option has a type (so typos and wrong values fail at eval, not at
runtime), a default, and a description. It is also what makes options
discoverable via `nix eval` / `nix repl`.

**④ `config` wrapped in `lib.mkIf`.** The gate. When the condition is false the
whole attribute set evaporates and contributes nothing. This is exactly why
`modules/nixos/default.nix` can import everything unconditionally.

### 09.1 The two `config`s that are not the same thing

This trips up everyone once:

- `config` (the **argument**) = the whole system's merged configuration. **Read
  from it.**
- `config = { ... }` (the **attribute you define**) = this module's
  contribution. **Write to it.**

Same name, opposite directions. Reading `config.<x>` inside a module that also
defines `config.<x>` is the usual cause of infinite recursion (§26).

### 09.2 `lib` vocabulary actually used in this codebase

| Function | Does |
|---|---|
| `lib.mkIf cond { … }` | include this block only if `cond` |
| `lib.mkMerge [ a b ]` | combine several conditional definitions of one config block |
| `lib.mkEnableOption "desc"` | shorthand `bool` option defaulting to **false** |
| `lib.mkEnableOption "x" // { default = true; }` | …defaulting to **true**. Used heavily here |
| `lib.mkOption { type; default; description; }` | a full option declaration |
| `lib.optionals cond [ … ]` | that list if `cond`, else `[ ]`. The package-list idiom |
| `lib.optional cond x` | a ONE-element list if `cond`. Note the missing `s` |
| `lib.optionalAttrs cond { … }` | same as `optionals`, for attribute sets |
| `lib.mkDefault v` | a value any other definition beats |
| `lib.mkForce v` | a value that beats everything else |
| `lib.genAttrs` | build an attrset from a list of names (`mkHost`, `flake.nix`) |
| `lib.mapAttrs` | transform an attrset (the `hotkeys` mapping in the Plasma module) |
| `lib.escapeShellArgs` | safely interpolate paths into a systemd `ExecStart` (clamav) |
| `lib.concatStringsSep` | join a list into a string (clamav unit description) |
| `lib.hasInfix` | substring test (the DoT `#hostname` assertion) |
| `lib.all` | list predicate (same assertion) |
| `lib.literalExpression` | render a `defaultText` that Nix should not evaluate |

**Types in use:** `bool str int path package raw lines port listOf attrsOf enum
nullOr either submodule functionTo ints.between ints.positive ints.unsigned
numbers.between`.

### 09.3 Priority — where `mkDefault` and `mkForce` are used, and why

Normally two modules setting one option to different values is an eval error.
Priorities break the tie.

| Site | Uses | Because |
|---|---|---|
| `core/boot.nix` | `boot.loader.systemd-boot.enable = mkDefault true` | so `secureboot.nix` can displace it |
| `security/secureboot.nix` | `boot.loader.systemd-boot.enable = mkForce false` | lanzaboote replaces systemd-boot rather than sitting alongside it |
| `gaming/default.nix` | `mkDefault true` for steam/gamescope/gamemode/launchers | the master switch turns them on, but a host can still opt out of any single one on the next line |
| `desktop/plasma.nix` | `services.orca.enable = cfg.speech` (plain) | a plain assignment outranks plasma6's upstream `mkDefault true` |
| `desktop/plasma.nix` | `services.speechd.enable = mkForce cfg.speech` | pins it so a future module cannot quietly pull ~700 MB of diphones back in |
| `hosts/arctic/hardware.nix` | `hardware.cpu.intel.updateMicrocode = mkDefault …` | generated code; left as generated |
| `hosts/arctic/default.nix` | `terminal.kitty.fontSize = mkDefault 19` | so a future per-host override wins without a fight |
| `security/kernel.nix` | `networking.tempAddresses` via the NixOS option, not a raw sysctl | `network-interfaces.nix` already defines `net.ipv6.conf.*.use_tempaddr`; a raw sysctl produces "defined multiple times" |

---

## 10 — The two fixpoints

NixOS and home-manager are **separate module systems**. They are evaluated
together but do not share a namespace.

| | NixOS | home-manager |
|---|---|---|
| Configures | the machine | your user |
| Modules in | `modules/nixos/` | `modules/home/` |
| Option roots | `arctic.core.*` `arctic.desktop.*` `arctic.gpu.*` `arctic.gaming.*` `arctic.network.*` `arctic.security.*` `arctic.virt.*` `arctic.apps.*` `arctic.disk.*` | `arctic.shell.*` `arctic.dev.*` `arctic.terminal.*` `arctic.plasma.*` `arctic.home.*` |
| Set from | top level of `hosts/arctic/default.nix` | `home-manager.users.arctic.arctic = { … }` at the bottom of the same file |
| Writes to | `/etc`, `/run/current-system`, systemd **system** units | `~/.config`, `~/.local`, systemd **user** units |
| Needs root | yes | no |
| Eval path | `.#nixosConfigurations.arctic.config.arctic.*` | `.#nixosConfigurations.arctic.config.home-manager.users.arctic.arctic.*` |

### 10.1 Why the leaf names are disjoint

The NixOS tree owns `arctic.desktop`, so the home-manager Plasma module — which
lives in the directory `modules/home/desktop/` — declares its options under
`arctic.plasma`.

Nothing would technically break if both were `arctic.desktop`; they are
different fixpoints and would not collide. But then reading
`config.arctic.desktop.enable` in a file would not tell you which one you were
looking at. **The rule constrains the OPTION namespace, not the directory
name.**

### 10.2 Crossing between them

A home-manager module reads system config through the `osConfig` argument.
`modules/home/desktop/plasma.nix` is the live example:

```nix
{ config, lib, osConfig ? null, ... }:
let
  systemHasPlasma =
    osConfig != null
    && osConfig.arctic.desktop.enable
    && osConfig.arctic.desktop.plasma;
in { … }
```

The `? null` default keeps the module usable in a **standalone** home-manager
setup, where `osConfig` is not passed at all. **There is no supported path in
the other direction** — if a NixOS module needs to know something about your
user, pass it down rather than reaching up.

### 10.3 System vs. home — the rule of thumb

> Does it need root, affect other users, or affect the boot process? **System.**
> Is it your preference about how a program looks or behaves for you? **Home.**

One deliberate consequence: the CLI workhorses (`eza`, `bat`, `ripgrep`, `fd`,
`fzf`, `zoxide`, `tmux`, `git`) are declared at **system** level in
`core/packages.nix`, so they exist in a root shell and in a recovery console.
`modules/home/packages.nix` holds only what is genuinely user-scoped
(`jq`, `just`, `yt-dlp`). Declaring them in both places would just build two
profiles containing the same store paths.

---

## 11 — Master option index

Every `arctic.*` option in the repository, flat and alphabetical. This is the
lookup table: it answers "where is it declared, what type is it, what is the
default, and what is it on this machine" in one place.

**Legend.** **bold true** = a default of `true` (Law 2 exception). **bold** in
the *arctic* column = the manifest overrides the default. `—` = the manifest
says nothing, so the default applies. `HM` = home-manager fixpoint, set inside
`home-manager.users.arctic.arctic`.

### 11.1 `arctic.apps.*` — `modules/nixos/apps/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `apps.browsers.enable` | browsers.nix | bool | false | **true** |
| `apps.browsers.brave` | browsers.nix | bool | **true** | — |
| `apps.browsers.tor` | browsers.nix | bool | **true** | — |
| `apps.dev.enable` | dev.nix | bool | false | **true** |
| `apps.dev.editors` | dev.nix | bool | **true** | true |
| `apps.dev.dotnet` | dev.nix | bool | false | **true** |
| `apps.flatpak.enable` | flatpak.nix | bool | false | **true** |
| `apps.flatpak.apps` | flatpak.nix | listOf str | `[ ]` | **4 IDs** |
| `apps.flatpak.uninstallUnmanaged` | flatpak.nix | bool | false | **true** |
| `apps.media.enable` | media.nix | bool | false | **true** |
| `apps.media.creation` | media.nix | bool | **true** | true |
| `apps.media.server` | media.nix | bool | false | **true** |
| `apps.media.torrent` | media.nix | bool | **true** | true |
| `apps.office.enable` | office.nix | bool | false | **true** |
| `apps.reverseEngineering.enable` | reverse-engineering.nix | bool | false | **true** |
| `apps.utilities.enable` | utilities.nix | bool | false | **true** |
| `apps.utilities.monitoring` | utilities.nix | bool | **true** | — |
| `apps.utilities.archives` | utilities.nix | bool | **true** | — |
| `apps.utilities.fileManagers` | utilities.nix | bool | **true** | — |
| `apps.utilities.chat` | utilities.nix | bool | **true** | — |
| `apps.utilities.usbTooling` | utilities.nix | bool | false | **true** |
| `apps.utilities.automation` | utilities.nix | bool | false | **true** |

### 11.2 `arctic.core.*` — `modules/nixos/core/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `core.boot.enable` | boot.nix | bool | **true** | — |
| `core.boot.kernelPackage` | boot.nix | raw | `pkgs.linuxPackages_6_12` | — |
| `core.boot.tmpfsSize` | boot.nix | str | `"50%"` | `"50%"` |
| `core.hardware.enable` | hardware.nix | bool | **true** | — |
| `core.hardware.i2c` | hardware.nix | bool | **true** | — |
| `core.hardware.mtp` | hardware.nix | bool | **true** | — |
| `core.hardware.android` | hardware.nix | bool | false | **true** |
| `core.hardware.appimage` | hardware.nix | bool | **true** | — |
| `core.hardware.nixLd` | hardware.nix | bool | **true** | — |
| `core.hardware.nixLdLibraries` | hardware.nix | functionTo (listOf package) | `p: [ curl openssl stdenv.cc.cc.lib ]` | — |
| `core.locale.enable` | locale.nix | bool | **true** | — |
| `core.locale.timeZone` | locale.nix | str | `"America/New_York"` | same |
| `core.locale.defaultLocale` | locale.nix | str | `"en_US.UTF-8"` | same |
| `core.nix.enable` | nix.nix | bool | **true** | — |
| `core.nix.trustedUsers` | nix.nix | listOf str | `[ "root" ]` | `[ "root" ]` |
| `core.nix.trustedSubstituters` | nix.nix | listOf str | `[ ]` | — |
| `core.nix.trustedPublicKeys` | nix.nix | listOf str | `[ ]` | — |
| `core.nix.allowUnfree` | nix.nix | bool | **true** | — |
| `core.nix.permittedInsecurePackages` | nix.nix | listOf str | `[ ]` | **`[ "ventoy-qt5-1.1.12" ]`** |
| `core.nix.gc.enable` | nix.nix | bool | **true** | — |
| `core.nix.gc.dates` | nix.nix | str | `"weekly"` | — |
| `core.nix.gc.keepDays` | nix.nix | int | `7` | — |
| `core.packages.enable` | packages.nix | bool | **true** | — |
| `core.packages.devEssentials` | packages.nix | bool | **true** | — |
| `core.packages.database` | packages.nix | bool | false | **true** |
| `core.shell.enable` | shell.nix | bool | **true** | — |
| `core.shell.fish` | shell.nix | bool | **true** | — |
| `core.shell.neovim` | shell.nix | bool | **true** | — |
| `core.users.enable` | users.nix | bool | **true** | — |
| `core.users.mutableUsers` | users.nix | bool | **true** | — |
| `core.users.primary.name` | users.nix | str | `"arctic"` | `"arctic"` |
| `core.users.primary.description` | users.nix | str | `"arctic"` | `"arctic"` |
| `core.users.primary.shell` | users.nix | raw | `pkgs.fish` | — |
| `core.users.primary.extraGroups` | users.nix | listOf str | `[ ]` | **13 groups** |
| `core.users.primary.hashedPassword` | users.nix | nullOr str | `null` | `null` |
| `core.users.primary.hashedPasswordFile` | users.nix | nullOr path | `null` | **set by `security.secrets`** |

### 11.3 `arctic.desktop.*` / `arctic.gpu.*` — `modules/nixos/desktop/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `desktop.enable` | plasma.nix | bool | false | **true** |
| `desktop.plasma` | plasma.nix | bool | **true** | true |
| `desktop.xserver` | plasma.nix | bool | **true** | true |
| `desktop.speech` | plasma.nix | bool | false | — (off) |
| `desktop.audio.enable` | audio.nix | bool | **true** | — |
| `desktop.audio.lowLatency` | audio.nix | bool | **true** | true |
| `desktop.fonts.enable` | fonts.nix | bool | **true** | — |
| `desktop.fonts.monospace` | fonts.nix | str | `"JetBrainsMono Nerd Font"` | — |
| `desktop.themes.enable` | themes.nix | bool | **true** | — |
| `desktop.themes.icons` | themes.nix | bool | **true** | true |
| `desktop.themes.cursors` | themes.nix | bool | **true** | true |
| `desktop.themes.sweet` | themes.nix | bool | false | **true** |
| `desktop.themes.whiteSur` | themes.nix | bool | false | **true** |
| `desktop.themes.vendored` | themes.nix | bool | **true** | true |
| `desktop.wayland.enable` | wayland.nix | bool | **true** | — |
| `gpu.nvidia.enable` | gpu.nix | bool | false | **true** |
| `gpu.nvidia.open` | gpu.nix | bool | **true** | true |
| `gpu.nvidia.branch` | gpu.nix | enum stable/beta/production/latest | `"stable"` | `"stable"` |
| `gpu.nvidia.vaapi` | gpu.nix | bool | **true** | true |
| `gpu.nvidia.powerManagement` | gpu.nix | bool | false | — (laptops) |

### 11.4 `arctic.disk.*` — `modules/nixos/disk/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `disk.useDisko` | disko.nix | bool | false | **true** |
| `disk.impermanence.enable` | impermanence.nix | bool | false | false (staged) |
| `disk.impermanence.root` | impermanence.nix | str | `"/persist"` | — |
| `disk.impermanence.wipeHome` | impermanence.nix | bool | false | false |

### 11.5 `arctic.gaming.*` — `modules/nixos/gaming/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `gaming.enable` | default.nix | bool | false | **true** |
| `gaming.nofileLimit` | performance.nix | int | `1048576` | — |
| `gaming.gamescope.enable` | performance.nix | bool | false → `mkDefault true` | true |
| `gaming.gamemode.enable` | performance.nix | bool | false → `mkDefault true` | true |
| `gaming.steam.enable` | steam.nix | bool | false → `mkDefault true` | true |
| `gaming.steam.protonGE` | steam.nix | bool | **true** | true |
| `gaming.steam.gamescopeSession` | steam.nix | bool | **true** | — |
| `gaming.steam.openFirewall` | steam.nix | bool | false | — (off) |
| `gaming.launchers.enable` | launchers.nix | bool | false → `mkDefault true` | true |
| `gaming.launchers.minecraft` | launchers.nix | bool | **true** | true |
| `gaming.launchers.wine` | launchers.nix | bool | **true** | true |
| `gaming.peripherals.wooting` | peripherals.nix | bool | false | **true** |
| `gaming.peripherals.pico` | peripherals.nix | bool | false | **true** |
| `gaming.peripherals.logitech` | peripherals.nix | bool | false | **true** |
| `gaming.peripherals.logitechGui` | peripherals.nix | bool | **true** | — |

### 11.6 `arctic.network.*` — `modules/nixos/network/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `network.manager.enable` | base.nix | bool | **true** | — |
| `network.manager.wifiMacAddress` | base.nix | enum preserve/permanent/random/stable | `"random"` | `"random"` (inert, see §14) |
| `network.manager.ethernetMacAddress` | base.nix | same enum | `"permanent"` | `"permanent"` |
| `network.extraHosts` | base.nix | lines | `""` | **3 BattlEye entries** |
| `network.dns.enable` | dns.nix | bool | **true** | true |
| `network.dns.provider` | dns.nix | enum quad9/mullvad/cloudflare/custom | `"quad9"` | `"quad9"` |
| `network.dns.servers` | dns.nix | listOf str | `[ ]` | — |
| `network.dns.overTls` | dns.nix | bool | **true** | true |
| `network.dns.dnssec` | dns.nix | bool | **true** | true |
| `network.dns.mdns` | dns.nix | bool | **true** | true |
| `network.dns.llmnr` | dns.nix | bool | false | false |
| `network.firewall.enable` | firewall.nix | bool | **true** | — |
| `network.firewall.backend` | firewall.nix | enum iptables/nftables | `"nftables"` | `"nftables"` |
| `network.firewall.allowedTCPPorts` | firewall.nix | listOf port | `[ ]` | — |
| `network.firewall.allowedUDPPorts` | firewall.nix | listOf port | `[ ]` | — |
| `network.firewall.localsend` | firewall.nix | bool | false | **true** |
| `network.firewall.extraCommands` | firewall.nix | lines | `""` | — (iptables only) |
| `network.firewall.extraInputRules` | firewall.nix | lines | `""` | — (nftables only) |
| `network.tor.enable` | tor.nix | bool | false | **true** |
| `network.tools.enable` | tools.nix | bool | false | **true** |
| `network.tools.capture` | tools.nix | bool | false | **true** |
| `network.tools.captureGui` | tools.nix | bool | **true** | — |
| `network.tools.scanning` | tools.nix | bool | false | **true** |

### 11.7 `arctic.security.*` — `modules/nixos/security/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `security.apparmor.enable` | apparmor.nix | bool | false | false (**deliberate**, §20.6) |
| `security.audit.enable` | audit.nix | bool | false | **true** |
| `security.clamav.enable` | clamav.nix | bool | false | **true** |
| `security.clamav.scanPaths` | clamav.nix | listOf str | `[ "/home/arctic/Downloads" ]` | — |
| `security.clamav.interval` | clamav.nix | str | `"Sun 03:00"` | — |
| `security.gpg.enable` | gpg.nix | bool | **true** | true |
| `security.gpg.sshSupport` | gpg.nix | bool | **true** | — |
| `security.gpg.pinentry` | gpg.nix | raw | `pkgs.pinentry-qt` | — |
| `security.kernel.hardenSysctl` | kernel.nix | bool | **true** | true |
| `security.kernel.hardenParams` | kernel.nix | bool | **true** | true |
| `security.kernel.blacklistModules` | kernel.nix | bool | **true** | true |
| `security.kernel.disableRadios` | kernel.nix | bool | false | **true** |
| `security.kernel.sysrq` | kernel.nix | int | `16` | `16` |
| `security.kernel.initOnFree` | kernel.nix | bool | false | false |
| `security.kernel.ipv6PrivacyExtensions` | kernel.nix | bool | **true** | true |
| `security.secrets.enable` | secrets.nix | bool | false | **true** |
| `security.secrets.ageKeyFile` | secrets.nix | path | `/var/lib/sops-nix/key.txt` | — |
| `security.secrets.defaultSopsFile` | secrets.nix | path | `secrets/arctic.yaml` | — |
| `security.secrets.managePasswords` | secrets.nix | bool | false | **true** |
| `security.secureboot.enable` | secureboot.nix | bool | false | false (**staged**) |
| `security.secureboot.pkiBundle` | secureboot.nix | path | `/var/lib/sbctl` | — |
| `security.secureboot.autoProvision` | secureboot.nix | bool | **true** | true |
| `security.secureboot.includeMicrosoftKeys` | secureboot.nix | bool | **true** | true |
| `security.sudo.harden` | sudo.nix | bool | **true** | true |
| `security.tools.enable` | tools.nix | bool | false | **true** |
| `security.tools.crypto` | tools.nix | bool | **true** | true |
| `security.tools.proton` | tools.nix | bool | **true** | true |
| `security.tools.opsec` | tools.nix | bool | **true** | true |
| `security.tools.audit` | tools.nix | bool | false | **true** |
| `security.tools.offensive` | tools.nix | bool | false | **true** |

### 11.8 `arctic.virt.*` — `modules/nixos/virt/`

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `virt.podman.enable` | containers.nix | bool | false | **true** |
| `virt.podman.dockerCompat` | containers.nix | bool | **true** | true |
| `virt.libvirt.enable` | libvirt.nix | bool | false | **true** |

### 11.9 `HM` — `modules/home/` (non-Plasma)

| Option | File | Type | Default | arctic |
|---|---|---|---|---|
| `dev.git.enable` | dev/git.nix | bool | **true** | — |
| `dev.git.userName` | dev/git.nix | str | `"arctic"` | — |
| `dev.git.userEmail` | dev/git.nix | str | `"arctictweak@gmail.com"` | same, set explicitly |
| `dev.neovim.enable` | dev/neovim.nix | bool | **true** | — |
| `dev.ssh.enable` | dev/ssh.nix | bool | **true** | — |
| `home.packages.enable` | packages.nix | bool | **true** | — |
| `shell.fish.enable` | shell/fish.nix | bool | **true** | — |
| `shell.fish.modernCliAliases` | shell/fish.nix | bool | **true** | — |
| `shell.starship.enable` | shell/starship.nix | bool | **true** | — |
| `shell.tmux.enable` | shell/tmux.nix | bool | **true** | — |
| `terminal.kitty.enable` | terminal/kitty.nix | bool | **true** | — |
| `terminal.kitty.fontFamily` | terminal/kitty.nix | str | `"JetBrainsMono Nerd Font"` | — |
| `terminal.kitty.fontSize` | terminal/kitty.nix | int | `19` | **`mkDefault 19`** |
| `terminal.kitty.opacity` | terminal/kitty.nix | str | `"0.90"` | — |

### 11.10 `HM` — `arctic.plasma.*` — `modules/home/desktop/plasma.nix`

**Every option here defaults to `null`, and a null is never written.** Enabling
the module changes nothing on its own; it takes ownership of exactly the keys
the manifest names.

| Option | Type | arctic |
|---|---|---|
| `plasma.enable` | bool | follows `osConfig.arctic.desktop.plasma` → **true** |
| `plasma.overrideConfig` | bool | `false` (default) — see §18.9 |
| **theme** | | |
| `theme.lookAndFeel` | nullOr str | **null — deliberately** (§18.3) |
| `theme.colorScheme` | nullOr str | `"SweetAmbarBlue"` |
| `theme.plasmaStyle` | nullOr str | `"Sweet-Ambar-Blue"` |
| `theme.widgetStyle` | nullOr str | null (Plasma's built-in default in force) |
| `theme.iconTheme` | nullOr str | `"Papirus"` |
| `theme.soundTheme` | nullOr str | `"freedesktop"` |
| `theme.splashScreen` | nullOr str | `"SimpleTuxSplash-Plasma6"` |
| `theme.windowDecoration.library` | nullOr str | `"org.kde.kwin.aurorae.v2"` |
| `theme.windowDecoration.theme` | nullOr str | `"__aurorae__svg__Sweet-ambar-blue"` |
| `theme.titlebarButtons.left` / `.right` | nullOr (listOf str) | null |
| `theme.wallpaper` | nullOr (path or listOf path) | **2 paths, per-screen** |
| **cursor** | | |
| `cursor.theme` | nullOr str | `"WhiteSur-cursors"` |
| `cursor.size` | nullOr ints.positive | `24` |
| **fonts** | | |
| `fonts.family` | nullOr str | `"Noto Sans"` |
| `fonts.monospace` | nullOr str | `"JetBrainsMono Nerd Font"` |
| `fonts.size` | nullOr ints.positive | `10` |
| **input** | | |
| `input.mice` | listOf submodule | **one entry** (below) |
| `input.keyboard.numlockOnStartup` | nullOr enum on/off/unchanged | `"on"` |
| `input.keyboard.repeatDelay` | nullOr ints 100–5000 | null |
| `input.keyboard.repeatRate` | nullOr numbers 0.2–100 | null |
| `input.keyboard.options` | nullOr (listOf str) | null |
| **behavior** | | |
| `behavior.clickItemTo` | nullOr enum open/select | null |
| `behavior.doubleClickInterval` | nullOr ints.positive | `200` |
| `behavior.animationSpeed` | nullOr numbers 0–10 | `0.75` |
| `behavior.tooltipDelay` | nullOr ints.positive | null |
| `behavior.middleClickPaste` | nullOr bool | null |
| `behavior.confirmLogout` | nullOr bool | null |
| `behavior.restoreSession` | nullOr enum | null |
| **kwin** | | |
| `kwin.virtualDesktops.number` | nullOr ints.positive | `1` |
| `kwin.virtualDesktops.rows` | nullOr ints.positive | `1` |
| `kwin.virtualDesktops.names` | nullOr (listOf str) | null |
| `kwin.borderlessMaximized` | nullOr bool | null |
| `kwin.edgeBarrier` | nullOr ints 0–1000 | null |
| `kwin.cornerBarrier` | nullOr bool | null |
| `kwin.tilingPadding` | nullOr ints 0–36 | `4` |
| `kwin.effects.blur` / `.blurStrength` | nullOr bool / ints 1–15 | null |
| `kwin.effects.dimInactive` / `.slideBack` / `.snapHelper` | nullOr bool | null |
| `kwin.effects.shakeCursor` | nullOr bool | **`false`** |
| `kwin.nightLight.enable` / `.mode` / `.dayTemperature` / `.nightTemperature` / `.morningTime` / `.eveningTime` / `.transitionTime` | various nullOr | all null |
| **screenLocker** | | |
| `screenLocker.autoLock` | nullOr bool | **`false`** |
| `screenLocker.timeout` | nullOr ints.unsigned | null |
| `screenLocker.lockOnResume` | nullOr bool | **`false`** |
| `screenLocker.passwordRequired` | nullOr bool | null |
| `screenLocker.graceTime` | nullOr ints.unsigned | null |
| **power** (AC profile only) | | |
| `power.turnOffDisplayIdle` | nullOr ints.unsigned | null |
| `power.autoSuspendAction` | nullOr enum | null |
| `power.powerButtonAction` | nullOr enum | null |
| **escape hatches** | | |
| `shortcuts` | attrsOf (attrsOf (str or listOf str)) | `{ }` |
| `hotkeys` | attrsOf submodule {name,key,command} | `{ }` |
| `panels` | listOf (attrsOf anything) | `[ ]` — **destructive when non-empty** |
| `extraSettings` | attrsOf attrsOf attrsOf anything | **2 kdeglobals keys** |

`input.mice` submodule fields: `name`, `vendorId`, `productId` (all `str`,
required), plus nullable `sensitivity` (−1…1), `accelerationProfile`
(`none`/`default`), `naturalScroll`, `scrollSpeed` (0.1…20), `leftHanded`,
`middleButtonEmulation`.

---

## 12 — System option reference

The detail behind each system module. Types and values are in §11; this section
is the **why**.

### 12.1 `arctic.core.boot` — `core/boot.nix`

Sets `boot.loader.systemd-boot.enable` (`mkDefault true`),
`boot.loader.efi.canTouchEfiVariables`, `boot.kernelPackages`,
`boot.initrd.systemd.enable = true`, and `boot.tmp.{useTmpfs,tmpfsSize,cleanOnBoot}`.

**The kernel is pinned to 6.12**, not `linuxPackages_latest`: the NVIDIA
out-of-tree module regularly lags the newest kernel by a release or two, and a
kernel the driver will not build against is an unbootable GPU.

**systemd in the initrd** gives better LUKS handling, proper unit ordering, and
is a prerequisite for TPM/FIDO2 unlock should that ever be wanted.

**`tmpfsSize` is a percentage, not an absolute.** The nix daemon builds in
`/tmp`; a fixed size at or near total RAM lets one large Chromium or Electron
build OOM the whole machine. This box has ~31.2 GiB, so 50% is ~15.6 GiB.

### 12.2 `arctic.core.nix` — `core/nix.nix`

Also sets, unconditionally: `experimental-features = [ nix-command flakes ]`,
`auto-optimise-store`, `sandbox = true`, `max-jobs = "auto"`, `cores = 0`,
`keep-outputs = true`, `keep-derivations = true`.

**`trustedUsers` is root-only and must stay that way (I1).** A trusted user can
set `post-build-hook` / `builders` per invocation — which the daemon runs **as
root** — and can import unsigned paths into the store. "Trusted user" is a
synonym for root. `nixos-rebuild` is unaffected because it already runs under
sudo. If you need a third-party binary cache, use `trustedSubstituters`, which
is the narrow version of the same permission.

`keep-outputs` / `keep-derivations` keep the build inputs of the current system
around, so `nix develop` and post-GC rebuilds do not re-download the world.

**`gc.keepDays` is also your rollback window.** Weekly GC deleting anything
older than 7 days means generations older than a week are gone.

### 12.3 `arctic.core.locale` — `core/locale.nix`

Also enables `services.timesyncd`. Accurate time is load-bearing for TLS
validation, TOTP codes and log correlation — all three fail confusingly when
the clock drifts.

### 12.4 `arctic.core.users` — `core/users.nix`

Current groups on `arctic`, each annotated with what creates it:

```
wheel           sudo
networkmanager  networking.networkmanager.enable
video render    graphics
audio input     devices
i2c             hardware.i2c.enable              (DDC/CI monitor control)
dialout         serial devices (Pico)
tor             services.tor.enable
wireshark       programs.wireshark.enable
ydotool         programs.ydotool.enable
kvm libvirtd    virtualisation.libvirtd.enable   ← ROOT-EQUIVALENT
```

There is **no `docker` group**, deliberately — it was root-equivalent by design
and rootless Podman does not need it.

**Three facts that matter here:**

1. **NixOS silently DROPS groups that do not exist (I12).** A typo fails *open*
   and looks like it worked. Every group above is created by something this
   config actually enables — which is why the coupling table in §14 lists them.
2. **`hashedPassword = null` is not `""` (I9).** The empty string declares an
   EMPTY PASSWORD, which would let anyone at the physical console get a shell as
   this wheel/libvirtd user. `null` means "no password via this mechanism."
3. **`mutableUsers = true` is deliberate and composes correctly with sops
   (I4).** With `true`, a declared hash SEEDS the account when it is first
   created (a fresh install) and `passwd` still works and survives rebuilds
   afterwards. With `false`, the hash is re-asserted on every activation and
   `passwd` is futile — turning a failed secret decryption into a permanent
   lockout.

The module emits a **warning** when no password source exists at all, because
that state is harmless on a running machine and catastrophic on a fresh install
(§08.2).

### 12.5 `arctic.core.shell` — `core/shell.nix`

fish must be enabled at the **system** level to be a valid login shell, even
though home-manager owns its actual configuration. Also sets
`EDITOR`/`VISUAL = nvim`, `environment.homeBinInPath`, and exactly two
system-wide aliases: `manage` and `cls`.

**Interactive conveniences deliberately do NOT live here.** Putting
`ls → eza` / `cat → bat` in `/etc/profile` means `sudo -i; grep -r` silently
behaves differently from `grep -r`, which is a genuine footgun during an
incident. They live in `modules/home/shell/fish.nix` instead.

### 12.6 `arctic.core.packages` — `core/packages.nix`

Deliberately at **system** level rather than home-manager: these are the tools
you need in a root shell or a recovery console, where the user profile is not
loaded.

| Group | Packages |
|---|---|
| always | `git file tree` · `bat fd ripgrep eza fzf zoxide tmux` · `fastfetch lm_sensors pciutils usbutils libmtp` |
| `devEssentials` | `gcc gnumake nodejs_22 python3 python3Packages.pip` |
| `database` | `postgresql_16` |

### 12.7 `arctic.core.hardware` — `core/hardware.nix`

Always sets `hardware.enableRedistributableFirmware = true`. Toggles map to
`hardware.i2c`, `services.gvfs` (MTP), `programs.appimage` (with `binfmt`),
`programs.nix-ld`, and one udev rule.

**Keep `nixLdLibraries` SHORT.** nix-ld is a deliberate hole in the "everything
is a derivation" guarantee: it lets arbitrary downloaded ELF binaries link
against a curated library set and run unaudited.

The Android udev rule uses **`TAG+="uaccess"`**, which hands the device to
whoever is logged in at the seat via systemd-logind ACLs. The idiom most guides
show — `MODE="0666"` plus `GROUP="plugdev"` — is wrong twice over on NixOS:
`0666` makes the device world-writable to every process on the machine, and
`plugdev` is a Debian-ism that does not exist here, so the `GROUP=` is silently
ignored rather than restricting anything.

### 12.8 `arctic.desktop` — `desktop/plasma.nix`

Enables SDDM (`wayland.enable`, `theme = "breeze"`, `autoNumlock = true`),
`services.desktopManager.plasma6`, and installs `kdePackages.spectacle`.

`xserver = true` keeps an X11 fallback session selectable at the SDDM greeter —
useful when a driver update breaks Wayland. It is **not** required for a Wayland
Plasma session; XWayland comes from plasma6 itself. Turning it off shrinks the
closure.

**`speech` is the largest single closure saving in this config.** plasma6
enables text-to-speech by default; speech-dispatcher pulls mbrola, which pulls
`mbrola-voices` at ~676 MB of recorded diphones, and nothing here speaks.

The real switch is **`services.orca.enable`, not speechd**: plasma6 sets
`services.orca.enable = mkDefault true`, and the orca module then turns on
speechd itself — so disabling speechd alone gets silently re-enabled and keeps
the screen reader installed anyway. orca is also **not** in plasma6's
`optionalPackages`, so `environment.plasma6.excludePackages` cannot reach it
either. The module therefore sets both: `services.orca.enable = cfg.speech` as a
plain assignment (which outranks the upstream `mkDefault`), plus
`services.speechd.enable = lib.mkForce cfg.speech` as a pin so a future module
cannot quietly pull the diphones back in.

**Turn `speech` back on if you want a screen reader** (Orca), KDE's "Speak Text"
actions, or any accessibility TTS. 676 MB is a bad reason to go without
accessibility if you need it.

### 12.9 `arctic.desktop.themes` — `desktop/themes.nix`

| Toggle | Installs |
|---|---|
| `icons` | `papirus-icon-theme`, `candy-icons` |
| `cursors` | `whitesur-cursors` |
| `sweet` | `sweet-nova` (base Sweet only — **not** Ambar Blue) |
| `whiteSur` | `whitesur-kde`, `whitesur-icon-theme` |
| `vendored` | `sweet-ambar-blue`, `simpletux-splash` (from `pkgs/`) |

Gated on `arctic.desktop.enable && cfg.enable`. This is the **assets** half
only; the selection half is `arctic.plasma.theme.*`. See §18 for the full
model — and note I13: naming a theme whose package is absent does not error.

### 12.10 `arctic.gpu.nvidia` — `desktop/gpu.nix`

Sets `services.xserver.videoDrivers = [ "nvidia" ]`,
`hardware.graphics.{enable, enable32Bit, extraPackages}` and
`hardware.nvidia.{modesetting, open, powerManagement, nvidiaSettings, package}`.
The driver package is resolved as
`config.boot.kernelPackages.nvidiaPackages.${branch}`, which is why the kernel
pin and the driver branch are coupled.

`open = true` is correct for Turing (RTX 20xx) and newer; this host is Ampere.
Set it `false` for Pascal and older, where the open module does not support the
GPU at all.

**`enable32Bit` is non-negotiable** for Steam, Proton and Wine.

### 12.11 `arctic.desktop.audio` — `desktop/audio.nix`

PipeWire with ALSA (+32-bit for Wine/Proton), PulseAudio and JACK emulation,
plus `security.rtkit.enable` and `pavucontrol` / `pamixer`.

`lowLatency` pins the quantum to 32 samples @ 48 kHz (~0.67 ms) via
`extraConfig.pipewire."92-low-latency"`. **If you get crackling under heavy CPU
load, this is the first thing to turn off** — a starved quantum produces xruns,
and the fix is a larger buffer, not a faster CPU. `rtkit` is what lets the
requested quantum actually be *met* rather than merely requested.

### 12.12 `arctic.desktop.fonts` — `desktop/fonts.nix`

Packages: `nerd-fonts.jetbrains-mono`, `nerd-fonts.fira-code`, `noto-fonts`,
`noto-fonts-cjk-sans`, `noto-fonts-color-emoji`, `liberation_ttf` (metric-
compatible with Arial/Times, for Office documents). fontconfig defaults:
monospace = the option, sansSerif = Noto Sans, serif = Noto Serif.

Anything named in `arctic.plasma.fonts.*` or `arctic.terminal.kitty.fontFamily`
must be resolvable from this set (§14).

### 12.13 `arctic.desktop.wayland` — `desktop/wayland.nix`

| Always | When `arctic.gpu.nvidia.enable` |
|---|---|
| `NIXOS_OZONE_WL = "1"` | `__GL_GSYNC_ALLOWED = "1"` |
| `QT_QPA_PLATFORM = "wayland;xcb"` | `__GL_VRR_ALLOWED = "1"` |
| `GDK_BACKEND = "wayland,x11"` | `LIBVA_DRIVER_NAME = "nvidia"` |
| `SDL_VIDEODRIVER = "wayland"` | |

Two variables are **deliberately absent** and the reason is recorded in the
file: `MOZ_DISABLE_RDD_SANDBOX=1` was added to fix VA-API in Firefox, which is
not installed — but Tor Browser *is* Firefox and does read it, so the only
effect it ever had was disabling the media-decode process sandbox in the one
browser on this machine where that sandbox matters most. `MOZ_ENABLE_WAYLAND`
went with it for the same reason.

### 12.14 `arctic.gaming` — `gaming/`

`arctic.gaming.enable` is a **master switch**: it turns on steam, gamescope,
gamemode and launchers via `mkDefault`, so a host can still opt out of any
single one on the next line. It also carries the user-namespace assertion (I2).

**`nofileLimit`** raises the hard `RLIMIT_NOFILE` to 1048576 via
`security.pam.loginLimits` — several Proton titles and Steam itself exhaust the
default 1024 and fail with confusing "too many open files" errors.

**`steam.openFirewall` stays off.** Remote Play / dedicated server / LAN
transfer ports listen on the LAN and none are needed for single-player or
normal online play.

**`steam.protonGE`** ships GE-Proton as a declarative compatibility tool
(`programs.steam.extraCompatPackages`) rather than letting protonup-qt download
it into `~/.steam` at runtime. Same result, except this one survives a wipe. The
module also enables `programs.steam.protontricks`, which is wrapped with the
right `extraCompatPaths` — the bare `pkgs.protontricks` in `systemPackages`
cannot see GE-Proton prefixes.

**gamemode settings:** `renice 10`, `ioprio 0`, `park_cores = "no"`,
`pin_cores = "yes"`, and — only when NVIDIA is on —
`apply_gpu_optimisations = "accept-responsibility"`, `gpu_device = 0`,
`nv_powermizer_mode = 1` and `nv_powermizermode_game = 1` (prefer maximum
performance).

**gamescope** gets `capSysNice = true`, which lets it raise its own scheduling
priority; that is most of where its frame-pacing advantage comes from.

**Peripherals use hardware MODULES, not bare packages.**
`hardware.wooting.enable` installs `wooting-udev-rules` via
`services.udev.packages`, covering every Wooting VID/PID including the legacy
`03eb` ones — the config previously carried eight hand-written rules duplicating
exactly that, and they are gone. `hardware.logitech.wireless` with
`enableGraphical = logitechGui` wires the separate `logitech-udev-rules`
derivation into udev and adds Solaar; installing `pkgs.solaar` alone would need
root to reach the receiver. The Pico rules are hand-written `TAG+="uaccess"`
rules for `2e8a:0005` (normal mode, USB + tty) and `2e8a:0003` / `2e8a:000a`
(BOOTSEL bootloader mode).

### 12.15 `arctic.network` — `network/`

**MAC policy.** WiFi gets a fresh MAC per association; `"stable"` would still be
a persistent per-SSID identifier that every AP can log and correlate. Ethernet
stays `"permanent"`: the cable already identifies the location, and randomising
it breaks DHCP reservations, port security and some ISP provisioning for
nothing. NetworkManager also gets the `networkmanager-openvpn` plugin.

> On this host the WiFi setting is **inert**, because
> `security.kernel.disableRadios = true` blacklists `iwlwifi`. It is kept so the
> policy is recorded for other hosts (§14).

**DNS.** Quad9 (Swiss non-profit, blocks known-malicious domains, no logging),
strict DoT and strict DNSSEC. Four details, each load-bearing:

- `Domains = [ "~." ]` routes EVERY lookup through the configured servers.
  Without it, a DHCP-supplied resolver wins for any domain it claims and the ISP
  router quietly keeps answering despite everything else here.
- `FallbackDNS = [ ]` is deliberate: resolved ships compiled-in Cloudflare and
  Google fallbacks that it uses **in plaintext** when the configured servers
  fail — a silent escape hatch out of every guarantee above.
- `DNSSEC = "true"`, **not** `"allow-downgrade"`. Downgrade mode silently
  accepts unvalidated answers whenever the upstream appears not to support
  DNSSEC — which is exactly the state an on-path attacker induces, so it
  validates precisely when nobody is attacking you.
- Every server carries a `#hostname` SNI suffix (assertion I7). Strict DoT has
  nothing to validate the certificate against otherwise.

Provider tables (`quad9`, `mullvad`, `cloudflare`) live in a `let` binding in
the module; `mullvad` uses the `base.dns.mullvad.net` endpoint, which also
blocks ads and trackers — swap `base` for `dns` if a blocked domain ever breaks
something.

**The failure mode to know: captive portals.** Hotel/airport WiFi intercepts
plaintext `:53`; with strict DoT that interception simply fails rather than
redirecting. Set `overTls = false` temporarily to get through one.

LLMNR is off: it broadcasts this machine's hostname to every network you join,
is a well-known credential-relay vector on Windows-heavy LANs, and nothing here
uses it. mDNS stays on for LocalSend and network printers.

**Firewall.** nftables backend, `checkReversePath = "loose"` (strict breaks
WireGuard's fwmark policy routing and LAN discovery), `rejectPackets = false`
(DROP, so no ICMP unreachable goes back to a scanner), and refusal logging off
(on a desktop it is mostly LAN broadcast/mDNS/SSDP chatter, and a journal full
of noise is a journal nobody reads). The only ports open are TCP+UDP **53317**,
opened by `programs.localsend.enable`.

**The nftables backend is a one-way door.** It sets
`boot.blacklistedKernelModules = [ "ip_tables" ]`, which Docker requires (hence
assertion I5), and it makes `networking.firewall.extraCommands` a hard assertion
failure — the equivalents (`extraInputRules`, `extraForwardRules`) exist only in
this backend. Podman and libvirt both detect nftables and configure netavark and
their own backend accordingly; nothing to do by hand.

**Tor.** SOCKS5 on `127.0.0.1:9050` and nothing else. **This is not system-wide
anonymisation** — nothing is routed through it unless an application is
explicitly pointed at the SOCKS port (torsocks, proxychains). Tor Browser
bundles its own tor and does not use this. `TransPort` / `DNSPort` are
deliberately absent: they open listeners that only do something if nat REDIRECT
rules point traffic at them, and no such rules exist — two idle ports that
*look* like transparent proxying but aren't is worse than not having them.
`StrictNodes` is likewise omitted; without `ExitNodes`/`EntryNodes`/
`ExcludeNodes` it is documented as having no effect either way.

**Tools.** `capture` matters beyond the package: `programs.wireshark.enable`
creates the `wireshark` group and installs the setcap `dumpcap` wrapper. Without
it, the group membership in `extraGroups` is meaningless and capture only works
as root. `captureGui` must stay on for the Qt GUI —
`programs.wireshark.package` defaults to `wireshark-cli`, so leaving it off
silently downgrades a GUI install to terminal-only.

**There is no VPN module**, and `network/default.nix` carries a comment
explaining why. See §25.

### 12.16 `arctic.security` — `security/`

Full treatment in §20.

### 12.17 `arctic.virt` — `virt/`

Podman: rootless, `dockerSocket.enable` tied to `dockerCompat`,
`defaultNetwork.settings.dns_enabled = true` (containers resolve each other by
name on user-defined networks), weekly `autoPrune` with `--all`, and
`virtualisation.oci-containers.backend = "podman"`.

**Podman was chosen over Docker specifically to remove a root-equivalence.**
Membership in the `docker` group is root by design — the daemon runs as root and
will happily bind-mount `/` into a container for any group member, so a
compromise of the login user is a compromise of the machine. Rootless Podman has
no daemon and no privileged group: a container escape lands as your unprivileged
user. `dockerCompat` covers `docker run`/`build`/`compose`, Dockerfiles,
devcontainers and oci-containers; the one thing it cannot do is serve something
that genuinely requires a rootful daemon (a few kind / k8s-in-docker setups).

libvirt enables `virtualisation.libvirtd` and `programs.virt-manager`. **Note
the `libvirtd` group is effectively root-equivalent** — a member can define a VM
with arbitrary host device passthrough and disk access. That is an accepted
trade here, not an oversight.

### 12.18 `arctic.apps` — `apps/`

Flatpak apps on this host:

```
org.vinegarhq.Sober            Roblox. THE reason Flatpak exists in this config.
com.github.tchx84.Flatseal     per-app permission editor
io.github.flattool.Warehouse   flatpak data management
tv.plex.PlexDesktop
```

`vinegar` in nixpkgs is the Roblox **Studio** wrapper, not Sober. There is no
nixpkgs equivalent of Sober, which is the entire reason this input exists.

Module details: one remote (flathub), `uninstallUnused` tied to
`uninstallUnmanaged`, weekly auto-update, `update.onActivation = false` (on
would make every `nixos-rebuild switch` block on network I/O against Flathub and
fail the rebuild when Flathub is down), and a `restartOnFailure` policy with
exponential backoff (5 steps, 30 min max).

**Consequence of `uninstallUnmanaged = true`:** `flatpak install` from a
terminal is now temporary — the next rebuild reverts it, along with its
`~/.var/app` data. Add the app ID to `arctic.apps.flatpak.apps` instead. This
was audited on 2026-08-01: the installed set was exactly the four above, so
taking authority removed nothing.

### 12.19 `arctic.disk` — `disk/`

See §19.

---

## 13 — home-manager option reference

Set inside `home-manager.users.arctic.arctic = { … }` at the bottom of
`hosts/arctic/default.nix`.

### 13.1 `arctic.shell.fish` — `home/shell/fish.nix`

Aliases when `modernCliAliases` is on: `ls`/`ll`/`la`/`lt` → eza variants,
`cat` → `bat --style=plain`, `grep` → `rg`, `cd` → `z`.

Always: `sys-check`, `net-scan`, `net-quick`, `net-full`, `net-net`, `net-ls` →
`$HOME/scripts/*` — personal scripts kept out of `/etc` so root's PATH stays
clean. **These scripts are imperative state and are not in this repo** (§22).

`interactiveShellInit`: zoxide init, empty greeting, `C-l` rebind,
`PAGER=cat`, `$HOME/.npm-global/bin` added to PATH.

`home.sessionPath = [ "$HOME/scripts" "$HOME/.cargo/bin" ]`. This was previously
`environment.variables.PATH` at system level, which also put **user-writable
directories ahead of `/run/wrappers/bin` in root's PATH** — a genuine privilege
escalation vector, now fixed by scoping it to the user.

### 13.2 `arctic.shell.starship` / `arctic.shell.tmux`

starship: `username@hostname`, 3-segment truncated directory, git branch and
status, a `❄️` nix-shell indicator, `❯` prompt character, fish integration on.

tmux: `C-a` prefix, vi keys, mouse on, `tmux-256color`, 10k history, `|` and `-`
splits inheriting cwd, `prefix r` reloads the config.

### 13.3 `arctic.dev` — `home/dev/`

**git:** aliases `lg st co br undo`, `init.defaultBranch = "main"`,
`pull.rebase = true`, `push.autoSetupRemote = true`, `core.autocrlf = false`.
Written through the modern `programs.git.settings` schema (§27). An empty
`userEmail` makes `git commit` fail outright with "unable to auto-detect email
address", which is why the option has a real default.

**neovim:** `defaultEditor`, `vimAlias`, and — explicitly, rather than inherited
from `home.stateVersion` — **`withRuby = false`** and **`withPython3 = false`**.
Those pull full Ruby and Python interpreters purely for legacy `:ruby`/`:python`
plugin hosts that nothing here uses. Settings: relative numbers, 4-space
expandtab, system clipboard, smartcase, truecolor, undofile.

**ssh is a hardened CLIENT config** with `enableDefaultConfig = false` —
home-manager's implicit defaults are deprecated upstream, and for a client
config "what exactly is in effect" should never require reading someone else's
module. Everything is stated explicitly in `settings."*"`:

| Setting | Value | Why |
|---|---|---|
| `IdentitiesOnly` | `true` | Otherwise ssh walks the whole agent and leaks every public key you hold to every server you touch — a free fingerprint of your identity across unrelated hosts |
| `ForwardAgent` / `AddKeysToAgent` | `false` / `"no"` | Agent forwarding lets whoever controls the remote host use your keys for as long as you stay connected |
| `HashKnownHosts` | `true` | A stolen `known_hosts` should not enumerate everywhere you connect |
| `StrictHostKeyChecking` | `"ask"` | |
| `Ciphers` | `chacha20-poly1305`, `aes256-gcm` | AEAD only |
| `MACs` | `hmac-sha2-{512,256}-etm` | Encrypt-then-MAC only |
| `KexAlgorithms` | `curve25519-sha256{,@libssh.org}` | |
| `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` | ed25519 + rsa-sha2-{512,256} | Excludes `ssh-rsa` (SHA-1) |
| `ControlMaster` / `ControlPersist` | `"no"` / `"no"` | |
| `ServerAliveInterval` / `CountMax` | `60` / `3` | |
| `Compression` | `false` | |

This is a **client** config. This host runs no sshd (§22).

### 13.4 `arctic.terminal.kitty` — `home/terminal/kitty.nix`

Tokyo Night palette, beam cursor without blink, powerline slanted tabs at the
bottom, `repaint_delay 8` / `input_delay 1` / `sync_to_monitor yes`, harfbuzz
with JetBrainsMono ligatures (`+liga +calt`), `copy_on_select = clipboard`,
`shell = /run/current-system/sw/bin/fish`, `editor = nvim`, 10k scrollback, no
audio bell, `confirm_os_window_close = 0`.

Keybindings cover splits (`ctrl+shift+\` / `-`), hjkl split navigation, tabs,
font size, live opacity (`ctrl+shift+a>m` / `>l` / `>1` / `>d`), and scrollback.

The `0.90` opacity is why `arctic.plasma.kwin.effects.blur` is worth having —
blur is what makes a transparent terminal readable.

### 13.5 `arctic.home.packages` — `home/packages.nix`

Enables `programs.home-manager` and installs `jq`, `just`, `yt-dlp`. Kept small
on purpose — see the system-vs-home rule in §10.3.

### 13.6 `arctic.plasma` — `home/desktop/plasma.nix`

The largest module in the repo (983 lines). Full treatment in §18.

`extraSettings` on this host is two kdeglobals keys:
`kdeglobals.General.TerminalApplication = "kitty"` and
`kdeglobals.General.TerminalService = "kitty.desktop"` — these are what make
Dolphin's "Open Terminal Here" open kitty. Neither has a plasma-manager wrapper.

**Three settings inside this module bypass the typed wrappers** and go through
the same raw `configFile` path as `extraSettings`, because plasma-manager has no
wrapper for them:

| Key | Why raw |
|---|---|
| `kwinrc.Plugins.shakecursorEnabled` | shakeCursor lives in kwinrc's plugin list, not the effects submodule |
| `kdeglobals.KDE.AnimationDurationFactor` | no wrapper at all |
| `kdeglobals.KDE.DoubleClickInterval` | no wrapper at all |

The module also does two pieces of translation worth knowing: `mkFont` only
emits a font once **both** a family and a size exist (plasma-manager's font
submodule requires `family`), and `hotkeys` entries omit `name`/`key` when null
rather than passing nulls through, because upstream treats them as plain strings
with their own defaults.

---

## 14 — Cross-module coupling map

**Read this before claiming any change is isolated.** Most of the surprises in
this repository come from an option in one module changing the meaning of an
option in another. Several of these couplings fail *silently*.

### 14.1 Gating — option A must be on for option B to do anything

| Gate | Gates | Mechanism |
|---|---|---|
| `arctic.desktop.enable` | `desktop.plasma`, `desktop.audio`, `desktop.fonts`, `desktop.themes`, `desktop.wayland` | each module wraps its config in `mkIf (arctic.desktop.enable && cfg.enable)` |
| `arctic.gaming.enable` | `steam`, `gamescope`, `gamemode`, `launchers` | `mkDefault true` — so a host can still override any one of them |
| `arctic.gaming.launchers.enable` | `.minecraft`, `.wine` | `lib.optionals` inside the package list |
| `arctic.network.tools.enable` | `.capture`, `.captureGui`, `.scanning` | same |
| `arctic.security.tools.enable` | `.crypto`, `.proton`, `.opsec`, `.audit`, `.offensive` | same |
| `arctic.apps.<x>.enable` | every sub-toggle of that app group | same |
| `arctic.security.secrets.enable` | `.managePasswords` | `mkIf` inside the module's config |
| `arctic.disk.impermanence.enable` | `.root`, `.wipeHome` | `mkIf cfg.enable` |
| `arctic.disk.impermanence.wipeHome` | the entire `users.arctic` persist list | `mkIf cfg.wipeHome` — **and this guard is load-bearing** (§19.3) |

### 14.2 Amplification — option A changes what option B produces

| When this is on | This changes | Where |
|---|---|---|
| `arctic.gpu.nvidia.enable` | adds `__GL_GSYNC_ALLOWED`, `__GL_VRR_ALLOWED`, `LIBVA_DRIVER_NAME` to the session env | `desktop/wayland.nix` |
| `arctic.gpu.nvidia.enable` | adds the whole `gpu` block to gamemode's settings | `gaming/performance.nix` |
| `arctic.gpu.nvidia.enable` | adds `nvtopPackages.nvidia` (when `utilities.monitoring`) | `apps/utilities.nix` |
| `arctic.gpu.nvidia.vaapi` | adds `nvidia-vaapi-driver` to `hardware.graphics.extraPackages` | `desktop/gpu.nix` |
| `arctic.virt.libvirt.enable` | adds `iommu=pt` to `boot.kernelParams` | `security/kernel.nix` |
| `arctic.security.kernel.initOnFree` | adds `init_on_free=1` to `boot.kernelParams` | `security/kernel.nix` |
| `arctic.core.boot.kernelPackage` | selects which NVIDIA driver build exists (`boot.kernelPackages.nvidiaPackages.<branch>`) | `desktop/gpu.nix` |
| `arctic.network.firewall.backend = "nftables"` | blacklists `ip_tables`; podman's netavark and libvirt reconfigure themselves | NixOS upstream |
| `arctic.apps.flatpak.uninstallUnmanaged` | also sets `uninstallUnused` (prunes runtimes) | `apps/flatpak.nix` |
| `arctic.virt.podman.dockerCompat` | also enables `dockerSocket` | `virt/containers.nix` |
| `arctic.security.secureboot.enable` | `mkForce`s systemd-boot **off** | `security/secureboot.nix` |

### 14.3 Cross-module writes — a module setting another module's option

There is exactly one, and it is worth knowing about because it makes a value in
§11 look wrong until you find it:

```nix
# modules/nixos/security/secrets.nix
arctic.core.users.primary.hashedPasswordFile =
  lib.mkIf cfg.managePasswords config.sops.secrets."arctic-password".path;

users.users.root.hashedPasswordFile =
  lib.mkIf cfg.managePasswords config.sops.secrets."root-password".path;
```

So `arctic.core.users.primary.hashedPasswordFile` reads as `null` in
`core/users.nix` and as a `/run/secrets-for-users/...` path in the built system.
`root`'s password is set directly, bypassing the `arctic.core.users` API,
because that API only models the primary user.

### 14.4 Group creation — the silent-failure cluster

`users.users.arctic.extraGroups` names groups that **must be created by
something else**. NixOS silently drops unknown groups (I12), so every entry
below is really a dependency on another option being on:

| Group | Created by | Which is turned on by |
|---|---|---|
| `wheel` | always exists | — |
| `networkmanager` | `networking.networkmanager.enable` | `arctic.network.manager.enable` |
| `video` `render` `audio` `input` `dialout` `kvm` | always exist | — |
| `i2c` | `hardware.i2c.enable` | `arctic.core.hardware.i2c` |
| `tor` | `services.tor.enable` | `arctic.network.tor.enable` |
| `wireshark` | `programs.wireshark.enable` | `arctic.network.tools.capture` |
| `ydotool` | `programs.ydotool.enable` | `arctic.apps.utilities.automation` |
| `libvirtd` | `virtualisation.libvirtd.enable` | `arctic.virt.libvirt.enable` |

**Turning off `arctic.network.tools.capture` therefore silently removes the
`wireshark` group**, and the `extraGroups` entry becomes a no-op with no
warning anywhere. The same is true for `tor`, `ydotool`, `i2c` and `libvirtd`.

### 14.5 Name-matching couplings — strings that must agree across files

These are the ones that fail silently and cost the most time.

| This value | Must match | Or else |
|---|---|---|
| `arctic.plasma.theme.iconTheme` = `"Papirus"` | a directory installed by `desktop.themes.icons` | Plasma falls back to Breeze, no error |
| `arctic.plasma.theme.colorScheme` = `"SweetAmbarBlue"` | `pkgs/sweet-ambar-blue` → `share/color-schemes/SweetAmbarBlue.colors` | same |
| `arctic.plasma.theme.plasmaStyle` = `"Sweet-Ambar-Blue"` | `share/plasma/desktoptheme/Sweet-Ambar-Blue` | same |
| `arctic.plasma.theme.windowDecoration.theme` = `"__aurorae__svg__Sweet-ambar-blue"` | `share/aurorae/themes/Sweet-ambar-blue` (prefix + directory name) | same |
| `arctic.plasma.theme.splashScreen` = `"SimpleTuxSplash-Plasma6"` | `share/plasma/look-and-feel/SimpleTuxSplash-Plasma6` **and** the KPlugin `Id` in its `metadata.json` | same |
| `arctic.plasma.cursor.theme` = `"WhiteSur-cursors"` | `whitesur-cursors` → `share/icons/WhiteSur-cursors` | same |
| `arctic.plasma.fonts.monospace` / `arctic.terminal.kitty.fontFamily` | a font installed by `desktop.fonts` | fontconfig substitutes something else |
| `arctic.core.users.primary.shell` = `pkgs.fish` | `arctic.core.shell.fish = true` **and** `arctic.shell.fish.enable` | the interactive config never loads |
| `arctic.plasma.input.mice[].{name,vendorId,productId}` | what libinput reports — for a wireless mouse, the **receiver** | the settings block is written for a device that does not exist |
| `arctic.security.clamav.scanPaths` | real paths (hardcoded `/home/arctic/Downloads`) | the timer scans nothing |

Note the capitalisation inconsistency: `Sweet-Ambar-Blue` (Plasma style) vs
`Sweet-ambar-blue` (Aurorae decoration). **That is upstream's own
inconsistency**, taken from each theme's `metadata.desktop`. Do not "fix" it.

### 14.6 Inert-by-other-option

| Option | Made inert by | Kept anyway because |
|---|---|---|
| `arctic.network.manager.wifiMacAddress` | `security.kernel.disableRadios = true` blacklists `iwlwifi` | the policy is still recorded for other hosts |
| `arctic.plasma.*` | `arctic.desktop.plasma = false` would make `arctic.plasma.enable` default false | — |
| `hosts/arctic/disko.nix` | `arctic.disk.useDisko = false` (currently **true**, so it is live) | `nix flake check` still type-checks it, and `disko-install` still reads it |

### 14.7 Must-agree pairs

| A | B | Symptom if they disagree |
|---|---|---|
| `services.displayManager.sddm.autoNumlock` (system) | `arctic.plasma.input.keyboard.numlockOnStartup` (home) | you type your password with NumLock off and use the desktop with it on |
| `arctic.desktop.fonts.monospace` | `arctic.plasma.fonts.monospace`, `arctic.terminal.kitty.fontFamily` | mismatched terminal/desktop fonts |
| `systemd.coredump.enable = false` (kernel.nix) | `security.pam.loginLimits` core = 0 (sudo.nix) | one alone leaves a path for crash dumps containing decrypted secrets |

### 14.8 Shared config keys written by two modules

Both are list merges, so they compose without conflict — but know they exist:

| Key | Written by | Merged as |
|---|---|---|
| `security.pam.loginLimits` | `security/sudo.nix` (core = 0) and `gaming/performance.nix` (nofile) | list concatenation |
| `boot.blacklistedKernelModules` | `security/kernel.nix` (twice: `blacklistModules` and `disableRadios`) plus NixOS's own nftables handling | list concatenation |
| `services.udev.extraRules` | `core/hardware.nix` (android) and `gaming/peripherals.nix` (pico) | text concatenation |
| `environment.systemPackages` | nearly every module | list concatenation |

---

## 15 — The manifest decoded

`hosts/arctic/default.nix` in prose. Anything not listed here is at its module
default. The file imports only `./hardware.nix` and `./disko.nix`.

### 15.1 On

Desktop (Plasma 6 + X11 fallback session), NVIDIA (open module, stable branch,
VA-API), low-latency audio, **all five theme families**, gaming (Steam +
GE-Proton + gamescope + gamemode + Lutris/Heroic/Prism/Wine/Bottles), Wooting +
Pico + Logitech peripherals, NetworkManager with WiFi MAC randomisation, Quad9
DoT+DNSSEC, an nftables firewall with LocalSend, the Tor daemon, full network
tooling with capture and scanning, kernel hardening (sysctl + params + module
blacklist + **radios blacklisted**), sudo hardening, the GPG agent, **sops
secrets with sops-managed passwords**, auditd, ClamAV, all five security tool
bundles, rootless Podman with Docker compatibility, libvirt, declarative Flatpak
with **`uninstallUnmanaged`**, browsers, dev apps (+ editors + .NET), media
(+ creation + server + torrent), office, utilities (+ USB tooling + automation),
reverse engineering, postgresql, Android udev rules, and **disko-generated
filesystems**.

### 15.2 Deliberately off

| Switch | Why | Where explained |
|---|---|---|
| `security.apparmor.enable` | enabled-with-no-policies confines nothing while looking like coverage | §20.6 |
| `security.kernel.initOnFree` | the one hardening param that shows in frametime graphs | §20.2 |
| `security.secureboot.enable` | **staged** — needs a one-time firmware trip (README phase 6) | §20.8 |
| `disk.impermanence.enable` | **staged** — turn on after the reinstall, once the path list is trusted | §19.3 |
| `disk.impermanence.wipeHome` | `/home` is its own subvolume; wiping `/` alone already proves completeness | §19.3 |
| `desktop.speech` | ~676 MB of mbrola diphones nothing here uses | §12.8 |
| `gaming.steam.openFirewall` | Remote Play / LAN transfer ports are not needed | §12.14 |
| `plasma.overrideConfig` | not yet — capture the live config with `rc2nix` first | §18.9 |

### 15.3 Host-specific facts, with their reasons

- **`core.boot.tmpfsSize = "50%"`** — 50% of RAM, not a fixed 32G. The nix
  daemon builds in `/tmp`; a fixed size at ~100% of RAM lets one large Electron
  or Chromium build take the whole machine down with it.
- **`core.nix.permittedInsecurePackages = [ "ventoy-qt5-1.1.12" ]`** — required
  by `ventoy-full-qt`, which ships prebuilt binary blobs (nixpkgs#404663).
  Accepted knowingly: it is only ever run manually to write a bootable USB.
  (`olm-3.2.16` used to be listed and was verified absent from the closure —
  nothing needed it.)
- **`network.extraHosts`** blackholes three BattlEye endpoints
  (`paradise-s1`, `test-s1`, `paradiseenhanced-s1`). GTA V Online refuses to
  connect through them on Linux and this is the standard workaround.
- **`security.kernel.disableRadios = true`** — this box has been on Ethernet
  since it was built. This is what Plasma's airplane mode only *appears* to do
  (§20.2).
- **`security.kernel.sysrq = 16`** (sync only), not 0 (I11).
- **`plasma.theme` sets no `lookAndFeel`** — this desktop runs an assembled mix,
  not one Global Theme (§18.3).
- **`plasma.wallpaper`** is a two-element list indexed by Plasma **screen
  number**, verified against `kscreen-doctor -o` (§18.6).
- **`plasma.input.mice`** names the Logitech **receiver** `046d:c547`, with
  `sensitivity = 0.0` and `accelerationProfile = "none"` (§18.7).
- **`plasma.screenLocker.autoLock = false`** — this machine is either in use or
  off, and it is the LUKS passphrase that actually protects it at rest; an idle
  timer adds interruption without adding much.
- **`terminal.kitty.fontSize = lib.mkDefault 19`** — `mkDefault` so a future
  per-host override wins without a fight.

### 15.4 The staging ledger

Five switches are "staged": fully implemented, documented, and deliberately in
one state until a specific event. Two of the five have since been turned on.

| Switch | State | Turn on when |
|---|---|---|
| `security.secrets.managePasswords` | **ON** (as of `514bdfa`) | done — real hashes are in `secrets/arctic.yaml` |
| `disk.useDisko` | **ON** (as of `015b3d7`) | done — the machine now runs the disko layout |
| `apps.flatpak.uninstallUnmanaged` | **ON** (audited 2026-08-01) | done — nothing hand-installed was still needed |
| `security.secureboot.enable` | off | you are ready for the firmware trip (README phase 6) |
| `disk.impermanence.enable` | off | after the reinstall, once you trust the path list |

> `README.md`'s "Current staging state" table still lists the first two as off.
> That is stale — see §28.

---

## 16 — Package inventory

What is installed and which module puts it there. Useful when working out why
something is in the closure.

### 16.1 System packages by module

| Module | Packages |
|---|---|
| `core/packages.nix` | `git file tree` · `bat fd ripgrep eza fzf zoxide tmux` · `fastfetch lm_sensors pciutils usbutils libmtp` · *devEssentials:* `gcc gnumake nodejs_22 python3 python3Packages.pip` · *database:* `postgresql_16` |
| `desktop/plasma.nix` | `kdePackages.spectacle` |
| `desktop/audio.nix` | `pavucontrol pamixer` |
| `desktop/fonts.nix` | `nerd-fonts.jetbrains-mono nerd-fonts.fira-code noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji liberation_ttf` |
| `desktop/themes.nix` | `papirus-icon-theme candy-icons` · `whitesur-cursors` · `sweet-nova` · `whitesur-kde whitesur-icon-theme` · **`sweet-ambar-blue simpletux-splash`** (local) |
| `desktop/gpu.nix` | `nvidia-vaapi-driver` (via `hardware.graphics.extraPackages`) |
| `gaming/launchers.nix` | `lutris heroic cartridges mangohud` · `vulkan-loader vulkan-tools dxvk` · *minecraft:* `prismlauncher jdk21 jdk17` · *wine:* `wine wine-wayland winetricks bottles` |
| `network/base.nix` | `networkmanager-openvpn` (as a NetworkManager plugin) |
| `network/tools.nix` | `curl dig dog mtr iproute2 iperf3 cli-tips` · `nethogs iftop` · `wireguard-tools proxychains-ng httpie` · *capture:* `tcpdump tshark` · *scanning:* `nmap zenmap netcat-openbsd dnsx` |
| `security/tools.nix` | *crypto:* `age gnupg pinentry-qt sops keepassxc` · *proton:* `proton-vpn protonmail-desktop proton-pass proton-authenticator` · *opsec:* `exiftool mat2` · *audit:* `lynis aide` · *offensive:* `burpsuite` |
| `security/clamav.nix` | `clamav` (+ the `scan` shell alias) |
| `apps/browsers.nix` | `brave tor-browser` |
| `apps/dev.nix` | `kitty claude-code devtoolbox` · *editors:* `vscodium jetbrains.pycharm` · *dotnet:* `dotnet-sdk_10` |
| `apps/media.nix` | `vlc` · *creation:* `obs-studio gimp` · *server:* `navidrome jellyfin-desktop` · *torrent:* `qbittorrent` |
| `apps/office.nix` | `libreoffice obsidian` |
| `apps/utilities.nix` | *monitoring:* `btop iotop hardinfo2` (+ `nvtopPackages.nvidia` when NVIDIA) · *archives:* `unzip p7zip rsync` · *fileManagers:* `yazi superfile` · *chat:* `equibop` · *usbTooling:* `ventoy-full-qt` · *automation:* `crossmacro` |
| `apps/reverse-engineering.nix` | `ghidra imhex` |

### 16.2 Packages that come from a `programs.*` / `hardware.*` module

**These are the ones people mistakenly add as bare packages, breaking the
setup.** The module does something the package alone cannot.

| Module option | Why the module, not the package |
|---|---|
| `programs.wireshark` | creates the `wireshark` group **and** installs the setcap `dumpcap` wrapper |
| `programs.ydotool` | runs the `ydotoold` daemon **and** creates the `ydotool` group |
| `programs.localsend` | opens TCP+UDP 53317 |
| `programs.steam.protontricks` | wrapped with `extraCompatPaths` so it can see GE-Proton prefixes |
| `programs.steam.extraCompatPackages` | registers GE-Proton as a Steam compatibility tool declaratively |
| `hardware.wooting` | installs `wooting-udev-rules` via `services.udev.packages` |
| `hardware.logitech.wireless` | installs `logitech-udev-rules`; `enableGraphical` is what adds Solaar |
| `programs.gamescope` | `capSysNice` — most of its frame-pacing advantage |
| `programs.appimage` | binfmt registration, so AppImages are executable |
| `programs.nix-ld` | the dynamic loader shim for foreign ELF binaries |
| `programs.virt-manager` | polkit rules and the libvirt session wiring |
| `programs.gnupg.agent` | the agent socket, SSH support, pinentry selection |
| `programs.neovim` / `programs.fish` | `$EDITOR` wiring and login-shell validity |

### 16.3 Home packages

`jq`, `just`, `yt-dlp`, plus everything pulled in by
`programs.{fish,starship,tmux,git,neovim,ssh,kitty,home-manager,plasma}`.

### 16.4 Closure notes

| Item | Size / note |
|---|---|
| `mbrola-voices` | ~676 MB, **excluded** via `arctic.desktop.speech = false` — the single largest saving here |
| `arctic.desktop.xserver = true` | keeps the X server in the closure for an X11 fallback session; turning it off shrinks the closure and costs the fallback |
| `desktop.themes.sweet` / `.whiteSur` | on for alternatives and Kvantum styles, not because anything selects them |
| `candy-icons` | an alternative; only `Papirus` is selected |
| `jdk21` + `jdk17` | both, because Minecraft 1.17–1.20.4 needs 17 and 1.20.5+ needs 21 |

Check any of this with `nix why-depends` and `nix path-info -rSh` (§04.6).

---

## 17 — Runtime surface: units, ports, paths

What actually runs, listens, and gets written on the live machine. This is the
section to consult when reasoning about behaviour rather than configuration.

### 17.1 Long-running services

| Unit | From | Note |
|---|---|---|
| `systemd-timesyncd` | `core/locale.nix` | NTP |
| `NetworkManager` | `network/base.nix` | + `networkmanager-openvpn` plugin |
| `systemd-resolved` | `network/dns.nix` | stub listener on `127.0.0.53:53` |
| `nftables` + `firewall` | `network/firewall.nix` | default DROP input policy |
| `tor` | `network/tor.nix` | SOCKS5 `127.0.0.1:9050` only |
| `sddm` | `desktop/plasma.nix` | Wayland greeter, `autoNumlock` |
| `pipewire`, `pipewire-pulse`, `wireplumber` | `desktop/audio.nix` | user units |
| `rtkit-daemon` | `desktop/audio.nix` | realtime scheduling privileges |
| `auditd` | `security/audit.nix` | writes `/var/log/audit/audit.log` |
| `clamav-freshclam` | `security/clamav.nix` | 12 signature checks/day |
| `podman` socket | `virt/containers.nix` | rootless; docker-compatible socket |
| `libvirtd` | `virt/libvirt.nix` | |
| `ydotoold` | `apps/utilities.nix` (`automation`) | creates the `ydotool` group |
| `gamemoded` | `gaming/performance.nix` | |
| `gpg-agent` | `security/gpg.nix` | user unit, SSH support on |
| `upower`, `power-profiles-daemon`, `udisks2`, `accounts-daemon` | plasma6 | pulled in by the desktop |

**Deliberately not running:** `sshd`, `clamd` (the resident ClamAV daemon —
§20.5), `bluetoothd`, `dockerd`, `fail2ban`, `usbguard`, `speech-dispatcher`,
`orca`.

### 17.2 Timers

| Timer | Schedule | From |
|---|---|---|
| `nix-gc` | weekly, `--delete-older-than 7d` | `core/nix.nix` |
| `clamav-scheduled-scan` | `Sun 03:00`, `Persistent`, `RandomizedDelaySec=30m` | `security/clamav.nix` |
| `clamav-freshclam` | 12× daily | `security/clamav.nix` |
| flatpak auto-update | weekly | `apps/flatpak.nix` |
| `podman-prune` | weekly, `--all` | `virt/containers.nix` |

`nix.settings.auto-optimise-store = true` is a **daemon setting**, not a timer —
deduplication happens as paths are added.

### 17.3 Listening sockets

| Address | What | Reachable from |
|---|---|---|
| `127.0.0.53:53` | systemd-resolved stub | localhost |
| `127.0.0.1:9050` | Tor SOCKS5 | localhost |
| TCP+UDP `53317` | LocalSend | **LAN** — the only port the firewall opens, verified: `allowedTCPPorts == allowedUDPPorts == [ 53317 ]` |
| `5353/udp` | resolved MulticastDNS | resolved binds it, but the firewall does **not** open it — outbound mDNS queries and LocalSend's own UDP 53317 discovery work; unsolicited inbound mDNS is dropped |
| `/run/podman/podman.sock` | Docker-compatible unix socket | local, `dockerCompat` |
| `/run/libvirt/*` | libvirt sockets | local, `libvirtd` group |

**Nothing else listens.** There is no sshd; there is nothing to jail, which is
why fail2ban is absent (§25).

### 17.4 Paths this configuration creates or owns

| Path | Owner | Note |
|---|---|---|
| `/run/current-system` | nix | the active generation |
| `/nix/var/nix/profiles/system` | nix | generation history = your rollback window |
| `/run/secrets/` | sops-nix | decrypted secrets, tmpfs |
| `/run/secrets-for-users/` | sops-nix | `neededForUsers` secrets — decrypted **before** user creation |
| `/var/lib/sops-nix/key.txt` | you, 0600 root | **the age private key. NOT in git. Root of trust.** |
| `/var/lib/sbctl/` | sbctl/lanzaboote | Secure Boot platform keys. **NOT in git, not recoverable** |
| `/var/log/audit/` | auditd | capped at 250 MB (50 MB × 5, ROTATE) |
| `/var/log/sudo.log` | sudo | event log only, never terminal transcripts |
| `/etc/modprobe.d/nixos.conf` | NixOS | where `blacklistedKernelModules` lands |
| `/etc/hosts` | NixOS | includes the three BattlEye blackholes |
| `/var/lib/flatpak/` | flatpak | system installs; tens of GB |
| `/var/lib/containers/`, `/var/lib/libvirt/` | podman, libvirt | images, volumes, VM disks |
| `~/.config/*rc` | plasma-manager **and** System Settings | both write here; §18 |
| `~/.local/share/plasma-manager/scripts/` | plasma-manager | the one-shot theme-apply script and its hash guard |
| `*.hm-bak` | home-manager | what `backupFileExtension` renames a conflicting dotfile to |
| `/tmp` | tmpfs, 50% of RAM | where the nix daemon builds |
| `/persist` | disko subvolume | mounted today; only *used* once impermanence is on |
| `/.snapshots` | disko subvolume | declared, no snapshot tooling configured yet |

### 17.5 Shell aliases in effect

| Alias | Expands to | Scope | From |
|---|---|---|---|
| `manage` | `bash ~/nixos-config/nix-manage.sh` | **system** (all users incl. root) | `core/shell.nix` |
| `cls` | `clear` | **system** | `core/shell.nix` |
| `scan` | `clamscan --recursive --infected --stdout` | **system** | `security/clamav.nix` |
| `ls` `ll` `la` `lt` | eza variants | user only | `home/shell/fish.nix` |
| `cat` | `bat --style=plain` | user only | `home/shell/fish.nix` |
| `grep` | `rg` | user only | `home/shell/fish.nix` |
| `cd` | `z` (zoxide) | user only | `home/shell/fish.nix` |
| `sys-check` `net-scan` `net-quick` `net-full` `net-net` `net-ls` | `$HOME/scripts/*` | user only | `home/shell/fish.nix` |

The split is deliberate: only aliases that make sense for **every** user
including root live at system level (§12.5).

---

## 18 — Plasma and theming

The single most confusing area of a declarative KDE setup, so it gets its own
section.

### 18.1 How plasma-manager works

Plasma keeps its state in `~/.config/*rc` INI files that System Settings
rewrites live. plasma-manager (wired in by `lib/mkHost.nix` as a
`sharedModules` entry) writes those same keys from Nix during home-manager
activation. **Both systems write to the same place; the only question is who
wins.**

**The contract in this repo: `null` means "not managed."** Every
`arctic.plasma.*` option defaults to null and a null is never emitted. So
enabling the module changes NOTHING on its own — it takes ownership of exactly
the keys the manifest names, and anything you set by hand in System Settings and
never declare keeps working. That is what makes it safe to adopt gradually, and
it stops being true only if you set `overrideConfig` (§18.9).

The current Plasma block was **captured from the live desktop**, so applying it
is a no-op: it takes ownership of settings that were already true rather than
changing them.

### 18.2 Themes need TWO halves

The mistake that costs the most time here:

| Half | File | Level | Does |
|---|---|---|---|
| **Assets** | `modules/nixos/desktop/themes.nix` | system | installs the theme FILES |
| **Selection** | `arctic.plasma.theme.*` in the manifest | user | picks which one is ACTIVE |

**Naming a theme whose package is not installed does not error (I13).** Plasma
silently falls back to Breeze. If a theme "did not apply", check that half
first:

```bash
ls /run/current-system/sw/share/{icons,color-schemes}
ls /run/current-system/sw/share/aurorae/themes
ls /run/current-system/sw/share/plasma/{desktoptheme,look-and-feel}
```

KDE finds these under `/run/current-system/sw/share/…`, exactly where it finds
Breeze. **Themes installed by hand into `~/.local/share` or `~/.icons` (via
KDE's "Get New Themes") are invisible to this repo and are DELETED by a
reinstall.**

### 18.3 The four theme options that sound identical

| Option | Controls | Example |
|---|---|---|
| `theme.lookAndFeel` | **Global Theme.** The umbrella preset — sets all of the below at once. Applied FIRST, so the others override it | `org.kde.breezedark.desktop` |
| `theme.colorScheme` | the colour palette only | `BreezeDark` |
| `theme.plasmaStyle` | how the **panel, widgets and popups** are drawn | `default` |
| `theme.widgetStyle` | how buttons and scrollbars are drawn **inside app windows** | `Union` (Plasma 6.5+ default), `Breeze`, `Oxygen`, `Fusion` |

`theme.windowDecoration` (the titlebar) is separate again, and plasma-manager
**asserts** that `library` and `theme` are set together — half a decoration is
an eval error, not a broken desktop.

**Do not set `windowDecoration` or `splashScreen` alongside `lookAndFeel`.** The
build warns, and the warning is right: the Global Theme is applied first and
carries its own decoration and splash, so the two race.

**This machine sets no `lookAndFeel` at all, deliberately.** It does not run one
Global Theme — it runs a Sweet Ambar Blue mix assembled part by part. Declaring
a Global Theme would re-apply on top and undo the parts below, which is exactly
what kept happening when this was done by hand.

`widgetStyle` is also unset: kdeglobals currently has no such key, so Plasma's
built-in default is in force. Both Sweet and WhiteSur ship Kvantum styles if you
want to change that — turn on the family in `desktop/themes.nix` and name it.

### 18.4 The theme audit — what runs, and whether a reinstall brings it back

| KDE category | Selected | Backed by | Source |
|---|---|---|---|
| Icons | `Papirus` | `papirus-icon-theme` | nixpkgs |
| Pointers | `WhiteSur-cursors` | `whitesur-cursors` | nixpkgs |
| System Sounds | `freedesktop` | ships with Plasma | nixpkgs |
| Colors | `SweetAmbarBlue` | `sweet-ambar-blue` | **`pkgs/`** |
| Plasma Style | `Sweet-Ambar-Blue` | `sweet-ambar-blue` | **`pkgs/`** |
| Window Decorations | `Sweet-ambar-blue` (Aurorae) | `sweet-ambar-blue` | **`pkgs/`** |
| Splash Screen | `SimpleTuxSplash-Plasma6` | `simpletux-splash` | **`pkgs/`** |
| Wallpapers | per-screen | `assets/wallpapers/` | this repo |
| Application Style | *(unset → Plasma default)* | Kvantum styles available | — |

**Every category this desktop selects is reproducible.**

**Why four are vendored.** nixpkgs has no Ambar Blue. `sweet-nova` packages only
the base Sweet set — `Sweet-Dark` / `Sweet-Dark-transparent` decorations,
`Sweet.colors`, `Sweet-cursors`, the Sweet Kvantum styles — and no Plasma
desktoptheme at all. `sweet` and `ant-theme` were **removed from nixpkgs**
outright; both depended on `gtk-engine-murrine`, which went with GTK 2.

A KDE theme is just a file tree, so each vendored package is a
`stdenvNoCC.mkDerivation` with `dontUnpack = true` that copies directories into
`$out/share/…`:

```
pkgs/sweet-ambar-blue/default.nix
  share/plasma/desktoptheme/Sweet-Ambar-Blue   <- theme.plasmaStyle
  share/aurorae/themes/Sweet-ambar-blue        <- theme.windowDecoration
                                                  ("__aurorae__svg__" + this)
  share/color-schemes/SweetAmbarBlue.colors    <- theme.colorScheme

pkgs/simpletux-splash/default.nix
  share/plasma/look-and-feel/SimpleTuxSplash-Plasma6   <- theme.splashScreen
```

**The install paths are load-bearing** and must match the strings in
`arctic.plasma.theme.*` character for character (§14.5).

A splash is a KPackage of structure `Plasma/LookAndFeel/Splash`, so it installs
under `look-and-feel` even though it is not a full Global Theme. The directory
name must equal the KPlugin `Id` in `metadata.json`, which is also what
`ksplashrc` stores. `Splash.qmlc` — a compiled QML cache — is deliberately
**not** vendored: it is a build artifact tied to one Qt version, Plasma
regenerates it at runtime, and a stale one is worse than none.

Still installed by hand and deliberately **not** declared, because nothing
selects them: `Ant-Dark` (36 MB of icons), the `Sweet-Mars` variants,
`Sweet-cursors`, and the `AndromedaLauncher` / `KdeControlStation` plasmoids. If
you ever select one, package it the same way first.

### 18.5 Why your theme keeps resetting

Theme selections (Global Theme, colours, Plasma style, cursors, icons) are not
rewritten on every activation. They are applied by a one-shot script:

```
~/.local/share/plasma-manager/scripts/1_script_apply_themes.sh
```

guarded by a sha256 of itself stored in `../last_run_script_apply_themes`. It
re-runs only when its own content changes.

**The trap:** that script embeds a **nix store path** (`plasma-changeicons`). So
any nixpkgs update changes the hash, the script re-runs, and it re-applies
whatever the config declares — silently overwriting themes you set by hand in
System Settings. That is not a bug; it is the config asserting itself. The fix
is to declare what you actually want rather than setting it in the GUI.

### 18.6 Wallpapers, per screen

`theme.wallpaper` takes a Nix **path**, which under flakes must be **inside the
repo**. An absolute path like `/home/arctic/Documents/wallpapers/x.jpg` is
rejected by pure evaluation — and would not survive a reinstall anyway, which is
the entire point. The images live in `assets/wallpapers/` and are copied into
the store.

A list assigns **per screen, indexed by Plasma's screen number** — element 0 to
screen 0, and so on. This is applied through Plasma's own scripting API
(`desktops()`, indexed by `desktop.screen`), **not** by editing containments in
`plasma-org.kde.plasma.desktop-appletsrc`. That matters: containment numbers are
imperative state that a fresh install renumbers, whereas screen numbers are
assigned by Plasma at runtime, so this survives the reinstall.

**Screen number is not the connector name.** Plasma numbers by display priority;
the primary is 0. Verified on this machine with `kscreen-doctor -o`:

```
screen 0 = DP-3, priority 1, 2560x1440@240, rotation normal
           -> the main monitor.  basement.jpg

screen 1 = DP-4, priority 2, 2560x1440@165, rotation 8 (270°),
           geometry 0,0 1440x2560 -> the vertical panel on the LEFT
           -> blackhole-abyss-wallpaper.jpg (3838x7890, natively portrait)
```

If the wallpapers ever swap monitors, the priorities changed — re-run
`kscreen-doctor -o` and reorder the list rather than editing anything else. A
list SHORTER than the screen count leaves the extra screens alone, so a
two-element list stays safe if you later unplug a monitor.

`assets/wallpapers/nixos-wallpaper-1.png` is present but **unreferenced**.

### 18.7 Mouse speed, specifically

Two different things, constantly confused:

- **`sensitivity`** (−1 … 1) — the "Pointer speed" slider, written as
  `PointerAcceleration`. A scale **factor**. 0 is the middle of the slider.
- **`accelerationProfile`** — the **curve**. `"none"` is flat: pointer distance
  is always the same multiple of mouse distance regardless of how fast you move.
  This is what "no mouse acceleration" / "raw input" means, and it is what keeps
  aim consistent in games. `"default"` is adaptive: moving faster travels
  disproportionately further.

This machine: `sensitivity = 0.0`, `accelerationProfile = "none"`.

The device is keyed on vendor + product + name, so settings follow the mouse
rather than the USB port. **For a wireless mouse the name libinput reports is
the RECEIVER, not the model on the box.** Read the true values off the running
system:

```bash
grep '^\[Libinput' ~/.config/kcminputrc
# [Libinput][1133][50503][Logitech USB Receiver]
#            ^vendor ^product  — DECIMAL here, but the option wants HEX
#            1133 = 046d       50503 = c547

# or, from the kernel's own view (which prints hex):
grep -B1 -A5 -i mouse /proc/bus/input/devices
```

Confirm this after any dongle change.

### 18.8 Capturing what you already have

`rc2nix` reads your live Plasma config and prints it as Nix. This is how you
migrate settings you tuned by hand instead of trying to remember them:

```bash
nix run github:nix-community/plasma-manager#rc2nix > /tmp/current-plasma.nix
```

Take what you want into `arctic.plasma.*` — typed options where they exist,
`extraSettings` where they do not — and discard the noise. It dumps a lot of
window geometry and per-app state you do not want declared.

### 18.9 The two settings that will delete things

**`overrideConfig = true`** makes this config the sole authority: on every
generation plasma-manager DELETES the KDE config files in its `resetFiles` list
(kdeglobals, kwinrc, kcminputrc, dolphinrc, katerc, the panel layout, …) and
rebuilds them from Nix alone. Anything you changed in the GUI and did not
declare is gone at next login. **It is the honest end state — get there by
capturing first (§18.8), not by flipping it and finding out what you forgot.**

**A non-empty `panels` list is destructive on its own**, regardless of
`overrideConfig` (I14): applying a layout requires deleting
`plasma-org.kde.plasma.desktop-appletsrc`, which takes your existing panels,
their widgets and every widget's settings with it. Empty (the default) leaves
panels completely alone. **Declare panels only when you are ready to declare all
of them.**

### 18.10 Applying changes

Most settings need a **log out and back in**. Plasma caches config in running
processes; rewriting the file underneath them does not notify them. Some take
effect after `systemctl --user restart plasma-plasmashell`, but the reliable
answer is a fresh session.

### 18.11 Two NumLock settings that must agree

`services.displayManager.sddm.autoNumlock` (system, `desktop/plasma.nix`) is the
**greeter's**; `arctic.plasma.input.keyboard.numlockOnStartup` (home) is the
**session's**. Set both, or you type your password with NumLock off and use the
desktop with it on.

---

## 19 — Disk, disko, impermanence, reinstall

### 19.1 The layout (`hosts/arctic/disko.nix`)

```
/dev/disk/by-id/<PLACEHOLDER>          GPT
├─ ESP    1G   vfat  /boot    umask=0077,fmask=0077,dmask=0077
└─ luks   100% LUKS2 "cryptroot"  allowDiscards, x-initrd.attach
   └─ btrfs  -f -L nixos
      ├─ @root      /            compress=zstd:3,noatime
      ├─ @home      /home        compress=zstd:3,noatime
      ├─ @nix       /nix         compress=zstd:3,noatime
      ├─ @persist   /persist     compress=zstd:3,noatime
      ├─ @snapshots /.snapshots  compress=zstd:3,noatime
      └─ @swap      /.swapvol    noatime      swapfile 34G
```

Why each choice:

| Choice | Reason |
|---|---|
| by-id device, supplied at install | survives a wipe, and cannot be reordered the way `/dev/nvme0n1` can when a second drive is added |
| 1 G ESP | room for several signed generations plus Secure Boot keys |
| `umask=0077` on the ESP | the ESP holds **unencrypted** kernels and initrds; this keeps them unreadable by anyone but root once the system is up |
| separate subvolumes | `@root` can be wiped for impermanence without touching `@home` |
| `zstd:3` | near-free on a 12600K, and less write wear on the SSD |
| swapfile **inside** LUKS | paged-out secrets are never on disk in the clear. 34 G leaves room for hibernation later |
| no compression on `@swap` | btrfs will not allow it, and it would defeat the point |
| `allowDiscards` on LUKS | it is an SSD; accepts the usual metadata leak |
| `x-initrd.attach` | the volume is attached in the initrd, before switch-root |

**The device is a PLACEHOLDER on purpose** (`/dev/disk/by-id/SET-ME-AT-INSTALL-TIME`,
invariant I17). This repo is public and a disk by-id path contains the drive's
serial number — a unique hardware identifier tied to a purchase and warranty
record. Pass the real device at install time, which `disko-install` accepts and
which **overrides** this value:

```bash
ls -l /dev/disk/by-id/ | grep -v part
disko-install ... --disk main /dev/disk/by-id/nvme-Samsung_SSD_...
```

That is strictly better than hardcoding: the one destructive operation in this
whole config now requires naming the target explicitly, rather than trusting a
string committed months earlier. If you ever run disko without the flag, it
fails loudly instead of formatting whatever the placeholder happens to name.

### 19.2 `arctic.disk.useDisko` — the reinstall flip

The mechanism is disko's own `enableConfig`, which wraps its generated
`fileSystems` / `boot.initrd.luks` / `swapDevices` in `mkIf`.

- `false` — the layout is still declared, so `nix flake check` type-checks it
  and `disko-install` can read it, but **nothing is generated**. Verified: with
  this false the built system was byte-identical to not having disko at all.
- `true` — disko owns the filesystems.

**Currently `true`.** The pre-disko `filesystems.nix` has been deleted from the
repo (commit `5d6245c`). Do not `nixos-rebuild switch` with this true on a
machine whose disk does not match the layout — the running system would point at
partitions that do not exist.

`diskoConfigurations.arctic` in `flake.nix` exposes the **same source file** at
the top level so the installer can read the layout without evaluating the whole
host — which matters because the host does not evaluate cleanly from an ISO that
has none of its hardware.

### 19.3 Impermanence — staged off

When enabled, `@root` is rolled back to a blank btrfs snapshot on every boot, so
anything not declared in this config or listed in the persist list simply
vanishes. **That is the strongest possible proof the config is complete: config
drift cannot accumulate because there is nowhere for it to accumulate.**

`fileSystems."/persist".neededForBoot = true` is set so `/persist` is mounted
before anything tries to bind-mount out of it.

**Persisted directories** (`environment.persistence."/persist"`,
`hideMounts = true`):

| Group | Paths | Why |
|---|---|---|
| Identity & boot | `/var/lib/nixos` `/var/lib/sbctl` `/var/lib/sops-nix` `/var/lib/systemd` `/var/lib/private` `/var/lib/machines` | uid/gid allocations, Secure Boot keys, the age key, timer stamps and the random seed. Losing these breaks the machine, not just an app |
| Network | `/etc/NetworkManager/system-connections` `/var/lib/NetworkManager` `/var/lib/bluetooth` `/var/lib/nftables` | without the first, every WiFi PSK is gone on each boot |
| Service state | `/var/lib/flatpak` `/var/lib/containers` `/var/lib/libvirt` `/var/lib/clamav` `/var/lib/tor` `/var/lib/fwupd` `/var/lib/upower` `/var/lib/power-profiles-daemon` `/var/lib/udisks2` `/var/lib/AccountsService` `/var/lib/sddm` | flatpak alone is tens of GB |
| Logs | `/var/log` | **an audit log that resets on every boot is not an audit log** |
| Files | `/etc/machine-id` | a new one each boot orphans all prior journald logs |

**`wipeHome` stays false** even when impermanence is turned on. `/home` is its
own subvolume, so wiping `/` alone already gives the reproducibility guarantee
for system state (`/etc`, `/var`, `/srv`). On a box with a 119 GB Steam library
and a decade of app state, the failure mode of `wipeHome` is losing something
you did not know you had, and the marginal security gain over an encrypted disk
is small.

The `users.arctic` persist list (games, `.var/app`, credentials, `.config`,
toolchains, documents) is guarded by `lib.mkIf cfg.wipeHome` — **and the guard
is load-bearing.** If `/home` is not being wiped, those bind mounts would shadow
the real `~` directories with empty ones from `/persist`, which is actively
destructive.

### 19.4 The reinstall, in one paragraph

Phases live in `README.md` and `INSTALL-CARD.txt`. The shape:

1. **Phase 0** (on the running machine) — real password hashes into
   `secrets/arctic.yaml`, the age key at `/var/lib/sops-nix/key.txt`, verify
   `/etc/shadow`, back up the age key **off** the machine, back up what the repo
   cannot rebuild (§22), confirm the disk by-id.
2. **Phase 1** — confirm `arctic.disk.useDisko = true`, commit, push. **Do not
   `nixos-rebuild switch` after this.**
3. **Phase 2** — firmware: Secure Boot disabled (or Setup Mode), CSM off, boot
   the minimal ISO.
4. **Phase 3** — `disko-install --flake github:<you>/nixos-config#arctic
   --disk main <real device> --extra-files /tmp/keys/key.txt
   /var/lib/sops-nix/key.txt --write-efi-boot-entries`.
5. **Phase 4** — **verify `/mnt/etc/shadow` BEFORE rebooting.**
6. **Phase 5** — first boot, Secure Boot still off.
7. **Phase 6** — enable `arctic.security.secureboot.enable`, rebuild, reboot
   into firmware, enroll keys, back up `/var/lib/sbctl`.
8. **Phase 7** — restore the handful of things this config deliberately does not
   reproduce (§22).

**Phase 4 exists because `nixos-enter` ends its activation call with `|| true`,
so activation failures are swallowed.** Check explicitly:

```bash
grep '^arctic:' /mnt/etc/shadow
#   arctic:$y$j9T$...   GOOD
#   arctic:!            BAD — sops did not decrypt. Fix BEFORE rebooting.
```

`disko-install` copies `--extra-files` into the target **between** mount and
`nixos-install`, so the age key is in place before activation runs. That is what
lets sops decrypt and `/etc/shadow` get a real hash before the first reboot.

---

## 20 — Security posture in full

### 20.1 Threat model, stated plainly

Single-user desktop, physically at home, always on Ethernet, **no listening
services**, runs games and untrusted downloads. The controls that follow target:

- network-path adversaries (encrypted DNS, strict DNSSEC, default-drop firewall,
  MAC randomisation, IPv6 privacy extensions);
- malicious files (ClamAV, metadata stripping, a sandboxed scan unit,
  filesystem sysctls);
- physical / evil-maid access to a powered-off machine (LUKS, and Secure Boot
  once enrolled).

They deliberately do **not** target a local unprivileged attacker sharing the
machine, because there isn't one. Several rejected hardening measures in §25 are
rejected precisely on that basis.

### 20.2 Kernel hardening — `security/kernel.nix`

Full values are in [Appendix A](#appendix-a--complete-kernel-tunable-values).
The reasoning:

**Two sysctl values are deliberately not maximal.**

- **`net.ipv4.conf.*.rp_filter = 2` (loose), not 1.** Strict breaks WireGuard's
  fwmark policy routing and LAN discovery (LocalSend, Steam Remote Play).
- **`kernel.yama.ptrace_scope = 1`, not 2 or 3.** 2 and 3 break gdb, RenderDoc
  and Nsight.

**`systemd.coredump.enable = false`** — PAM's core limit (set in `sudo.nix`)
does not bind systemd-coredump, which happily writes crash dumps containing
decrypted secrets and session keys to disk. Both halves are needed (§14.7).

**`networking.tempAddresses = "default"`** (IPv6 privacy extensions, RFC 4941)
goes through the **NixOS option, not a raw sysctl** — `network-interfaces.nix`
already defines `net.ipv6.conf.*.use_tempaddr` and a raw sysctl produces a
"defined multiple times" eval error. Without privacy extensions the IPv6 address
embeds a stable interface identifier that follows you across every network and
site — a supercookie no browser setting can clear.

**Module blacklist:** `dccp sctp rds tipc` (uncommon protocols with CVE
histories), `cramfs freevxfs jffs2 hfs hfsplus` (auto-mount of a crafted image
is the risk), `firewire-core` (DMA attack surface). Two are deliberately **not**
blacklisted, and both used to be: `udf` (needed to mount UDF optical media and
some game ISOs) and `thunderbolt` (this Z690 board exposes USB4/TB4 headers;
blacklisting it silently kills those ports).

**Radios (`disableRadios`, host-specific):** blacklists `iwlwifi` (CNVi WiFi —
`iwlmvm` is loaded by it and dies with it) and `btusb` (the AX201's Bluetooth
side, on USB `8087:0026`).

> This is what Plasma's airplane mode only *appears* to do. That toggle drives
> NetworkManager for WiFi and BlueZ for Bluetooth, so on a host with no
> `bluetoothd` the Bluetooth half silently no-ops: `nmcli radio all` reads
> disabled while `rfkill list` still shows `hci0` unblocked and powered.

**Recovery does not need a rebuild.** NixOS writes a plain `blacklist` line into
`/etc/modprobe.d/nixos.conf`, which only stops **udev autoloading** — an
explicit modprobe still works, so a phone hotspot is two commands away even from
a TTY with no network:

```bash
sudo modprobe iwlwifi && nmcli radio wifi on
```

USB tethering is unaffected either way — that is a `cdc_ncm`/`rndis` gadget, not
a radio, and it never touches rfkill. Not blacklisted because neither is a
radio: `hid-logitech-hidpp` (the Unifying/Lightspeed receiver is proprietary
2.4 GHz over its own dongle, not Bluetooth) and `snd-usb-audio` (the Arctis Pro
Wireless base station).

**`sysrq = 16` (sync only), NOT 0 (I11).** With an out-of-tree GPU driver and a
Wayland compositor, Alt+SysRq is the only clean way out of a wedged session, and
cutting power to a btrfs filesystem is a worse outcome than the local-attacker
scenario `sysrq=0` defends against. Values: `0` disabled · `16` sync ·
`176` sync+remount-ro+reboot · `1` everything.

**`initOnFree` is off.** Of every hardening parameter here it is the one that
shows up in frametime graphs, because games are allocation-heavy. A/B the 1%
lows in MangoHud before keeping it on.

### 20.3 sudo — `security/sudo.nix`

`wheelNeedsPassword = true`, `execWheelOnly = true`, `security.polkit.enable`,
and a hard core limit of 0 for all domains (coredumps can contain decrypted
secrets, session keys and passwords).

Logging is **event log only** (`Defaults logfile="/var/log/sudo.log"`) —
deliberately **not** `log_output`, which records full terminal transcripts into
an unrotated, unbounded `/var/log/sudo-io/`, including the output of anything you
`sudo cat /run/secrets/*`. That would turn the audit trail into the single
richest secret store on the box.

Also deliberately absent: `requiretty` (breaks sudo from systemd units, scripts
and pipes) and `timestamp_timeout=5` (already sudo's compiled-in default, so a
no-op).

### 20.4 Audit — `security/audit.nix`

**Both halves are needed.** `security.audit` alone loads rules into the kernel
with no consumer: no `/var/log/audit/audit.log` and no `ausearch`, with records
going only to the kernel ring buffer. This module enables `security.auditd` too
— which was the gap in the previous version of this config.

auditd settings cap the log at 250 MB (50 MB × 5, `ROTATE`), warn to syslog at
15% / 5% free, and **never halt or go single-user on a full disk** — on a
workstation that is a self-inflicted denial of service, not a security control.

Rules watch:

```
-w /etc/passwd  -p wa -k identity
-w /etc/shadow  -p wa -k identity
-w /etc/group   -p wa -k identity
-w /etc/sudoers   -p wa -k sudoers
-w /etc/sudoers.d -p wa -k sudoers
-w /var/lib/sops-nix -p wa -k secrets      # this machine's roots of trust
-w /var/lib/sbctl    -p wa -k secureboot
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=-1 -k privesc
-a always,exit -F arch=b64 -S init_module -S finit_module -S delete_module -k modules
```

`-F auid!=-1` skips records with an unset audit ID (daemons), which otherwise
dominate the log.

**Two rules were deliberately removed** because they made the log unreadable,
not because they were wrong: `-S connect` (one record per outbound socket — with
a browser, Tor and containers running, tens of thousands per minute) and
`-S unlink -S unlinkat -S rename -S renameat` (nearly as bad on a Nix machine
specifically: every build, GC and rebuild generates thousands). **An audit log
nobody can read is worse than no audit log, because it looks like coverage.**

### 20.5 ClamAV — `security/clamav.nix`

Updater on (12 freshclam checks/day), **resident daemon off** — clamd holds the
entire ~1 GB signature database in RAM permanently and nothing on a desktop asks
it to scan anything: there is no mail gateway and no file server here.

Note you cannot use `services.clamav.scanner` instead: nixpkgs asserts
`scanner.enable -> daemon.enable`, because that scanner shells out to
`clamdscan --fdpass` and needs a live socket. Hence a hand-written timer running
standalone `clamscan`, which loads signatures itself.

The scan unit is heavily sandboxed because it reads untrusted files by
definition:

| Setting | Value |
|---|---|
| `PrivateNetwork` | `true` |
| `ProtectSystem` | `strict` |
| `ProtectHome` | `read-only` |
| `ProtectKernelTunables` / `ProtectKernelModules` / `ProtectControlGroups` | `true` |
| `NoNewPrivileges` / `RestrictSUIDSGID` | `true` |
| `ReadOnlyPaths` | scan paths + `/var/lib/clamav` only |
| `MemoryDenyWriteExecute` | **`false`** — clamav JITs bytecode signatures |
| `SuccessExitStatus` | **`[ 1 ]`** — clamscan exits 1 when it FINDS something; without this the unit is marked failed on a successful detection |
| `Nice` / `IOSchedulingClass` | `19` / `idle` |
| timer | `Persistent = true`, `RandomizedDelaySec = 30m` |

Ad-hoc use is the common case: `scan ~/Downloads/thing.exe` (shell alias).

### 20.6 AppArmor — off, and this is the honest setting

AppArmor only loads profiles declared via `security.apparmor.policies.<name>`.
`security.apparmor.packages` merely adds an `#include` search path and loads
nothing, and the upstream `pkgs.apparmor-profiles` set is keyed on FHS paths
(`/usr/bin/firefox`) that do not exist on NixOS.

So `enable = true` with no policies **confines nothing** — it costs an
`apparmor=1` kernel flag and buys the false impression of coverage.
**Landlock, which modern applications actually use, is active either way.**

Turn this on only alongside real, hand-written policies. Enabling it "for
defence in depth" without policies is strictly worse than leaving it off,
because it makes an audit look clean.

### 20.7 Secrets — `security/secrets.nix`, `.sops.yaml`, `secrets/arctic.yaml`

```
.sops.yaml            PUBLIC, committed. age recipient:
                      age10ptah7kf5zhepd26j2h3darhu2ldl0d9fy8vedmr4f4h47gl4aqsrjntgh
                      creation_rules: secrets/[^/]+\.yaml$ -> that key

secrets/arctic.yaml   sops-ENCRYPTED, committed. Ciphertext is safe. Keys:
                        arctic-password   yescrypt hash ($y$j9T$…, 73 chars)
                        root-password     yescrypt hash

age private key       ~/.config/sops/age/keys.txt   (you, for `sops` edits)
                      /var/lib/sops-nix/key.txt     (the system, 0600 root)
                      NEVER committed. .gitignore blocks key.txt, keys.txt,
                      *.age, *.agekey, .sops-key*, age-key* — deliberately broad,
                      with `!secrets/*.yaml` so the encrypted files still commit.
```

Three deliberate non-choices in the sops wiring:

- **Not `sops.age.sshKeyPaths`** — this host runs no sshd, so there is no host
  key to derive an identity from.
- **Not `sops.age.generateKey`** — that creates a FRESH key when the file is
  missing, which cannot decrypt anything encrypted earlier. A missing key should
  be a loud failure, not a silent new identity.
- **`neededForUsers = true`** on both password secrets — this moves decryption
  ahead of user creation in the activation order (the secret lands in
  `/run/secrets-for-users`, not `/run/secrets`). Without it, users are created
  before the hash exists. sops-nix asserts these must be root-owned.

**Adding a recipient** (a second machine, a backup key): add its public key to
`.sops.yaml` as both an anchor and a `key_groups` entry, then
`sops updatekeys secrets/arctic.yaml`.

**Adding a secret:** `sops secrets/arctic.yaml`, then reference it in a module
via `config.sops.secrets."<name>".path`. Never a plaintext value in a `.nix`
file — the nix store is world-readable.

### 20.8 Secure Boot — `security/secureboot.nix`, staged off

lanzaboote replaces systemd-boot (`boot.loader.systemd-boot.enable = mkForce
false`) with a bootloader that signs the kernel, initrd and stub with **your**
keys, so firmware refuses to boot anything you did not build.

**This closes the evil-maid gap left open by full-disk encryption:** LUKS
protects data at rest, but `/boot` is unencrypted and an attacker with physical
access can otherwise swap in a kernel that captures your passphrase.

**Safe with NVIDIA on this system.** The usual worry — Secure Boot engaging
kernel lockdown and refusing the unsigned out-of-tree NVIDIA module — cannot
happen here: nixpkgs' kernel is built with `CONFIG_SECURITY_LOCKDOWN_LSM` unset
(and `CONFIG_MODULE_SIG` unset), so there is no lockdown LSM for Secure Boot to
trigger. This is the same fact that makes `lockdown=` and `module.sig_enforce=1`
inert as kernel parameters (§25).

`autoProvision = true` lets lanzaboote generate and stage keys itself, and flips
`allowUnsigned` — which is what makes a fresh install possible at all, since the
very first `nixos-install` must write bootloader artifacts to the ESP before any
keys exist. `autoReboot = false`, so enrollment completes only when you
deliberately reboot into firmware, which is the point at which you get to change
your mind.

**`includeMicrosoftKeys = true` should stay true.** Many boards ship option ROMs
(notably on discrete GPUs) signed only by Microsoft's UEFI CA; excluding them
can leave you with a machine that will not POST to a display. lanzaboote asserts
this unless you explicitly acknowledge the brick risk.

`/var/lib/sbctl` is **not in git and not recoverable** — if you lose it with
Secure Boot enforcing, recovery means clearing the keys in firmware.

### 20.9 The two files that are not in git

| File | What it is | If lost |
|---|---|---|
| `~/.config/sops/age/keys.txt` | age private key | every value in `secrets/` is unrecoverable |
| `/var/lib/sbctl/` | Secure Boot platform keys | clear Secure Boot keys in firmware to recover |

Back both up **off this machine** — a password manager and a USB stick kept
somewhere else — and verify you can read them back before relying on them. Both
are on the impermanence persist list.

### 20.10 Verifying the posture

```bash
# DNS: must show +DNSOverTLS and DNSSEC=yes, and NO fallback servers
resolvectl status
sudo tcpdump -ni any port 53          # must stay SILENT while browsing

# Firewall: input policy drop, only 53317 open
sudo nft list ruleset | head -40
ss -tulpn                             # cross-check what actually listens

# Audit trail
sudo ausearch -k privesc | tail
sudo ls -lh /var/log/audit/

# Containers run as you, not root
podman info | grep -i rootless
docker run --rm alpine id             # docker -> podman

# Secrets
sudo grep '^arctic:' /etc/shadow      # $y$j9T$... = good;  ! = BAD
ls -l /run/secrets-for-users/

# Boot chain
bootctl status
sudo sbctl verify                     # after phase 6
```

**The gaming smoke test is the one that actually matters**, because kernel
hardening breaks games by disabling user namespaces, which Steam's
pressure-vessel and flatpak/bwrap both need:

```
Steam    -> launch a Proton title        (proves pressure-vessel works)
Steam    -> gamescope session starts
Sober    -> Roblox launches and logs in  (proves bwrap works)
MangoHud -> 1% lows unchanged
```

---

## 21 — Overlays and local packages

```nix
# overlays/default.nix
{
  additions      = final: _prev: import ../pkgs { pkgs = final; };
  modifications  = _final: _prev: { };   # currently EMPTY
}
```

Both are wired into every host by `lib/mkHost.nix`, alongside
`nur.overlays.default`.

`additions` is what makes `pkgs.sweet-ambar-blue` and `pkgs.simpletux-splash`
resolvable anywhere in the config — including in home-manager modules, because
`useGlobalPkgs = true` shares the same package set. The same `./pkgs` set is
also exported as flake `packages.<system>`, so `nix build .#sweet-ambar-blue`
works.

`modifications` is for patching existing nixpkgs packages. **It is empty, and
that is a feature.** When you add one: comment WHY, and delete it the moment
upstream fixes the thing.

**Adding a package:** create `pkgs/<name>/default.nix`, add one line
(`<name> = pkgs.callPackage ./<name> { };`) to `pkgs/default.nix`, `git add`,
rebuild.

The two current packages are documented in §18.4. Both are
`stdenvNoCC.mkDerivation` with `dontUnpack = true` — a KDE theme is just a file
tree, so there is nothing to build.

---

## 22 — What this config does NOT reproduce

**This is the completeness checklist.** Everything below is imperative state. A
wipe destroys it, and the repo will not bring it back. Nothing here is an
oversight — each is either genuinely un-declarable, or is a login rather than a
restore, which is why declaring it would be more complexity than value.

### 22.1 Must be backed up before a wipe

| Item | Where | Consequence if lost |
|---|---|---|
| **age private key** | `~/.config/sops/age/keys.txt`, `/var/lib/sops-nix/key.txt` | every secret in this repo is permanently unreadable |
| **Secure Boot keys** | `/var/lib/sbctl/` | with Secure Boot enforcing, recovery means clearing keys in firmware |
| SSH keys | `~/.ssh` | |
| GPG keyring | `~/.gnupg` | |
| Flatpak app data | `~/.var/app` | **Sober keeps the Roblox login here** |
| NetworkManager connections | `/etc/NetworkManager/system-connections` | WiFi PSKs and the Proton VPN tunnels |
| libvirt VMs | `/var/lib/libvirt` | VM definitions and disk images |
| Steam library | `~/.local/share/Steam` | ~119 GB — back up or plan to re-download |

### 22.2 A login, not a restore

| Item | How it comes back |
|---|---|
| Proton VPN | open the app, sign in. It recreates its own NetworkManager connections — a wireguard interface plus killswitch and IPv6-leak dummy devices |
| WiFi | two networks, `Gaige-Network` and `iPhone`. Retype the PSKs |
| Steam library | sign in, re-download what you still play |
| Roblox | Sober installs declaratively; the login is a login |
| Brave profile | sign in to Brave Sync |

### 22.3 Referenced by the config but not contained in it

| Item | Referenced from | Note |
|---|---|---|
| `$HOME/scripts/sys-check` | `home/shell/fish.nix` alias | not in this repo |
| `$HOME/scripts/net-scan` | `home/shell/fish.nix` aliases (×5) | not in this repo |
| `$HOME/.npm-global/bin` | `fish` `interactiveShellInit` | created by npm, not declared |
| `$HOME/.cargo/bin` | `home.sessionPath` | created by rustup, not declared |
| Hand-installed KDE themes | §18.4 | `Ant-Dark`, `Sweet-Mars`, `Sweet-cursors`, `AndromedaLauncher`, `KdeControlStation` — in `~/.local/share`, deleted by a reinstall |
| `~/.local/share/plasma-manager/` state | plasma-manager | regenerated on activation |

**If you want any of §22.3 to survive a wipe, it has to move into the repo** —
the scripts into a `pkgs/` derivation or `home.file`, the themes into `pkgs/` as
§18.4 describes.

### 22.4 Declared but empty / unused

| Item | Status |
|---|---|
| `overlays.modifications` | empty — nothing in nixpkgs is patched |
| `arctic.core.nix.trustedSubstituters` / `trustedPublicKeys` | empty — no third-party caches |
| `arctic.network.firewall.allowedTCPPorts` / `UDPPorts` | empty — the only open port comes from `localsend` |
| `arctic.plasma.shortcuts` / `hotkeys` / `panels` | empty — Plasma's own defaults and your existing panels are untouched |
| `assets/wallpapers/nixos-wallpaper-1.png` | present, unreferenced |
| `/.snapshots` subvolume | created by disko; no snapshot tooling is configured yet |
| `.claude/settings.local.json` | empty permission allowlist |

---

## 23 — Recipes — where do I put X?

The table that answers most questions.

| I want to… | Put it in | Notes |
|---|---|---|
| Turn an existing feature on/off | `hosts/arctic/default.nix` | The manifest. The default answer |
| Install a CLI tool for everyone (incl. root) | the matching `modules/nixos/*/`, in `environment.systemPackages` | Root shells and recovery consoles get it too |
| Install a GUI app | `modules/nixos/apps/<category>.nix` | Behind an existing `arctic.apps.*` toggle |
| Install something only *you* use, with no system role | `modules/home/packages.nix` | `home.packages` |
| Configure a program's dotfiles | `modules/home/<area>/<prog>.nix` | Use `programs.<x>` from home-manager where one exists |
| Add a brand-new capability | a new `.nix` in the right `modules/` dir **+ list it in that dir's `default.nix`** | Recipe below |
| Change a kernel param / sysctl | `modules/nixos/security/kernel.nix` | Read §25 first — several are deliberately absent |
| Open a port | `arctic.network.firewall.allowedTCPPorts` in the manifest | Prefer a `programs.*` module if one exists (it opens the right ports itself) |
| Add a user group | `arctic.core.users.primary.extraGroups` | **The group must exist or NixOS silently drops it** — §14.4 |
| Add a secret | `sops secrets/arctic.yaml`, then reference it in a module | Never a plaintext value in a `.nix` file |
| Patch a nixpkgs package | `overlays/default.nix` → `modifications` | Comment WHY; delete it when upstream fixes it |
| Package something not in nixpkgs | `pkgs/<name>/default.nix` + one line in `pkgs/default.nix` | Auto-exposed as `pkgs.<name>` and `.#<name>` |
| Install a KDE theme | `modules/nixos/desktop/themes.nix` **and** select it in `arctic.plasma.theme.*` | **Both halves, always** — §18.2 |
| Change theme / cursor / mouse speed | `arctic.plasma.*` under `home-manager.users.arctic` | §18 |
| Add a Flatpak | `arctic.apps.flatpak.apps` | `flatpak install` by hand is reverted at the next rebuild |
| Add a second machine | `hosts/<name>/` + one `mkHost` call in `flake.nix` | Touch nothing in `modules/` |
| Something true for **every** host, not just this one | `lib/mkHost.nix` | Rare. Think first |

### 23.1 Add a package to an existing category

```nix
# modules/nixos/apps/media.nix
environment.systemPackages = with pkgs; [
  vlc
  obs-studio          # ← add here
];
```

Rebuild. Done. No option needed — a package inside an already-gated list
inherits that gate.

### 23.2 Add a new toggle to an existing module

```nix
# 1. declare it
options.arctic.apps.media = {
  streaming = lib.mkEnableOption "streaming tools";
};

# 2. use it
config = lib.mkIf cfg.enable {
  environment.systemPackages = with pkgs; [ ]
    ++ lib.optionals cfg.streaming [ obs-studio streamlink ];
};

# 3. turn it on in hosts/arctic/default.nix
apps.media.streaming = true;
```

### 23.3 Add a whole new module

```nix
# modules/nixos/apps/backup.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.backup;
in
{
  options.arctic.apps.backup = {
    enable = lib.mkEnableOption "declarative backups";

    destination = lib.mkOption {
      type = lib.types.str;
      description = ''
        restic repository URL.

        Explain WHY someone would change this, not what it is.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.restic ];
  };
}
```

Then add `./backup.nix` to `modules/nixos/apps/default.nix`, and `git add` it.
**Neither step is optional** — nothing globs, and flakes do not see untracked
files.

### 23.4 Add a second machine

```nix
# flake.nix
nixosConfigurations.laptop = myLib.mkHost {
  hostName = "laptop";
  stateVersion = "25.05";
};
```

Create `hosts/laptop/{default.nix,hardware.nix}`. Every module is already
available; the new manifest just turns on a different subset.

Things that would likely differ on a laptop:
`security.kernel.disableRadios = false` (it leaves the desk),
`gpu.nvidia.powerManagement = true`, a different `disk` layout, and the
`power.*` / `screenLocker.*` Plasma options — all of which this config leaves at
their defaults precisely because they are desktop-irrelevant.

---

## 24 — Build, test, roll back

```bash
# Evaluate + build everything WITHOUT touching the running system.
nix flake check                    # builds config.system.build.toplevel

# Apply.
sudo nixos-rebuild switch --flake ~/nixos-config#arctic

# Apply now, but do NOT make it the boot default. A reboot undoes it.
# The right choice for anything touching the GPU, boot chain, disk or SDDM.
sudo nixos-rebuild test --flake ~/nixos-config#arctic

# Build and make it the boot default, but do not activate now.
sudo nixos-rebuild boot --flake ~/nixos-config#arctic

# What would change? Run before switching.
nix build .#nixosConfigurations.arctic.config.system.build.toplevel --no-link \
  --print-out-paths | xargs nvd diff /run/current-system

# Update dependencies.
nix flake update                   # everything
nix flake update nixpkgs           # one input

# Roll back.
sudo nixos-rebuild switch --rollback
sudo nix-env --list-generations -p /nix/var/nix/profiles/system

# Lint / format (inside `nix develop`).
nix fmt                # nixfmt-tree
statix check           # anti-patterns
deadnix                # unused bindings
```

**Rolling back is also a boot menu entry.** Every generation stays in
systemd-boot. A change that breaks your desktop entirely is survivable by
rebooting and picking the previous entry — which is why `nixos-rebuild test` is
worth the habit for risky changes, and why `gc.keepDays = 7` is also your
rollback window.

### 24.1 `nix-manage.sh` (alias: `manage`)

An interactive TUI over the same operations. It **stages git changes
automatically** before every build, which is exactly the footgun it exists to
remove.

```
1  Rebuild & switch          5  View generations       9  System status
2  Test build                6  Quick clean            q  Exit
3  Update flake inputs       7  Deep clean (destroys rollback history)
4  Diff last two builds      8  Optimise store
```

Option 7 runs `nix-collect-garbage -d` (both user and root) and then
`switch-to-configuration boot` to prune the boot menu. It asks for a typed
`yes`. **It removes your ability to roll back.**

### 24.2 Which command for which change

| Change touches | Use |
|---|---|
| a package list, an app toggle | `switch` |
| GPU driver, kernel, kernel params, initrd | `test` first, then `switch` if the session survives |
| bootloader, Secure Boot, disko | `boot` — then reboot deliberately |
| disk layout on a machine that already has data | **nothing.** That path is an installer-only operation (§19) |
| Plasma settings | `switch`, then **log out and back in** (§18.10) |
| a new module file | `git add` first, then `switch` |

---

## 25 — The decisions ledger

Everything this config deliberately does **not** do. This is the most valuable
section for anyone — human or AI — proposing a change, because almost every
"obvious improvement" is already here with a reason attached.

### 25.1 Security

| Not done | Why |
|---|---|
| AppArmor enabled | Loads no policies on NixOS; confines nothing while looking like coverage. Landlock is active anyway |
| `lockdown=confidentiality` | `CONFIG_SECURITY_LOCKDOWN_LSM` is unset in nixpkgs' kernel — the parameter is inert |
| `module.sig_enforce=1` | `CONFIG_MODULE_SIG` unset — inert, and logs "Unknown kernel command line parameters" |
| `debugfs=off` | Breaks ftrace/perf/bpftrace for negligible gain against a threat model with no local attacker |
| `nosmt` | Halves throughput on a 12600K to defend against cross-HT side channels that need a hostile co-tenant, which a desktop has not |
| `mitigations=off` | The *opposite* of hardening. Listed only because gaming guides push it |
| `kernel.unprivileged_userns_clone` | A Debian/hardened-kernel patch that does not exist on nixpkgs' kernel. It was set here for a long time and logged an error every single boot |
| `user.max_user_namespaces=0` / `allowUserNamespaces=false` | Breaks Steam pressure-vessel (most Proton titles), flatpak/bwrap (Sober/Roblox), and nix's own build sandbox. There is an assertion (I2) |
| `vm.max_map_count` set here | nixpkgs already sets 1048576 via `mkDefault`. Never lower it — several DX12/Proton titles hard-fail below ~262144 (I3) |
| `kernel.perf_event_paranoid=3` | Breaks perf, intel_gpu_top and GPU profilers. Bad trade on a single-user desktop. MangoHud is unaffected (Vulkan layer + NVML) |
| `net.ipv6.conf.all.accept_ra=0` | On a machine getting IPv6 by SLAAC it means no IPv6 address at all — and it contradicts the privacy extensions, which only apply to RA-assigned addresses |
| `rp_filter=1` (strict) | Breaks WireGuard fwmark policy routing and LAN discovery |
| `ptrace_scope` 2 or 3 | Breaks gdb, RenderDoc, Nsight |
| `sysrq=0` | Alt+SysRq is the only clean recovery from a wedged NVIDIA/Wayland session (I11) |
| sudo `log_output` | Writes full terminal transcripts, unrotated and unbounded, including secrets you `sudo cat` |
| sudo `requiretty` | Breaks sudo from systemd units, scripts and pipes |
| sudo `timestamp_timeout=5` | Already sudo's compiled-in default — a no-op |
| fail2ban | Its only jail was sshd, and this host runs no sshd |
| usbguard | Was disabled with both policies set to `allow` — it would have blocked nothing either way. On a desktop with a Wooting, a Pico and controllers it is friction without a matching threat |
| sshd | Nothing needs to reach this box inbound |
| audit `-S connect` | Tens of thousands of records per minute with a browser, Tor and containers running |
| audit `-S unlink/rename` | Every nix build, GC and rebuild generates thousands |
| auditd halt-on-full-disk | A self-inflicted DoS on a workstation, not a security control |
| clamd resident daemon | ~1 GB of signatures in RAM permanently with nothing asking it to scan |
| `docker` / the `docker` group | Root-equivalent by design. Rootless podman replaced it |
| `sops.age.generateKey` | Silently creates a fresh key that cannot decrypt anything |
| `sops.age.sshKeyPaths` | No sshd, so no host key to derive from |
| `mutableUsers = false` | Turns a failed secret decryption into a permanent lockout (I4) |
| a real disk by-id in `disko.nix` | Contains the drive serial — a unique hardware identifier, and this repo is public (I17) |

### 25.2 Desktop / theming

| Not done | Why |
|---|---|
| `theme.lookAndFeel` set | This desktop runs an assembled Sweet Ambar Blue mix, not one Global Theme. A Global Theme is applied first and would undo the parts below it |
| `theme.widgetStyle` set | kdeglobals currently has no such key, so Plasma's built-in default is in force. Sweet and WhiteSur both ship Kvantum styles if you want to change that |
| `overrideConfig = true` | Not yet — capture the live config with `rc2nix` first (§18.8) |
| non-empty `panels` | Destructive on its own: applying a layout deletes the appletsrc and takes every existing panel and widget with it (I14) |
| `MOZ_DISABLE_RDD_SANDBOX=1` | Was added to fix VA-API in Firefox, which is not installed — but Tor Browser IS Firefox and does read it, so the only effect was disabling the media-decode sandbox in the one browser where it matters most |
| `MOZ_ENABLE_WAYLAND` | Same reason: no Firefox, and Tor Browser manages its own display backend |
| speech-dispatcher / orca | ~676 MB of mbrola diphones nothing here uses. **Turn on for a screen reader** — accessibility is a good reason |
| Brave managed policies | Brave Origin installs from inside Brave now. Managed policy silently wins over the in-browser UI and drifts from what upstream ships |
| Themes left in `~/.local/share` | Invisible to this repo and deleted by a reinstall. Vendor them into `pkgs/` instead — §18.4 |
| eight hand-written Wooting udev rules | `hardware.wooting.enable` installs the upstream rules package, which covers more VID/PIDs than the hand-written set did |

### 25.3 Networking

| Not done | Why |
|---|---|
| A declarative VPN module | Proton VPN is the GUI app, which manages its own NetworkManager connections (wireguard interface + killswitch + IPv6-leak dummies). Two mechanisms both claiming the default route is how you end up with a tunnel you think is up and isn't. Server switching is the whole point and is inherently interactive. **Cost: the VPN connections are imperative state and do not survive a wipe** (§22) |
| Tor `TransPort` / `DNSPort` | They open listeners that only do something if nat REDIRECT rules point traffic at them, and no such rules exist. Two idle ports that *look* like transparent proxying but aren't is worse than not having them |
| Tor `StrictNodes` | Documented as having no effect without `ExitNodes`/`EntryNodes`/`ExcludeNodes` |
| `DNSSEC = allow-downgrade` | Silently accepts unvalidated answers whenever upstream appears not to support DNSSEC — i.e. exactly the state an on-path attacker induces |
| resolved's built-in fallbacks | They are used in **plaintext** when the configured servers fail — a silent escape hatch out of every guarantee |
| LLMNR | Broadcasts this machine's hostname to every network; a known credential-relay vector on Windows-heavy LANs |
| firewall refusal logging | On a desktop it is mostly LAN broadcast/mDNS/SSDP chatter; a journal full of noise is a journal nobody reads |
| `rejectPackets` | DROP instead, so no ICMP unreachable goes back to a scanner |
| a `docker0` blanket ACCEPT rule | Went with docker |
| an ESTABLISHED,RELATED accept rule | Redundant — every NixOS firewall backend already does that in the input chain |
| `steam.openFirewall` | Remote Play / dedicated server / LAN transfer ports listen on the LAN and none are needed for single-player or normal online play |

### 25.4 Structure

| Not done | Why |
|---|---|
| `lib.filesystem.listFilesRecursive` in `default.nix` files | Breaks the moment a non-module `.nix` lands in a directory, and turns an accidental file into a silent system change |
| Interactive aliases in `environment.shellAliases` | A root shell would silently behave differently from a user shell — the wrong time to discover `grep` isn't grep |
| CLI tools declared in both system and home | Just builds two profiles containing the same store paths |
| `programs.neovim.withRuby` / `withPython3` left to stateVersion | Pulls full Ruby and Python interpreters for legacy plugin hosts nothing uses |
| ssh `enableDefaultConfig` | Deprecated upstream, and "what is in effect" should not require reading someone else's module |
| `impermanence.wipeHome` | `/home` is its own subvolume; wiping `/` alone already proves completeness without risking a 119 GB library and a decade of app state |
| flatpak `update.onActivation` | Would make every rebuild block on network I/O against Flathub and fail when Flathub is down |
| `Splash.qmlc` vendored | A compiled QML cache tied to one Qt version. Plasma regenerates it; a stale one is worse than none |
| a nixpkgs `modifications` overlay | Nothing upstream currently needs patching, and an empty overlay is a feature |

---

## 26 — Traps and failure modes

Things that will cost you an hour if nobody warns you. Ordered roughly by how
often they bite.

**"error: attribute 'foo' missing" after adding a module.** You forgot to list
it in the directory's `default.nix`, or you forgot to `git add` it.

**A new file changes nothing.** Untracked. Flakes ignore untracked files
silently. `git add -A`. (`manage` does this for you.)

**"The option `arctic.x.y' does not exist".** The module declaring it is not
imported, or you are setting a home-manager option at NixOS level (or vice
versa). Check which fixpoint you are in — §10.

**Infinite recursion.** Almost always a module reading `config.<something>` that
its own `config` block also defines (§09.1). Break it by reading `cfg` from a
narrower path, or by moving the value into a `let` binding.

**A group in `extraGroups` does nothing.** NixOS silently DROPS groups that do
not exist (I12). The group has to be created by something you actually enabled —
see the table in §14.4. A typo here fails **open** and looks like it worked.

**A package is installed but the feature does not work.** You used the bare
package where a `programs.*` / `hardware.*` module was needed — see §16.2.
Wireshark without the group, Solaar without udev rules, LocalSend without the
port, ydotool without the daemon.

**home-manager activation fails on a fresh install.** An unmanaged dotfile is in
the way. `backupFileExtension = "hm-bak"` in `mkHost.nix` handles this — it
renames the offender instead of aborting. If you remove that line, fresh
installs break.

**Plasma settings do not take effect.** Log out and back in (§18.10).

**A theme "does not apply".** Its package is not installed. Plasma falls back to
Breeze silently (I13, §18.2).

**Your theme silently reverted after a nixpkgs update.** The
`1_script_apply_themes.sh` hash changed because it embeds a store path, so it
re-ran and re-applied the declared config over your GUI changes (§18.5).

**A rebuild "works" but the change is not there.** You edited a module whose
`enable` is false, or whose parent gate is false (§14.1). `nix eval` the option
and confirm it is actually on.

**Games stopped launching after a hardening change.** You disabled user
namespaces. There is an assertion (I2), but check `security.allowUserNamespaces`
and `user.max_user_namespaces` first.

**Docker container networking broken.** The nftables backend blacklists
`ip_tables`. Docker must be removed *before* the backend switch, not after.
There is an assertion (I5).

**DNS stops working on hotel/airport WiFi.** Strict DoT means the captive-portal
interception simply fails rather than redirecting. Set
`arctic.network.dns.overTls = false` temporarily.

**No WiFi at all, and `nmcli radio wifi on` does nothing.** `disableRadios`
blacklisted `iwlwifi`. `sudo modprobe iwlwifi && nmcli radio wifi on` — no
rebuild needed (§20.2). USB tethering works regardless.

**A Flatpak you installed by hand vanished.** `uninstallUnmanaged = true`. Add
the app ID to `arctic.apps.flatpak.apps` (§12.18).

**Fresh install produced a locked account.** No password source at activation
time. The warning in `core/users.nix` fires for this, and README phase 4 has the
`nixos-enter --root /mnt -- passwd arctic` fix — but only *before* the reboot.

**Audio crackles under load.** `arctic.desktop.audio.lowLatency = false`. A
starved 32-sample quantum produces xruns; the fix is a larger buffer.

**`nix flake check` fails but `nixos-rebuild` seemed fine.** `flake check`
builds `system.build.toplevel` — it is the stricter of the two. Trust it.

**Disk space.** `/nix/store` grows without bound. `manage` → quick clean, or
`nix-collect-garbage -d`. Old generations are what you are deleting, so make
sure the current one is bootable first.

**An option's value looks wrong in the source.** Check whether another module
writes it — `arctic.core.users.primary.hashedPasswordFile` is set from
`security/secrets.nix`, not from `core/users.nix` (§14.3).

---

## 27 — Upstream schema notes

**Your prior knowledge of NixOS may be older than these.** This config uses
current schemas; older forms still work in some cases but warn, and a few were
removed outright. If you "correct" one of these to the older name, you will
break the build or silently change behaviour.

| This config uses | Older / wrong form | Note |
|---|---|---|
| `services.resolved.settings.Resolve.*` | `services.resolved.{dnssec,dnsovertls,domains,llmnr,fallbackDns}` | those are renamed aliases now and warn; `services.resolved.extraConfig` was **removed outright** |
| `programs.git.settings` (HM) | `programs.git.{userName,userEmail,extraConfig,aliases}` | new consolidated schema |
| `programs.ssh.enableDefaultConfig = false` + `settings."*"` (HM) | implicit defaults + `matchBlocks` | the implicit default set is deprecated upstream |
| `inputs.plasma-manager.homeModules.plasma-manager` | `homeManagerModules.plasma-manager` | renamed |
| `hardware.graphics.{enable,enable32Bit,extraPackages}` | `hardware.opengl.{enable,driSupport32Bit,extraPackages}` | renamed |
| `fonts.packages` | `fonts.fonts` | renamed |
| `nerd-fonts.jetbrains-mono` | `(nerdfonts.override { fonts = [ "JetBrainsMono" ]; })` | the monolithic `nerdfonts` package was split |
| `programs.gnupg.agent.pinentryPackage` | `pinentryFlavor` | renamed |
| `boot.tmp.{useTmpfs,tmpfsSize,cleanOnBoot}` | `boot.tmpOnTmpfs`, `boot.cleanTmpDir` | renamed |
| `services.displayManager.sddm` | `services.xserver.displayManager.sddm` | moved out of `xserver` |
| `services.desktopManager.plasma6` | `services.xserver.desktopManager.plasma5` | Plasma 6 lives outside `xserver` |
| `security.auditd.settings` | hand-written `auditd.conf` | typed now |
| `programs.steam.extraCompatPackages` | manual `~/.steam/root/compatibilitytools.d` | declarative now |
| `hardware.logitech.wireless.enableGraphical` | `pkgs.solaar` in `systemPackages` | the option adds the udev rules the package needs |
| `virtualisation.podman.dockerCompat` + `dockerSocket.enable` | aliasing `docker=podman` by hand | |
| `disko.enableConfig` | — | the mechanism behind `arctic.disk.useDisko` |

**Rule of thumb:** if an option name in this repo looks unfamiliar, assume it is
the *current* one and check `search.nixos.org` before "fixing" it. The
`flake.lock` pins nixpkgs at 2026-08-01, which is likely newer than your
training data.

---

## 28 — Known drift

Small inconsistencies between comments/docs and the code, found in the audit
that produced this document. **None affect the build.** All are worth fixing
when you next touch the file, and all are reasons to prefer the source over a
comment (§00.2).

| Where | Says | Actually |
|---|---|---|
| `hosts/arctic/hardware.nix` header | "Disk layout lives in `./filesystems.nix` (today's ext4 machine) and `./disko.nix`" | `filesystems.nix` was deleted in commit `5d6245c`; disko owns the filesystems |
| `hosts/arctic/default.nix`, the `disk.useDisko` comment | "false = today's ext4 machine (`./filesystems.nix`)" | the option is now `true` and that file is gone |
| `modules/nixos/disk/disko.nix`, option description | describes `false` as "today's hand-partitioned ext4 machine" | same — the machine is on the disko layout now |
| `README.md`, "Current staging state" table | lists `managePasswords` and `useDisko` as still-off | both are on (commits `514bdfa`, `015b3d7`) |
| `modules/home/desktop/plasma.nix`, `iconTheme` description | "Papirus comes from `papirus-icon-theme` in `modules/nixos/apps/utilities.nix`" | it moved to `modules/nixos/desktop/themes.nix` |
| `pkgs/default.nix` header | "Empty for now, but wired up" | it has two packages |
| `modules/nixos/desktop/themes.nix` + `pkgs/sweet-ambar-blue/default.nix` headers | cross-reference "EMPYREAN.md §10" / "§13" | this document has been renumbered; theming is now **§18** |
| `modules/nixos/network/base.nix`, `wifiMacAddress` | describes an active policy | inert on this host while `security.kernel.disableRadios = true` blacklists `iwlwifi` (the manifest notes this; the module does not) |
| repository root | — | `.directory` (KDE folder metadata) is untracked and not in `.gitignore` |

---

## 29 — Glossary

| Term | Means here |
|---|---|
| **manifest** | `hosts/arctic/default.nix` — the one file that flips switches |
| **fixpoint** | one module system's merged config. There are two: NixOS and home-manager (§10) |
| **`cfg`** | the strict convention name for `config.arctic.<this module's subtree>` |
| **gate** | the `lib.mkIf` wrapping a module's `config` block |
| **assets half / selection half** | theme packages (system) vs. theme names (user) — §18.2 |
| **staged off** | an option that is fully implemented, documented, and deliberately `false` until a specific event (usually the reinstall) |
| **vendored** | a package whose source tree is committed into `pkgs/` rather than fetched |
| **`arctic.*`** | this repo's own typed option namespace, layered over NixOS/home-manager options |
| **closure** | everything in `/nix/store` a system depends on. `nix path-info -Sh /run/current-system` |
| **generation** | one built system, kept in `/nix/var/nix/profiles/system` and in the boot menu |
| **overlay** | a function `final: prev: { … }` that adds to or modifies a package set |
| **derivation** | a build recipe. `pkgs.<name>` evaluates to one |
| **`toplevel`** | `config.system.build.toplevel` — the store path that *is* the built system |
| **inert** | imported and evaluated but contributing nothing, because its gate is false |
| **fails open** | a misconfiguration that silently grants nothing (or everything) instead of erroring — see I12, I13 |
| **one-way door** | a change that cannot be cleanly reversed later, e.g. the nftables backend |
| **root-equivalent** | a permission that is functionally root even though it is not `uid 0` — the `docker`, `libvirtd` and nix `trusted-users` cases |

---

## 30 — Further reading

| | |
|---|---|
| NixOS options search | <https://search.nixos.org/options> |
| Package search | <https://search.nixos.org/packages> |
| home-manager options | <https://home-manager-options.extranix.com> |
| plasma-manager options | <https://nix-community.github.io/plasma-manager/> |
| disko examples | <https://github.com/nix-community/disko/tree/master/example> |
| sops-nix | <https://github.com/Mic92/sops-nix> |
| lanzaboote | <https://github.com/nix-community/lanzaboote> |
| impermanence | <https://github.com/nix-community/impermanence> |
| nix-flatpak | <https://github.com/gmodena/nix-flatpak> |
| Nix language, one page | <https://nix.dev/tutorials/nix-language> |
| Module system, in depth | <https://nixos.org/manual/nixos/stable/#sec-writing-modules> |
| Local, offline | `man configuration.nix`, `man home-configuration.nix`, `man 7 xkeyboard-config` |

**The single most useful habit:** when you want to change something, find the
option with `nix repl` and tab completion rather than searching the web for a
snippet. The config in front of you is the documentation, and it is the version
that is actually true.

---

## Appendix A — complete kernel tunable values

Exact values from `modules/nixos/security/kernel.nix`, for when you need to
compare against a hardening guide rather than read prose.

### A.1 `boot.kernel.sysctl` (when `hardenSysctl`, which is the default)

```nix
# ── network ───────────────────────────────────────────────────────────────
"net.ipv4.conf.all.rp_filter"               = 2;   # LOOSE, not strict — see §20.2
"net.ipv4.conf.default.rp_filter"           = 2;
"net.ipv4.conf.all.accept_redirects"        = 0;
"net.ipv4.conf.default.accept_redirects"    = 0;
"net.ipv4.conf.all.secure_redirects"        = 0;
"net.ipv4.conf.default.secure_redirects"    = 0;
"net.ipv4.conf.all.send_redirects"          = 0;
"net.ipv4.conf.default.send_redirects"      = 0;
"net.ipv4.conf.all.accept_source_route"     = 0;
"net.ipv4.conf.default.accept_source_route" = 0;
"net.ipv6.conf.all.accept_redirects"        = 0;
"net.ipv6.conf.default.accept_redirects"    = 0;
"net.ipv6.conf.all.accept_source_route"     = 0;

"net.ipv4.tcp_syncookies"                    = 1;
"net.ipv4.tcp_rfc1337"                       = 1;  # drop TIME-WAIT assassination
"net.ipv4.icmp_echo_ignore_broadcasts"       = 1;
"net.ipv4.icmp_ignore_bogus_error_responses" = 1;
"net.ipv4.conf.all.log_martians"             = 1;

"net.core.rmem_max" = 7500000;   # helps Steam throughput and WireGuard
"net.core.wmem_max" = 7500000;

# ── kernel ────────────────────────────────────────────────────────────────
"kernel.kptr_restrict"           = 2;   # hide kernel pointers, even from root
"kernel.dmesg_restrict"          = 1;   # `sudo dmesg` still works
"kernel.kexec_load_disabled"     = 1;   # no live kernel replacement
"kernel.randomize_va_space"      = 2;
"kernel.sysrq"                   = 16;  # from arctic.security.kernel.sysrq
"kernel.yama.ptrace_scope"       = 1;   # NOT 2/3 — those break gdb/RenderDoc/Nsight
"kernel.unprivileged_bpf_disabled" = 1;
"net.core.bpf_jit_harden"        = 2;
"dev.tty.ldisc_autoload"         = 0;

# ── filesystem ────────────────────────────────────────────────────────────
"fs.protected_hardlinks" = 1;
"fs.protected_symlinks"  = 1;
"fs.protected_fifos"     = 2;
"fs.protected_regular"   = 2;
"fs.suid_dumpable"       = 0;

# ── memory ────────────────────────────────────────────────────────────────
"vm.swappiness" = 10;   # 31 GiB desktop — keep pages resident under game load
```

Plus `systemd.coredump.enable = false;` and
`networking.tempAddresses = "default";` (the latter only when
`ipv6PrivacyExtensions`).

**Deliberately NOT set here:** `net.ipv6.conf.all.accept_ra`,
`kernel.unprivileged_userns_clone`, `user.max_user_namespaces`,
`vm.max_map_count`, `kernel.perf_event_paranoid`. Each is explained in §25.1 and
in the module's own comments.

### A.2 `boot.kernelParams` (when `hardenParams`, which is the default)

```
slab_nomerge                  blocks cross-cache heap-spray techniques
init_on_alloc=1               kills a large class of uninit-memory bugs
page_alloc.shuffle=1          freelist randomisation
randomize_kstack_offset=on    per-syscall kernel stack offset
vsyscall=none                 only affects pre-2013 static 64-bit binaries

+ init_on_free=1              only when arctic.security.kernel.initOnFree
+ iommu=pt                    only when arctic.virt.libvirt.enable
```

**Deliberately NOT set:** `lockdown=confidentiality`, `module.sig_enforce=1`
(both inert — the kernel configs are unset), `debugfs=off`, `nosmt`,
`mitigations=off`. §25.1.

### A.3 `boot.blacklistedKernelModules`

```
# from blacklistModules (default true) — safe on any host
dccp sctp rds tipc              uncommon network protocols with CVE histories
cramfs freevxfs jffs2 hfs hfsplus   uncommon filesystems; auto-mount of a
                                    crafted image is the risk
firewire-core                   DMA attack surface

# from disableRadios (host-specific, ON for arctic)
iwlwifi                         CNVi WiFi; iwlmvm is loaded by it and dies with it
btusb                           the AX201's Bluetooth side (USB 8087:0026)

# from the nftables firewall backend (NixOS upstream, not this module)
ip_tables
```

**Deliberately NOT blacklisted**, and both used to be: `udf` (UDF optical media
and some game ISOs) and `thunderbolt` (this Z690 board exposes USB4/TB4
headers). Also not blacklisted because neither is a radio:
`hid-logitech-hidpp` and `snd-usb-audio`.

---

## Appendix B — file inventory

Every `.nix` file in the repository, its size, and its one-line role. Sizes are
a useful proxy for where the complexity is.

| Lines | File | Role |
|---|---|---|
| 983 | `modules/home/desktop/plasma.nix` | the entire `arctic.plasma.*` API over plasma-manager |
| 479 | `hosts/arctic/default.nix` | **the manifest** |
| 261 | `modules/nixos/security/kernel.nix` | sysctl / kernelParams / blacklists / radios |
| 155 | `modules/nixos/disk/impermanence.nix` | ephemeral root + the persist list |
| 152 | `modules/home/terminal/kitty.nix` | Tokyo Night kitty config |
| 140 | `modules/nixos/network/dns.nix` | resolved, DoT, DNSSEC, provider table |
| 118 | `hosts/arctic/disko.nix` | LUKS + btrfs subvolume layout |
| 117 | `flake.nix` | inputs and outputs |
| 113 | `modules/nixos/desktop/themes.nix` | theme packages (the assets half) |
| 107 | `modules/nixos/core/users.nix` | primary user, groups, password sourcing |
| 105 | `modules/nixos/network/firewall.nix` | nftables/iptables backend + assertions |
| 93 | `modules/nixos/security/clamav.nix` | freshclam + a sandboxed scan timer |
| 92 | `modules/nixos/core/nix.nix` | daemon settings, trusted users, GC |
| 89 | `modules/nixos/security/secrets.nix` | sops-nix wiring, password sourcing |
| 87 | `lib/mkHost.nix` | **the assembler** |
| 86 | `modules/nixos/security/secureboot.nix` | lanzaboote, staged off |
| 77 | `modules/nixos/apps/flatpak.nix` | declarative Flatpak |
| 75 | `modules/nixos/security/audit.nix` | kernel audit + auditd + rules |
| 73 | `modules/nixos/desktop/plasma.nix` | SDDM + plasma6 + the speech opt-out |
| 70 | `modules/nixos/network/tools.nix` | diagnostics, capture, scanning |
| 68 | `modules/nixos/gaming/peripherals.nix` | Wooting, Logitech, Pico |
| 67 | `modules/nixos/gaming/performance.nix` | gamescope, gamemode, nofile |
| 66 | `modules/home/shell/fish.nix` | fish, aliases, sessionPath |
| 63 | `modules/home/dev/ssh.nix` | hardened ssh client |
| 58 | `modules/nixos/core/hardware.nix` | i2c, MTP, AppImage, nix-ld, android udev |
| 57 | `pkgs/sweet-ambar-blue/default.nix` | vendored Plasma style + Aurorae + colours |
| 56 | `modules/nixos/virt/containers.nix` | rootless podman |
| 54 | `modules/nixos/apps/utilities.nix` | monitors, archives, ventoy, ydotool |
| 53 | `modules/nixos/network/base.nix` | NetworkManager, MAC policy, extraHosts |
| 53 | `modules/nixos/gaming/steam.nix` | Steam, GE-Proton, protontricks |
| 51 | `modules/nixos/core/packages.nix` | baseline system CLI |
| 51 | `modules/home/shell/starship.nix` | prompt |
| 50 | `modules/nixos/desktop/audio.nix` | PipeWire + low latency |
| 50 | `modules/nixos/core/boot.nix` | bootloader, kernel pin, /tmp tmpfs |
| 50 | `modules/home/dev/git.nix` | git identity and aliases |
| 49 | `modules/nixos/gaming/launchers.nix` | Lutris/Heroic/Prism/Wine/Vulkan |
| 48 | `modules/nixos/desktop/gpu.nix` | NVIDIA stack |
| 45 | `modules/nixos/gaming/default.nix` | master switch + userns assertion |
| 44 | `modules/nixos/security/tools.nix` | crypto/proton/opsec/audit/offensive |
| 42 | `modules/nixos/core/shell.nix` | fish + neovim as system defaults |
| 40 | `pkgs/simpletux-splash/default.nix` | vendored Plasma 6 splash |
| 40 | `modules/nixos/security/sudo.nix` | sudo hardening, polkit, core limit |
| 40 | `modules/nixos/desktop/wayland.nix` | session env vars |
| 36 | `modules/nixos/desktop/fonts.nix` | font packages + fontconfig |
| 35 | `modules/nixos/network/tor.nix` | tor client daemon |
| 33 | `modules/home/dev/neovim.nix` | neovim, no Ruby/Python hosts |
| 32 | `modules/nixos/apps/browsers.nix` | Brave, Tor Browser |
| 31 | `modules/nixos/security/apparmor.nix` | off by design |
| 31 | `modules/nixos/apps/media.nix` | VLC, OBS, GIMP, Jellyfin, qBittorrent |
| 30 | `modules/nixos/disk/disko.nix` | the `useDisko` flip |
| 30 | `modules/home/shell/tmux.nix` | tmux |
| 30 | `hosts/arctic/hardware.nix` | generated hardware facts |
| 29 | `modules/nixos/core/locale.nix` | timezone, locale, timesyncd |
| 28 | `modules/nixos/apps/dev.nix` | kitty, claude-code, VSCodium, PyCharm |
| 27 | `modules/nixos/security/gpg.nix` | gpg-agent |
| 24 | `modules/home/packages.nix` | user-scoped packages |
| 20 | `modules/nixos/virt/libvirt.nix` | libvirtd + virt-manager |
| 17 | `modules/nixos/apps/reverse-engineering.nix` | Ghidra, ImHex |
| 17 | `modules/nixos/apps/office.nix` | LibreOffice, Obsidian |
| 16 | `pkgs/default.nix` | local package list |
| 14 | `overlays/default.nix` | additions + (empty) modifications |
| 5 | `lib/default.nix` | exports mkHost |
| — | `modules/*/default.nix` (12 files) | each lists its siblings. **Nothing globs** |

Non-Nix files: `README.md` (327), `nix-manage.sh` (200), `INSTALL-CARD.txt`,
`.sops.yaml`, `.gitignore`, `secrets/arctic.yaml`, `flake.lock`, and this file.

---

*End of EMPYREAN. If something in this document contradicts the source, the
source is right — and the contradiction is a bug in this document worth fixing
on the spot.*
