#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
#  NIX-MANAGE — Arctic's NixOS management script
#  Usage: bash ~/nixos-config/nix-manage.sh   OR   manage (shell alias)
# ─────────────────────────────────────────────────────────────────────────────

FLAKE_PATH="$HOME/nixos-config"
FLAKE_NAME="arctic"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
header() {
  clear
  echo -e "${BLUE}${BOLD}╔═══════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}${BOLD}║   NIX-MANAGE  ·  config: ${FLAKE_NAME}              ║${NC}"
  echo -e "${BLUE}${BOLD}╚═══════════════════════════════════════════════╝${NC}"
  echo -e "${DIM}  flake: ${FLAKE_PATH}${NC}\n"
}

ok()   { echo -e "${GREEN}${BOLD}✔ $*${NC}"; }
err()  { echo -e "${RED}${BOLD}✘ $*${NC}"; }
info() { echo -e "${CYAN}▶ $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }

pause() {
  echo -e "\n${DIM}Press Enter to return to menu...${NC}"
  read -r
}

# Stage git changes — flakes require files to be tracked
stage_changes() {
  if [[ -d "$FLAKE_PATH/.git" ]]; then
    info "Staging changes in $FLAKE_PATH..."
    git -C "$FLAKE_PATH" add --all
  else
    warn "Not a git repo — untracked files may not be included in the build."
  fi
}

# ── Main loop ────────────────────────────────────────────────────────────────
while true; do
  header
  echo -e "${BOLD}SYSTEM OPS${NC}"
  echo -e "  ${GREEN}1)${NC} Rebuild & switch        ${DIM}(apply all changes)${NC}"
  echo -e "  ${GREEN}2)${NC} Test build               ${DIM}(apply but don't set boot default)${NC}"
  echo -e "  ${GREEN}3)${NC} Update flake inputs      ${DIM}(refresh nixpkgs, HM, etc.)${NC}"
  echo -e "  ${GREEN}4)${NC} Diff last two builds     ${DIM}(what changed?)${NC}"

  echo -e "\n${BOLD}MAINTENANCE${NC}"
  echo -e "  ${GREEN}5)${NC} View generations         ${DIM}(boot history)${NC}"
  echo -e "  ${GREEN}6)${NC} Quick clean              ${DIM}(collect garbage)${NC}"
  echo -e "  ${GREEN}7)${NC} Deep clean               ${DIM}(delete ALL old generations + GC)${NC}"
  echo -e "  ${GREEN}8)${NC} Optimise store           ${DIM}(deduplicate /nix/store)${NC}"

  echo -e "\n${BOLD}INFO${NC}"
  echo -e "  ${GREEN}9)${NC} System status            ${DIM}(kernel, GPU, disk)${NC}"
  echo -e "  ${RED}q)${NC} Exit"
  echo -e "\n${DIM}─────────────────────────────────────────────────${NC}"
  read -rp "  Selection: " choice

  case $choice in
    # ── Rebuild & switch ──────────────────────────────────────────────────────
    1)
      stage_changes
      info "Building and activating system..."
      if sudo nixos-rebuild switch --flake "${FLAKE_PATH}#${FLAKE_NAME}"; then
        ok "Rebuild successful!"
      else
        err "Rebuild failed — check errors above."
      fi
      pause
      ;;

    # ── Test build ────────────────────────────────────────────────────────────
    2)
      stage_changes
      info "Building and testing (will not persist across reboot)..."
      if sudo nixos-rebuild test --flake "${FLAKE_PATH}#${FLAKE_NAME}"; then
        ok "Test build active — reboot to revert, or do a full switch to keep it."
      else
        err "Test build failed."
      fi
      pause
      ;;

    # ── Update flake inputs ───────────────────────────────────────────────────
    3)
      info "Updating flake.lock (fetching latest commits for all inputs)..."
      nix flake update --flake "$FLAKE_PATH"
      ok "flake.lock updated. Run option 1 to apply."
      pause
      ;;

    # ── Diff ─────────────────────────────────────────────────────────────────
    4)
      info "Comparing last two system generations..."
      GENS=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations \
        | awk '{print $1}' | tail -n 2)
      PREV=$(echo "$GENS" | head -n 1)
      CURR=$(echo "$GENS" | tail -n 1)
      if [[ -z "$PREV" || "$PREV" == "$CURR" ]]; then
        warn "Need at least two generations to diff."
      else
        nix store diff-closures \
          "/nix/var/nix/profiles/system-${PREV}-link" \
          "/nix/var/nix/profiles/system-${CURR}-link" \
          | head -80
      fi
      pause
      ;;

    # ── View generations ──────────────────────────────────────────────────────
    5)
      echo -e "${BLUE}${BOLD}Current system generations:${NC}\n"
      sudo nix-env -p /nix/var/nix/profiles/system --list-generations
      pause
      ;;

    # ── Quick clean ───────────────────────────────────────────────────────────
    6)
      info "Collecting garbage (keeps recent generations)..."
      nix-collect-garbage
      sudo nix-collect-garbage
      ok "Done."
      pause
      ;;

    # ── Deep clean ────────────────────────────────────────────────────────────
    7)
      echo -e "${RED}${BOLD}WARNING: This removes ALL old generations.${NC}"
      warn "You will lose the ability to roll back to any previous build."
      read -rp "  Are you sure? (yes/no): " confirm
      if [[ "$confirm" == "yes" ]]; then
        info "Deleting all old generations..."
        sudo nix-collect-garbage -d
        nix-collect-garbage -d
        # Update boot menu to remove deleted entries
        sudo /run/current-system/bin/switch-to-configuration boot
        ok "Deep clean complete."
      else
        info "Cancelled."
      fi
      pause
      ;;

    # ── Optimise store ────────────────────────────────────────────────────────
    8)
      info "Deduplicating /nix/store (this may take a while)..."
      nix-store --optimise
      ok "Store optimised."
      pause
      ;;

    # ── System status ─────────────────────────────────────────────────────────
    9)
      echo -e "\n${BLUE}${BOLD}── System ───────────────────────────────────────${NC}"
      echo -e "  NixOS   : $(nixos-version)"
      echo -e "  Kernel  : $(uname -r)"
      echo -e "  Uptime  : $(uptime -p)"

      echo -e "\n${BLUE}${BOLD}── GPU ──────────────────────────────────────────${NC}"
      NVDRIVER=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo "not found")
      NVGPU=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "")
      echo -e "  Driver  : $NVDRIVER"
      [[ -n "$NVGPU" ]] && echo -e "  GPU     : $NVGPU"

      echo -e "\n${BLUE}${BOLD}── Storage ──────────────────────────────────────${NC}"
      df -h / /boot | tail -n +1

      echo -e "\n${BLUE}${BOLD}── Nix store ────────────────────────────────────${NC}"
      STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1)
      GEN_COUNT=$(sudo nix-env -p /nix/var/nix/profiles/system --list-generations 2>/dev/null | wc -l)
      echo -e "  Store   : $STORE_SIZE"
      echo -e "  Gens    : $GEN_COUNT"
      pause
      ;;

    # ── Exit ──────────────────────────────────────────────────────────────────
    q|Q)
      echo -e "\n${GREEN}Stay frosty, Arctic.${NC}\n"
      exit 0
      ;;

    *)
      warn "Invalid option: '$choice'"
      sleep 1
      ;;
  esac
done