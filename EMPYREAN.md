# EMPYREAN — mastering this NixOS config

The complete map of this repo: where everything lives, what each piece is for,
and where to put the next thing you want to add.

`README.md` is the **runbook** — how to install, how to recover, what the
security posture is. This file is the **manual** — how the config is built and
how to work on it.

---

## 1. The thirty-second model

The whole repo exists to make one sentence true:

> Everything this machine is, is a value in a Nix expression that this repo
> contains.

Three ideas follow from that, and they explain every design choice here.

**Modules declare capability. The host declares facts.**
`modules/` says *"this machine COULD have Plasma / Tor / Secure Boot"* and how
each would be built. `hosts/arctic/default.nix` says *"this machine DOES"*.
No file in `modules/` knows it is on your desktop. That is what lets a second
machine reuse all of it.

**Nothing is on unless something turns it on.**
Every module is wrapped in `lib.mkIf cfg.enable`. Importing all of `modules/`
adds zero packages and zero services. Importing is not enabling.

**One file is the manifest.**
To change what this machine *does*, you edit `hosts/arctic/default.nix` and
nothing else. You edit `modules/` only to teach the config a capability it does
not yet have.

That last one is the discipline that keeps this repo readable. When you find
yourself writing a raw NixOS option in the host file, that is the signal to go
make it an `arctic.*` option in a module instead.

---

## 2. The map

```
flake.nix                  ENTRY POINT. Inputs (pinned deps) + outputs (what
                           this repo produces). The only file nix looks at first.
flake.lock                 Exact commit of every input. Never hand-edit.
                           This file is why the build is reproducible.

lib/
  default.nix              Exports the helpers. Currently just mkHost.
  mkHost.nix               THE ASSEMBLER. Builds a machine from parts: nixpkgs
                           instance, overlays, third-party modules, our modules,
                           the host file, home-manager. Everything true for
                           EVERY host lives here.

hosts/
  arctic/
    default.nix            ★ THE MANIFEST. Every arctic.* switch for this box.
                           This is the file you edit 95% of the time.
    hardware.nix           nixos-generate-config output. CPU microcode, kernel
                           modules needed to boot, hardware quirks. Machine
                           facts you did not choose.
    disko.nix              Declarative partition layout (LUKS + btrfs).
                           Consumed at install time; see README phase 3.

modules/nixos/             SYSTEM-level modules — one machine, all users.
  default.nix              Lists the subdirectories. Nothing else.
  core/       boot, hardware, locale, nix settings, packages, shell, users
  desktop/    plasma (SDDM + plasma6), gpu, fonts, audio, wayland env
  gaming/     steam, launchers, performance tuning, peripherals
  network/    NetworkManager, DNS, firewall, tor, capture tools
  security/   kernel hardening, sudo, gpg, sops secrets, secureboot,
              apparmor, audit, clamav, tool bundles
  virt/       podman, libvirt
  apps/       browsers, dev, media, office, utilities, flatpak, RE tools
  disk/       disko wiring, impermanence

modules/home/              USER-level modules — your dotfiles, your session.
  default.nix              Lists the subdirectories.
  shell/      fish, starship, tmux
  dev/        git, neovim, ssh
  terminal/   kitty
  desktop/    plasma (theme, cursor, fonts, mouse, KWin, shortcuts)
  packages.nix             User-scoped packages

overlays/default.nix       Modify or add packages globally.
                           `additions` exposes ./pkgs; `modifications` patches
                           existing nixpkgs packages.
pkgs/default.nix           Packages defined in this repo. Empty, but wired.

secrets/arctic.yaml        sops-encrypted. Committed — the ciphertext is safe.
.sops.yaml                 Which age keys can decrypt. Public.

nix-manage.sh              Interactive TUI: rebuild, update, clean, diff,
                           generations. Aliased to `manage`.
check-password.sh          Verifies a password hash before you rely on it.
INSTALL-CARD.txt           Printable reinstall crib sheet.
README.md                  Runbook: install, recover, verify, staging state.
EMPYREAN.md                This file.
```

---

## 3. How a rebuild actually flows

