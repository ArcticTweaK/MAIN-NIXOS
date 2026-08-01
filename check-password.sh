#!/usr/bin/env bash
# Verify that the hash stored in secrets/arctic.yaml really matches the
# password you intend to type. Run this BEFORE the reinstall — on the ISO
# there is no rescue shell if the two disagree.
#
# Prompts silently, compares in memory, stores nothing.
#
#   bash check-password.sh
#
# Delete this file whenever you like; it is a one-off utility.

set -euo pipefail
cd "$(dirname "$0")"
export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

for account in arctic-password root-password; do
  stored=$(sops -d secrets/arctic.yaml | sed -n "s/^${account}: //p")

  if [[ "$stored" != \$y\$* ]]; then
    printf '%-16s SKIP (not a yescrypt hash)\n' "$account"
    continue
  fi

  # A yescrypt hash is $y$<params>$<salt>$<digest>. Re-hashing the candidate
  # password with the SAME salt must reproduce the stored string exactly.
  prefix=$(cut -d'$' -f1-4 <<<"$stored")

  read -rsp "Password for ${account}: " pw
  echo

  if [[ "$(mkpasswd -m yescrypt -S "$prefix" -s <<<"$pw")" == "$stored" ]]; then
    printf '  -> MATCH: this password will work after the reinstall\n\n'
  else
    printf '  -> NO MATCH: the stored hash is for a DIFFERENT password.\n'
    printf '     Fix with: sops set secrets/arctic.yaml '"'"'["%s"]'"'"' "\\"$(mkpasswd -m yescrypt)\\""\n\n' "$account"
  fi
  unset pw
done
