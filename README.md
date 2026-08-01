# arctic — NixOS configuration

A single-host NixOS flake built so the machine can be destroyed and rebuilt
from this repo plus two backed-up key files.

**Host:** `arctic` — i5-12600K · RTX 3070 Ti · Samsung 980 PRO 1 TB · KDE Plasma 6
(Wayland) · Steam + Proton-GE + gamescope · Roblox via Sober.

```
nixos-rebuild switch --flake ~/nixos-config#arctic     # or: manage
```

---

## Layout

```
flake.nix              inputs, mkHost, diskoConfigurations, checks, devShell
lib/mkHost.nix         the one place a machine is assembled
hosts/arctic/
  default.nix          THE MANIFEST — the only file that flips arctic.* switches
  hardware.nix         generate-config output, minus filesystems
  filesystems.nix      today's ext4 layout   (used while useDisko = false)
  disko.nix            target LUKS+btrfs     (used at reinstall)
modules/nixos/         core desktop gaming network security virt apps disk
modules/home/          shell dev terminal
secrets/arctic.yaml    sops-encrypted, committed
.sops.yaml             age recipients, public
```

Every feature is a typed `arctic.*` option with a default. To change what this
machine does, edit `hosts/arctic/default.nix` — nothing else. To add a second
machine, add `hosts/<name>/` and one `mkHost` call.

Discover options with:

```bash
nix eval .#nixosConfigurations.arctic.options.arctic --apply builtins.attrNames
```

---

## The two files that are not in git

If you lose these, no amount of git history brings the machine back.

| File | What it is | If lost |
|---|---|---|
| `~/.config/sops/age/keys.txt` | age private key | every value in `secrets/` is unrecoverable |
| `/var/lib/sbctl/` | Secure Boot platform keys | clear Secure Boot keys in firmware to recover |

Back both up **off this machine** — password manager and a USB stick you keep
somewhere else. Verify you can read them back before relying on them.

`.gitignore` blocks `key.txt`, `keys.txt`, `*.age` so the private key cannot be
committed next to the files it opens.

---

## Current staging state

These switches are deliberately off. Each is safe to leave off indefinitely and
each has a documented turn-on procedure below.

| Switch | Turn on when |
|---|---|
| `arctic.security.secrets.managePasswords` | `secrets/arctic.yaml` holds real hashes (phase 0) |
| `arctic.disk.useDisko` | you are installing onto a wiped disk (phase 1) |
| `arctic.security.secureboot.enable` | you are ready for the firmware trip (phase 6) |
| `arctic.disk.impermanence.enable` | after reinstall, once you trust the path list |
| `arctic.apps.flatpak.uninstallUnmanaged` | nothing hand-installed is still needed |

---

# Bootstrap runbook

## Phase 0 — before wiping anything (on the running system)

```bash
cd ~/nixos-config && nix develop        # sops, age, sbctl, mkpasswd, nvd

# 0.1  Put real password hashes in the secrets file.
mkpasswd -m yescrypt                    # type password -> copy the $y$... hash
sops secrets/arctic.yaml                # replace both REPLACE-ME values

# 0.2  Place the age key where the system expects it.
sudo install -d -m 0755 /var/lib/sops-nix
sudo install -m 0600 -o root -g root ~/.config/sops/age/keys.txt \
     /var/lib/sops-nix/key.txt

# 0.3  Flip managePasswords in hosts/arctic/default.nix, then:
sudo nixos-rebuild switch --flake .#arctic

#      VERIFY BEFORE LOGGING OUT. Keep a root shell open on another TTY.
sudo grep '^arctic:' /etc/shadow        # $y$j9T$... = good;  ! = BAD, fix now
ls -l /run/secrets-for-users/
su - arctic                             # in a fresh TTY

# 0.4  Back up the age key off this machine. Verify you can read it back.

# 0.5  Back up what the repo cannot rebuild.
#      ~/.ssh ~/.gnupg ~/.var/app (Sober's Roblox login lives here)
#      /etc/NetworkManager/system-connections   /var/lib/libvirt
#      ~/.local/share/Steam is ~119 GB — back up or plan to re-download.

# 0.6  Confirm the disk id is unchanged (it survives a wipe).
ls -l /dev/disk/by-id/ | grep -v part

git commit -am "..." && git push
```