Understanding the order matters, because it explains where a given error comes
from.

```
  nixos-rebuild switch --flake ~/nixos-config#arctic
        │
        ├─ 1. Reads flake.nix, resolves inputs from flake.lock
        │       ← "input not found" / lock errors surface here
        │
        ├─ 2. Calls myLib.mkHost { hostName = "arctic"; ... }
        │
        ├─ 3. mkHost builds ONE module list:
        │       · nixpkgs instance + overlays + hostname
        │       · third-party modules (sops, disko, lanzaboote, flatpak,
        │         impermanence)
        │       · ../modules/nixos       ← declares every arctic.* OPTION
        │       · ../hosts/arctic        ← SETS those options
        │       · home-manager + ../modules/home + plasma-manager
        │
        ├─ 4. The module system merges all of it into one `config`
        │       ← type errors, assertions, "option does not exist",
        │         and infinite recursion all surface here
        │
        ├─ 5. Builds every derivation the result references
        │       ← compile errors and broken packages surface here
        │
        └─ 6. Activates: switches /run/current-system, starts/stops units,
              runs the home-manager activation (which writes your dotfiles
              and Plasma settings)
                ← activation script failures surface here
```

Steps 1–4 are pure evaluation and cost seconds. Step 5 is where time goes.
That is why `nix flake check` is worth running before a rebuild: it does 1–5
without touching the running system.

---

## 4. Where do I put X?

The table that answers most questions.

| I want to… | Put it in | Notes |
|---|---|---|
| Turn an existing feature on/off | `hosts/arctic/default.nix` | The manifest. Default answer. |
| Install a CLI tool for everyone (incl. root) | the matching `modules/nixos/*/`, in `environment.systemPackages` | Root shells and recovery consoles get it too |
| Install a GUI app | `modules/nixos/apps/<category>.nix` | Behind an existing `arctic.apps.*` toggle |
| Install something only *you* use, no system role | `modules/home/packages.nix` | `home.packages` |
| Configure a program's dotfiles | `modules/home/<area>/<prog>.nix` | Use `programs.<x>` from home-manager where one exists |
| Add a brand-new capability | a new `.nix` in the right `modules/` dir + list it in that dir's `default.nix` | See §6 recipe |
| Change a kernel param / sysctl | `modules/nixos/security/kernel.nix` | |
| Open a port | `arctic.network.firewall.allowedTCPPorts` in the manifest | |
| Add a user group | `arctic.core.users.primary.extraGroups` | The group must exist or NixOS silently drops it |
| Add a secret | `sops secrets/arctic.yaml`, then reference it in a module | Never a plaintext value in a `.nix` file |
| Patch a nixpkgs package | `overlays/default.nix` → `modifications` | Comment WHY; delete when upstream fixes it |
| Package something not in nixpkgs | `pkgs/<name>/default.nix` + one line in `pkgs/default.nix` | Auto-exposed as `pkgs.<name>` |
| Change theme / cursor / mouse speed | `arctic.plasma.*` under `home-manager.users.arctic` | §9 |
| Add a second machine | `hosts/<name>/` + one `mkHost` call in `flake.nix` | Touch nothing in `modules/` |
| Something true for every host, not just this one | `lib/mkHost.nix` | Rare. Think first. |

**The rule of thumb for system vs. home:** does it need root, or does it affect
other users or the boot process? System. Is it your preference about how a
program looks or behaves for you? Home.

---

## 5. Anatomy of a module

Every module in this repo has the same four-part shape. Here is
`modules/nixos/desktop/plasma.nix`, dissected:

```nix
{ config, lib, pkgs, ... }:          # ① the module arguments

let
  cfg = config.arctic.desktop;       # ② the shorthand, always named `cfg`
in
{
  options.arctic.desktop = {         # ③ WHAT CAN BE CONFIGURED
    enable = lib.mkEnableOption "a graphical desktop";

    xserver = lib.mkOption {
      type = lib.types.bool;         #    typed — a wrong value is an eval error
      default = true;                #    what happens if nobody says otherwise
      description = ''               #    why you would change it
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

**① The arguments.** `config` is the *fully merged* configuration of the whole
system — every module's output combined. `lib` is nixpkgs' function library.
`pkgs` is the package set (with this repo's overlays applied). `...` swallows
arguments you did not ask for. Use `_:` when you need none, as the `default.nix`
files do.

**② `cfg`.** Purely a convention, but a strict one here: it makes every module
readable the same way. `cfg` always points at *this module's own* option
subtree.

**③ `options`.** The declaration. This is what makes `arctic.*` a real API:
each option has a type (so typos and wrong values fail at eval, not at
runtime), a default, and a description. This is also what makes options
*discoverable* — see §8.

**④ `config` wrapped in `lib.mkIf`.** The gate. When `cfg.enable` is false the
entire attribute set below evaporates and contributes nothing. This is why
`modules/nixos/default.nix` can import everything unconditionally.

### The two `config`s that are not the same thing

This trips up everyone once:

- `config` (the argument) = the whole system's merged configuration. Read from it.
- `config = { ... }` (the attribute you define) = this module's contribution.

They have the same name and opposite directions.

### Useful `lib` functions in this codebase

| Function | Does |
|---|---|
| `lib.mkIf cond { … }` | Include this block only if `cond` |
| `lib.mkEnableOption "desc"` | Shorthand for a `bool` option defaulting to `false` |
| `lib.mkEnableOption "x" // { default = true; }` | …but defaulting to `true`. Used a lot here |
| `lib.mkOption { type; default; description; }` | A full option declaration |
| `lib.optionals cond [ … ]` | That list if `cond`, else `[ ]`. For package lists |
| `lib.optionalAttrs cond { … }` | Same, for attribute sets |
| `lib.mkDefault v` | A value any other definition beats |
| `lib.mkForce v` | A value that beats everything else |
| `lib.mkMerge [ a b ]` | Combine several definitions of one option |
| `lib.types.*` | `bool str int path package listOf attrsOf enum nullOr submodule` |

`mkDefault` and `mkForce` exist to resolve conflicts. Normally two modules
setting the same option to different values is an error; priorities break the
tie. The manifest uses `lib.mkDefault 19` for the kitty font size so a future
per-host override wins without a fight.

---

## 6. Recipes

### Add a package to an existing category

```nix
# modules/nixos/apps/media.nix
environment.systemPackages = with pkgs; [
  mpv
  obs-studio          # ← add here
];
```

Rebuild. Done. No option needed — a package inside an already-gated list
inherits that gate.

### Add a new toggle to an existing module

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

### Add a whole new module

