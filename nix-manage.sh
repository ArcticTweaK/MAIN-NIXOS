#!/usr/bin/env bash

# --- CONFIGURATION ---
FLAKE_PATH="$HOME/nixos-config"
FLAKE_NAME="arctic"

# --- COLORS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- HELPER FUNCTIONS ---
header() {
    clear
    echo -e "${BLUE}${BOLD}=================================================${NC}"
    echo -e "${BLUE}${BOLD}   NIXOS PROFESSIONAL MANAGER - CONFIG: $FLAKE_NAME ${NC}"
    echo -e "${BLUE}${BOLD}=================================================${NC}"
}

# --- MAIN LOOP ---
while true; do
    header
    echo -e "${BOLD}SYSTEM OPS:${NC}"
    echo -e "  ${GREEN}1)${NC} Rebuild & Switch (Apply changes)"
    echo -e "  ${GREEN}2)${NC} Update Flake Inputs (Refresh package versions)"
    echo -e "  ${GREEN}3)${NC} System Diff (What changed since last build?)"
    
    echo -e "\n${BOLD}MAINTENANCE:${NC}"
    echo -e "  ${GREEN}4)${NC} View Generations (Boot history)"
    echo -e "  ${GREEN}5)${NC} Quick Clean (Collect garbage)"
    echo -e "  ${GREEN}6)${NC} Deep Clean (Delete old generations + Garbage)"
    echo -e "  ${GREEN}7)${NC} Optimise Store (Deduplicate files)"
    
    echo -e "\n${BOLD}INFO:${NC}"
    echo -e "  ${GREEN}8)${NC} Check Kernel & NVIDIA Status"
    echo -e "  ${RED}q)${NC} Exit"
    echo -e "-------------------------------------------------"
    read -p "Selection: " choice

    case $choice in
        1)
            echo -e "${YELLOW}Staging changes in $FLAKE_PATH...${NC}"
            if [ -d "$FLAKE_PATH/.git" ]; then
                git -C "$FLAKE_PATH" add .
            else
                echo -e "${RED}Warning: Not a git repository. Flakes require files to be tracked.${NC}"
            fi

            echo -e "${YELLOW}Starting rebuild...${NC}"
            if sudo nixos-rebuild switch --flake "$FLAKE_PATH#$FLAKE_NAME"; then
                echo -e "${GREEN}${BOLD}✔ Rebuild successful!${NC}"
            else
                echo -e "${RED}${BOLD}✘ Rebuild failed! Check the errors above.${NC}"
            fi
            ;;
        2)
            echo -e "${YELLOW}Updating flake.lock...${NC}"
            nix flake update --flake "$FLAKE_PATH"
            ;;
        3)
            echo -e "${YELLOW}Comparing last two system closures...${NC}"
            nix store diff-closures /nix/var/nix/profiles/system-$(($(sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -n 2 | head -n 1 | awk '{print $1}')))-link /nix/var/nix/profiles/system
            ;;
        4)
            echo -e "${BLUE}Current System Generations:${NC}"
            sudo nix-env -p /nix/var/nix/profiles/system --list-generations
            ;;
        5)
            echo -e "${YELLOW}Cleaning user and system garbage...${NC}"
            nix-collect-garbage && sudo nix-collect-garbage
            ;;
        6)
            echo -e "${RED}${BOLD}!!! WARNING: THIS WIPES ALL ROLLBACK HISTORY !!!${NC}"
            read -p "Are you absolutely sure? (y/n): " confirm
            if [[ $confirm == [yY] ]]; then
                sudo nix-collect-garbage -d
                sudo /run/current-system/bin/switch-to-configuration boot
            fi
            ;;
        7)
            echo -e "${YELLOW}Optimising store... (This may take a while)${NC}"
            nix-store --optimise
            ;;
        8)
            echo -e "${BLUE}Kernel:${NC} $(uname -r)"
            echo -e "${BLUE}NVIDIA:${NC} $(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null || echo 'Not Found')"
            ;;
        q)
            echo -e "${GREEN}Stay frosty, Arctic.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option.${NC}"
            ;;
    esac
    echo -e "\n${YELLOW}Press Enter to return to menu...${NC}"
    read
done