## Phase 1 — flip the disko boolean

```diff
  # hosts/arctic/default.nix
- useDisko = false;
+ useDisko = true;
```

```bash
git commit -am "arctic: switch to disko layout" && git push
```

**Do not `nixos-rebuild switch` after this.** The running system would point at
partitions that do not exist yet. This commit is only ever consumed from the
installer.

## Phase 2 — firmware

1. Secure Boot → **Disabled** (or Custom → Reset to Setup Mode). It must not be
   enforcing during the install.
2. CSM off, UEFI-only boot.
3. Boot the NixOS minimal ISO.

## Phase 3 — install

```bash
sudo -i
# network first: plug in ethernet, or `systemctl start wpa_supplicant`

# Restore the age key to the ISO's tmpfs (NOT the target disk yet).
mkdir -p /tmp/keys && chmod 700 /tmp/keys
cp /run/media/<usb>/keys.txt /tmp/keys/key.txt && chmod 600 /tmp/keys/key.txt
nix-shell -p age --run 'age-keygen -y /tmp/keys/key.txt'   # must match .sops.yaml

# Identify the target disk. hosts/arctic/disko.nix deliberately contains a
# placeholder, NOT a real path — the serial is a hardware identifier and this
# repo is public. --disk overrides it, which also means the one destructive
# operation here requires naming the target explicitly.
ls -l /dev/disk/by-id/ | grep -v part

nix --experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake 'github:<you>/nixos-config#arctic' \
  --disk main /dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_XXXXXXXXXXX \
  --extra-files /tmp/keys/key.txt /var/lib/sops-nix/key.txt \
  --write-efi-boot-entries
```

You will be prompted for the LUKS passphrase during formatting.

`disko-install` copies `--extra-files` into the target *between* mount and
`nixos-install`, so the age key is in place before activation runs. Activation
happens inside `nixos-enter` during `nixos-install`, which is what lets sops
decrypt and `/etc/shadow` get a real hash before you ever reboot.

<details>
<summary>Manual alternative, if you want to inspect between steps</summary>

```bash
nix run 'github:nix-community/disko/latest' -- \
  --mode destroy,format,mount --flake 'github:<you>/nixos-config#arctic'

findmnt -R /mnt && btrfs subvolume list /mnt

install -d -m 0755 /mnt/var/lib/sops-nix
install -m 0600 -o root -g root /tmp/keys/key.txt /mnt/var/lib/sops-nix/key.txt

nixos-install --flake 'github:<you>/nixos-config#arctic' --no-root-password
```
</details>

## Phase 4 — verify BEFORE rebooting

`nixos-enter` ends its activation call with `|| true`, so activation failures
are **swallowed**. Check explicitly.

```bash
grep '^arctic:' /mnt/etc/shadow
#   arctic:$y$j9T$...   GOOD
#   arctic:!            BAD — sops did not decrypt. Diagnose before rebooting:
      ls -l /mnt/var/lib/sops-nix/key.txt
      nixos-enter --root /mnt -- journalctl -b | grep -i sops

# MANDATORY if you skipped managePasswords in phase 0. With no password
# source the account is created "!" (locked) and there is no way in after
# the reboot except booting the ISO again. Harmless to run either way —
# mutableUsers = true means it survives every future rebuild.
nixos-enter --root /mnt -- passwd arctic
nixos-enter --root /mnt -- passwd root

ls /mnt/boot/EFI/Linux/ /mnt/boot/EFI/systemd/
umount -R /mnt && cryptsetup close cryptroot && reboot
```

## Phase 5 — first boot (Secure Boot still off)

```bash
findmnt -t btrfs && sudo btrfs subvolume list / && swapon --show
ls -l /run/secrets-for-users/
journalctl -fu flatpak-managed-install    # Sober et al. install themselves
```

Then delete `hosts/arctic/filesystems.nix` and drop it from the imports — disko
owns the filesystems now.

## Phase 6 — enroll Secure Boot

Set `arctic.security.secureboot.enable = true`, rebuild, reboot. Then:

```bash
systemctl status generate-sb-keys prepare-sb-auto-enroll
sudo ls -l /var/lib/sbctl/keys        # PK/ KEK/ db/
sudo ls -l /boot/loader/keys/auto/    # PK.auth KEK.auth db.auth
```