```bash
$EDITOR modules/nixos/apps/backup.nix
```

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.arctic.apps.backup;
in
{
  options.arctic.apps.backup = {
    enable = lib.mkEnableOption "declarative backups";

    destination = lib.mkOption {
      type = lib.types.str;
      description = "restic repository URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.restic ];
  };
}
```

Then add `./backup.nix` to `modules/nixos/apps/default.nix`. **This step is not
optional** — nothing globs. Every `default.nix` lists its siblings explicitly,
deliberately, so that dropping a stray `.nix` file into a directory cannot
silently change the system.

### Add a second machine

```nix
# flake.nix
nixosConfigurations.laptop = myLib.mkHost {
  hostName = "laptop";
  stateVersion = "25.05";
};
```

Create `hosts/laptop/{default.nix,hardware.nix}`. Every module is already
available to it; the new manifest just turns on a different subset.

---

## 7. The two fixpoints

NixOS and home-manager are **separate module systems** that get evaluated
together but do not share a namespace.

|  | NixOS | home-manager |
|---|---|---|
| Configures | the machine | your user |
| Modules in | `modules/nixos/` | `modules/home/` |
| Options | `arctic.core.*`, `arctic.desktop.*`, … | `arctic.shell.*`, `arctic.plasma.*`, … |
| Set from | `hosts/arctic/default.nix` top level | `home-manager.users.arctic = { … }` at the bottom of the same file |
| Writes to | `/etc`, `/run/current-system`, systemd units | `~/.config`, `~/.local`, user units |
| Needs root | yes | no |

**Option leaf names are kept disjoint between the two on purpose.** The NixOS
tree owns `arctic.desktop`, so the home-manager Plasma module — which lives in
the directory `modules/home/desktop/` — declares its options under
`arctic.plasma` instead. Nothing would technically break if both were called
`arctic.desktop`, but then reading `config.arctic.desktop.enable` in a file
would tell you nothing about which one you were looking at.

**Crossing between them.** A home-manager module can read system config through
the `osConfig` argument:

```nix
{ config, lib, osConfig ? null, ... }:
let
  systemHasPlasma = osConfig != null && osConfig.arctic.desktop.plasma;
in { … }
```

There is no supported path in the other direction. If a NixOS module needs to
know something about your user, pass it down — do not try to read up.

---

## 8. Discovery — finding any option or value

You will need these constantly. They are the difference between guessing and
knowing.

### What options exist?

```bash
# Top-level arctic groups (system)
nix eval .#nixosConfigurations.arctic.options.arctic --apply builtins.attrNames

# Everything inside one group
nix eval .#nixosConfigurations.arctic.options.arctic.security \
  --apply builtins.attrNames

# Search all NixOS options, including upstream ones
nix search nixpkgs <term>          # packages
man configuration.nix              # options, offline
# https://search.nixos.org/options — options, searchable
# https://home-manager-options.extranix.com — home-manager options
```

### What is a value right now?

```bash
# System
nix eval .#nixosConfigurations.arctic.config.arctic.desktop.plasma
nix eval --json .#nixosConfigurations.arctic.config.networking.firewall.allowedTCPPorts

# Home-manager (note the path through home-manager.users.<name>)
nix eval .#nixosConfigurations.arctic.config.home-manager.users.arctic.arctic.plasma.theme.iconTheme
```

### What does this option mean?

```bash
# Description + type + default + which file declares it
nix eval --raw .#nixosConfigurations.arctic.options.arctic.security.kernel.sysrq.description
nix eval --json .#nixosConfigurations.arctic.options.arctic.disk.useDisko.declarations
```

### Where did this package come from?

```bash
nix why-depends /run/current-system nixpkgs#<pkg>
nix path-info -Sh /run/current-system        # total closure size
```

### Explore interactively

```bash
nix repl
nix-repl> :lf .
nix-repl> nixosConfigurations.arctic.config.arctic.<TAB>
```

Tab completion in `nix repl` is the fastest way to learn the shape of anything.

---

## 9. The `arctic.*` reference

### System — set at the top level of `hosts/arctic/default.nix`

| Group | Options |
|---|---|
| `core.boot` | `enable` `kernelPackage` `tmpfsSize` |
| `core.hardware` | `enable` `android` `appimage` `i2c` `mtp` `nixLd` `nixLdLibraries` |
| `core.locale` | `enable` `timeZone` `defaultLocale` |
| `core.nix` | `enable` `allowUnfree` `trustedUsers` `permittedInsecurePackages` `trustedSubstituters` `trustedPublicKeys` `gc.{enable,dates,keepDays}` |
| `core.packages` | `enable` `database` `devEssentials` |
| `core.shell` | `enable` `fish` `neovim` |
| `core.users` | `enable` `mutableUsers` `primary.{name,description,extraGroups,shell,hashedPassword,hashedPasswordFile}` |
| `desktop` | `enable` `plasma` `xserver` `audio.{enable,lowLatency}` `fonts.{enable,monospace}` `wayland.enable` |
| `gpu.nvidia` | `enable` `open` `branch` `vaapi` `powerManagement` |
| `gaming` | `enable` `nofileLimit` `steam.{enable,protonGE,gamescopeSession,openFirewall}` `launchers.{enable,minecraft,wine}` `peripherals.{wooting,pico}` `gamemode.enable` `gamescope.enable` |
| `network` | `extraHosts` `manager.{enable,wifiMacAddress,ethernetMacAddress}` `dns.{enable,provider,servers,overTls,dnssec,mdns,llmnr}` `firewall.{enable,backend,localsend,allowedTCPPorts,allowedUDPPorts,extraInputRules,extraCommands}` `tor.enable` `tools.{enable,capture,captureGui,scanning}` |
| `security` | `kernel.{hardenSysctl,hardenParams,blacklistModules,ipv6PrivacyExtensions,sysrq,initOnFree}` `sudo.harden` `gpg.{enable,pinentry,sshSupport}` `secrets.{enable,managePasswords,ageKeyFile,defaultSopsFile}` `secureboot.{enable,autoProvision,includeMicrosoftKeys,pkiBundle}` `apparmor.enable` `audit.enable` `clamav.{enable,interval,scanPaths}` `tools.{enable,crypto,proton,opsec,audit,offensive}` |
| `virt` | `podman.{enable,dockerCompat}` `libvirt.enable` |
| `apps` | `browsers.{enable,brave,tor}` `dev.{enable,editors,dotnet}` `media.{enable,creation,server,torrent}` `office.enable` `utilities.{enable,monitoring,archives,fileManagers,chat,usbTooling,automation}` `reverseEngineering.enable` `flatpak.{enable,apps,uninstallUnmanaged}` |
| `disk` | `useDisko` `impermanence.{enable,root,wipeHome}` |

### User — set inside `home-manager.users.arctic = { … }`

| Group | Options |
|---|---|
| `shell` | `fish.{enable,modernCliAliases}` `starship.enable` `tmux.enable` |
| `dev` | `git.{enable,userName,userEmail}` `neovim.enable` `ssh.enable` |
| `terminal` | `kitty.{enable,fontFamily,fontSize,opacity}` |
| `home` | `packages.enable` |
| `plasma` | see below |

---

## 10. Plasma — the desktop, declared

`modules/home/desktop/plasma.nix`, built on
[plasma-manager](https://github.com/nix-community/plasma-manager).

### How it works

Plasma keeps its state in `~/.config/*rc` INI files that System Settings
rewrites live. plasma-manager writes the same keys from Nix during home-manager
activation. So the two systems are writing to the same place, and the question
is only who wins.

**Every option defaults to `null`, and a null is never written.** Enabling the
module changes nothing on its own; it takes ownership of exactly the keys the
manifest names. Anything else stays under System Settings' control. This is
what makes it safe to adopt gradually.

### `arctic.plasma.*`

| Group | Options |
|---|---|
| | `enable` (follows the system) · `overrideConfig` |
| `theme` | `lookAndFeel` `colorScheme` `plasmaStyle` `widgetStyle` `iconTheme` `soundTheme` `splashScreen` `windowDecoration.{library,theme}` `titlebarButtons.{left,right}` `wallpaper` |
| `cursor` | `theme` `size` |
| `fonts` | `family` `monospace` `size` |
| `input` | `mice` (list: `name` `vendorId` `productId` `sensitivity` `accelerationProfile` `naturalScroll` `scrollSpeed` `leftHanded` `middleButtonEmulation`) · `keyboard.{numlockOnStartup,repeatDelay,repeatRate,options}` |
| `behavior` | `clickItemTo` `doubleClickInterval` `animationSpeed` `tooltipDelay` `middleClickPaste` `confirmLogout` `restoreSession` |
| `kwin` | `virtualDesktops.{number,rows,names}` `borderlessMaximized` `edgeBarrier` `cornerBarrier` `tilingPadding` `effects.{blur,blurStrength,dimInactive,slideBack,snapHelper,shakeCursor}` `nightLight.{enable,mode,dayTemperature,nightTemperature,morningTime,eveningTime,transitionTime}` |
| `screenLocker` | `autoLock` `timeout` `lockOnResume` `passwordRequired` `graceTime` |
| `power` | `turnOffDisplayIdle` `autoSuspendAction` `powerButtonAction` |
| | `shortcuts` · `hotkeys` · `panels` · `extraSettings` |

### The four theme options that sound identical

This is the single most confusing part of KDE, so:

| Option | Controls | Example |
|---|---|---|
| `theme.lookAndFeel` | **Global Theme.** The umbrella preset — sets all of the below at once. Applied first, so the others override it. | `org.kde.breezedark.desktop` |
| `theme.colorScheme` | The colour palette only | `BreezeDark` |
| `theme.plasmaStyle` | How the **panel, widgets and popups** are drawn | `default` |
| `theme.widgetStyle` | How buttons and scrollbars are drawn **inside app windows** | `Union`, `Breeze` |

Plus `theme.windowDecoration` for the titlebar, which is separate again — and
which must have `library` *and* `theme` set together or the build fails an
assertion.

**Do not set `windowDecoration` or `splashScreen` alongside `lookAndFeel`.**
The build warns about it and the warning is correct: the Global Theme is
applied first and carries its own decoration and splash, so the two race. Either
let the Global Theme supply them — what this machine does — or drop
`lookAndFeel` and assemble the parts yourself.

### Mouse speed, specifically

Two different things, often confused:

- **`sensitivity`** (−1 … 1) — the "Pointer speed" slider. A scale factor.
  0 is the middle of the slider.
- **`accelerationProfile`** — the curve.
  `"none"` is flat: pointer distance is always the same multiple of mouse
  distance. This is what "no mouse acceleration" means and it is what keeps aim
  consistent in games. `"default"` is adaptive: moving faster travels
  disproportionately further.

This machine is set to `sensitivity = 0.0` and `accelerationProfile = "none"`.

The device is identified by vendor + product + name, so settings follow the
mouse rather than the USB port. For a wireless mouse the name libinput reports
is the **receiver**, not the model. Read the true values off the running system:

```bash
grep '^\[Libinput' ~/.config/kcminputrc
# [Libinput][1133][50503][Logitech USB Receiver]
#            ^vendor ^product  — DECIMAL here, but the option wants HEX
#            1133 = 046d       50503 = c547
```

### Capturing what you already have

`rc2nix` reads your live Plasma config and prints it as Nix. This is how you
migrate settings you tuned by hand instead of trying to remember them:

```bash
nix run github:nix-community/plasma-manager#rc2nix > /tmp/current-plasma.nix
```

Read it, take what you want into `arctic.plasma.*` (using the typed options
where they exist and `extraSettings` where they do not), and discard the noise —
it dumps a lot of window geometry and per-app state you do not want declared.

### Two settings that will delete things

**`overrideConfig = true`** makes this config the sole authority: on every
generation plasma-manager deletes Plasma's config files and rebuilds them from
Nix alone. Anything you changed in the GUI and did not declare is gone at next
login. It is the honest end state, but get there by capturing first.

**A non-empty `panels` list** is destructive on its own, regardless of
`overrideConfig` — applying a layout requires deleting
`plasma-org.kde.plasma.desktop-appletsrc`, which takes your existing panels,
their widgets and every widget's settings with it. Empty (the default) leaves
panels completely alone. Declare panels only when you are ready to declare all
of them.

### Applying changes

Most settings need a **log out and back in**. Plasma caches config in running
processes; rewriting the file underneath them does not notify them. Some take
effect after `systemctl --user restart plasma-plasmashell`, but the reliable
answer is a fresh session.

### The wallpaper caveat

`theme.wallpaper` takes a Nix path, which under flakes must be **inside the
repo**. An absolute path like `/home/arctic/Documents/wallpapers/x.jpg` is
rejected by pure evaluation — and would not survive a reinstall anyway, which is
the point of this repo. Commit the image (an `assets/` directory is the obvious
home) and reference it relatively.

---

## 11. Build, test, roll back

```bash
# Evaluate + build everything WITHOUT touching the running system.
nix flake check                    # builds config.system.build.toplevel

# Apply.
sudo nixos-rebuild switch --flake ~/nixos-config#arctic

# Apply now, but do NOT make it the boot default. A reboot undoes it.
# The right choice for anything touching the GPU, boot, or disk.
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
```

Or `manage` (`nix-manage.sh`) for the same things behind a menu.

**Rolling back is also a boot menu entry.** Every generation stays in
systemd-boot. A change that breaks your desktop entirely is survivable by
rebooting and picking the previous entry — which is why `nixos-rebuild test` is
worth the habit for risky changes.

**`nix develop`** drops you in a shell with the repo's tools: `nixfmt-tree`,
`statix`, `deadnix`, `sops`, `age`, `sbctl`, `mkpasswd`, `nvd`,
`nix-output-monitor`.

```bash
nix fmt                # format
statix check           # anti-patterns
deadnix               # unused bindings
```

---

## 12. House rules

Conventions this repo actually enforces. Following them keeps it coherent.

1. **`hosts/arctic/default.nix` contains only `arctic.*` switches and machine
   facts.** A raw NixOS option appearing there is a sign a module is missing.
2. **Every `default.nix` lists its siblings explicitly.** No
   `listFilesRecursive`. It breaks the moment a non-module `.nix` lands in the
   directory, and it makes an accidental file into a silent system change.
3. **Every option is typed and has a description.** The type is what turns a
   typo into an eval error instead of a runtime surprise.
4. **Every module gates its `config` behind `lib.mkIf`.**
5. **Comment the WHY, never the what.** The existing comments explain why
   `sysrq = 16` and not `0`, why AppArmor is off, why there is no `docker`
   group. That is the repo's most valuable content — a future you re-litigating
   a settled decision is the thing these comments prevent.
6. **Every entry in `permittedInsecurePackages` gets a comment** saying what
   needs it and why that is acceptable. Otherwise it outlives its reason.
7. **`system.stateVersion` is never bumped.** It is a compatibility marker for
   stateful defaults, not a version number.
8. **Secrets are sops-encrypted or they are not in the repo.** No plaintext
   credentials in a `.nix` file, ever — the store is world-readable and this
   repo is public.
9. **`git add` before rebuilding.** Flakes only see tracked files; an untracked
   new module is invisible and the error will not say so. `nix-manage.sh` stages
   for you.

---

## 13. Traps

Things that will cost you an hour if nobody warns you.

**"error: attribute 'foo' missing" after adding a module.** You forgot to list
it in the directory's `default.nix`, or you forgot to `git add` it.

**A new file changes nothing.** Untracked. Flakes ignore untracked files
silently. `git add -A`.

**"The option `arctic.x.y' does not exist".** The module declaring it is not
imported, or you are setting a home-manager option at NixOS level (or vice
versa). Check which fixpoint you are in — §7.

**Infinite recursion.** Almost always a module reading `config.<something>` that
its own `config` block also defines. Break it by reading `cfg` from a narrower
path, or by moving the value into a `let` binding.

**A group in `extraGroups` does nothing.** NixOS silently DROPS groups that do
not exist. The group has to be created by something you actually enabled —
`programs.wireshark.enable` creates `wireshark`, `services.tor.enable` creates
`tor`. A typo here fails open and looks like it worked.

**home-manager activation fails on a fresh install.** An unmanaged dotfile is in
the way. `backupFileExtension = "hm-bak"` in `mkHost.nix` handles this — it
renames the offender instead of aborting.

**Plasma settings do not take effect.** Log out and back in. See §10.

**A rebuild "works" but the change is not there.** You edited a module whose
`enable` is false. `nix eval` the option and confirm it is actually on.

**Disk space.** `/nix/store` grows without bound. `manage` → quick clean, or
`nix-collect-garbage -d`. Old generations are what you are deleting, so keep
the current one bootable first.

---

## 14. Learning further

| | |
|---|---|
| Options search | <https://search.nixos.org/options> |
| Package search | <https://search.nixos.org/packages> |
| home-manager options | <https://home-manager-options.extranix.com> |
| plasma-manager options | <https://nix-community.github.io/plasma-manager/> |
| Nix language, one page | <https://nix.dev/tutorials/nix-language> |
| Module system, in depth | <https://nixos.org/manual/nixos/stable/#sec-writing-modules> |
| Local, offline | `man configuration.nix`, `man home-configuration.nix` |

The single most useful habit: when you want to change something, find the option
with `nix repl` and tab completion rather than searching the web for a snippet.
The config in front of you is the documentation, and it is the version that is
actually true.