In firmware: Secure Boot → Custom → **Reset to Setup Mode** → **Enabled**.
Save and exit. systemd-boot enrolls the three `.auth` files and the firmware
transitions to User Mode. Reboot once more, then:

```bash
bootctl status | head -6              # Secure Boot: enabled (user)
sudo sbctl verify
nvidia-smi && lsmod | grep nvidia     # GPU still works
```

If enrollment does not happen automatically, `sudo sbctl enroll-keys --microsoft`
while firmware is in Setup Mode does it by hand.

**Back up `/var/lib/sbctl/` now.**

## Phase 7 — after

Restore `~/.ssh`, `~/.gnupg`, `~/.var/app`, NetworkManager connections, Steam.

**Things this config deliberately does not reproduce.** All are a login, not a
restore — which is why they are not worth the complexity of declaring:

| | |
|---|---|
| Proton VPN | open the app, sign in. It recreates its own NetworkManager connections (a wireguard interface plus killswitch and IPv6-leak dummies) |
| WiFi | two networks, `Gaige-Network` and `iPhone`. Retype the PSKs |
| Steam library | sign in, re-download what you still play |
| Roblox | Sober installs declaratively; the login is a login |
| Brave profile | sign in to Brave Sync |

`system.stateVersion` stays `"24.11"`. Never bump it — it is a compatibility
marker for stateful defaults, not a version number.

---

## Verifying the security posture

```bash
# DNS: must show +DNSOverTLS and DNSSEC=yes, no fallback servers
resolvectl status
# and this must stay SILENT while browsing (all queries on :853, not :53)
sudo tcpdump -ni any port 53

# Firewall
sudo nft list ruleset | head -40      # input policy drop, only 53317 open

# Audit trail
sudo ausearch -k privesc | tail
sudo ls -lh /var/log/audit/

# Containers run as you, not root
podman info | grep -i rootless
docker run --rm alpine id             # docker -> podman

# Boot chain
bootctl status
```

**Gaming smoke test — the one that actually matters.** Kernel hardening breaks
games by disabling user namespaces, which Steam's pressure-vessel and
flatpak/bwrap both need:

```
Steam -> launch a Proton title        (proves pressure-vessel works)
Steam -> gamescope session starts
Sober -> Roblox launches and logs in  (proves bwrap works)
MangoHud -> 1% lows unchanged
```

---

## Notes on deliberate choices

Things that look like omissions but are not. Each is explained where it lives.

- **AppArmor is off.** It only loads profiles from `security.apparmor.policies`;
  `packages` adds an include path and loads nothing, and upstream profiles are
  keyed on FHS paths that do not exist on NixOS. Enabled-with-no-policies
  confines nothing while looking like coverage. Landlock stays active either
  way (`lsm=landlock,yama,bpf`).
- **No `lockdown=` or `module.sig_enforce`.** Both are inert on nixpkgs' kernel
  — `CONFIG_SECURITY_LOCKDOWN_LSM` and `CONFIG_MODULE_SIG` are unset. This is
  also why Secure Boot is safe with the NVIDIA module here.
- **`kernel.sysrq = 16`, not 0.** Alt+SysRq is the only clean recovery from a
  wedged NVIDIA/Wayland session; cutting power to btrfs is worse.
- **`rp_filter = 2` (loose), not 1.** Strict breaks WireGuard fwmark routing and
  LAN discovery.
- **No `accept_ra = 0`.** It is in every hardening list, but on a machine using
  SLAAC it means no IPv6 address at all.
- **No fail2ban, no usbguard, no sshd.** Nothing listens, so there is nothing to
  jail; usbguard on a desktop with a Wooting, a Pico and controllers is friction
  without a matching threat.
- **`init_on_free` is off.** The one hardening parameter that shows up in
  frametime graphs. Toggle is `arctic.security.kernel.initOnFree`.
- **Roblox is a Flatpak.** Sober is not in nixpkgs, and `vinegar` is the Roblox
  *Studio* wrapper, not this.
- **No Brave managed policies.** Brave Origin installs from inside Brave now.
  Managed policy silently overrides the in-browser UI and drifts from upstream.
