#!/bin/bash
# Description: ROS Noetic Docker Manage Script (Beautiful TUI Style - English)

# Ensure working directory is the script's directory
cd "$(dirname "$0")"

CONFIG_FILE=".selected_gpu"

# Detect and define docker compose command
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Argument handling: support reset parameter
if [ "$1" = "-r" ] || [ "$1" = "--reset" ]; then
    rm -f "$CONFIG_FILE"
fi

# ==================================================
#                  TUI Border Helper Functions
# ==================================================
_get_box_width() {
    # Get current terminal columns, default to 80
    local cols=$(tput cols 2>/dev/null || echo 80)
    if ! [[ "$cols" =~ ^[0-9]+$ ]]; then
        cols=80
    fi
    # Set box width to (cols - 4), constrained between 45 and 80 columns
    local width=$(( cols - 4 ))
    if [ $width -gt 80 ]; then
        width=80
    elif [ $width -lt 45 ]; then
        width=45
    fi
    echo "$width"
}

print_box_top() {
    local w=$(_get_box_width)
    local line=""
    for ((i=0; i<w-2; i++)); do line="${line}─"; done
    echo "┌${line}┐"
}

print_box_sep() {
    local w=$(_get_box_width)
    local line=""
    for ((i=0; i<w-2; i++)); do line="${line}─"; done
    echo "├${line}┤"
}

print_box_bottom() {
    local w=$(_get_box_width)
    local line=""
    for ((i=0; i<w-2; i++)); do line="${line}─"; done
    echo "└${line}┘"
}

print_box_line() {
    local content="$1"
    local w=$(_get_box_width)
    local total_width=$(( w - 2 ))
    local text="  $content" # Left indentation
    
    # Calculate visual width
    local byte_len=$(echo -n "$text" | wc -c)
    local char_len=$(echo -n "$text" | wc -m)
    local visual_width=$(( char_len + (byte_len - char_len) / 2 ))
    
    local pad_len=$(( total_width - visual_width ))
    if [ $pad_len -lt 0 ]; then
        pad_len=0
    fi
    
    local padding=""
    if [ $pad_len -gt 0 ]; then
        padding=$(printf '%*s' "$pad_len" "")
    fi
    
    echo "│$text$padding│"
}

print_box_header() {
    local title="$1"
    local w=$(_get_box_width)
    local total_width=$(( w - 2 ))
    
    local byte_len=$(echo -n "$title" | wc -c)
    local char_len=$(echo -n "$title" | wc -m)
    local visual_width=$(( char_len + (byte_len - char_len) / 2 ))
    
    local pad_total=$(( total_width - visual_width ))
    if [ $pad_total -lt 0 ]; then
        pad_total=0
    fi
    
    local pad_left=$(( pad_total / 2 ))
    local pad_right=$(( pad_total - pad_left ))
    
    local padding_left=""
    if [ $pad_left -gt 0 ]; then
        padding_left=$(printf '%*s' "$pad_left" "")
    fi
    local padding_right=""
    if [ $pad_right -gt 0 ]; then
        padding_right=$(printf '%*s' "$pad_right" "")
    fi
    
    echo "│$padding_left$title$padding_right│"
}

# ==================================================

# Select GPU configuration function
select_gpu_config() {
    while true; do
        clear
        print_box_top
        print_box_header "Antigravity Docker Tool"
        print_box_sep
        print_box_line "[ First Run ] Please select your GPU configuration:"
        print_box_line ""
        print_box_line "  1. AMD"
        print_box_line "  2. Intel"
        print_box_line "  3. NVIDIA"
        print_box_bottom
        read -p "Enter choice [1-3]: " opt
        case $opt in
            1)
                echo "amd" > "$CONFIG_FILE"
                break
                ;;
            2)
                echo "intel" > "$CONFIG_FILE"
                break
                ;;
            3)
                echo "nvidia" > "$CONFIG_FILE"
                break
                ;;
            *)
                read -p "Invalid choice! Press Enter to retry..." temp
                ;;
        esac
    done
    clear
    print_box_top
    print_box_header "Antigravity Docker Tool"
    print_box_sep
    print_box_line "Configuration saved successfully: $(cat "$CONFIG_FILE")"
    print_box_bottom
    read -p "Press Enter to load management menu..." temp
}

# Check if first run or reset
if [ ! -f "$CONFIG_FILE" ]; then
    select_gpu_config
fi

# Main loop menu
while true; do
    if [ ! -f "$CONFIG_FILE" ]; then
        select_gpu_config
    fi
    
    GPU_TYPE=$(cat "$CONFIG_FILE")
    COMPOSE_FILE="docker-compose.${GPU_TYPE}.yml"
    
    # Check if compose file exists
    if [ ! -f "$COMPOSE_FILE" ]; then
        clear
        print_box_top
        print_box_header "Antigravity Docker Tool"
        print_box_sep
        print_box_line "Error: Config file $COMPOSE_FILE not found."
        print_box_line "Clearing broken config, please reselect..."
        print_box_bottom
        rm -f "$CONFIG_FILE"
        read -p "Press Enter to continue..." temp
        continue
    fi
    
    clear
    print_box_top
    print_box_header "Antigravity Docker Tool"
    print_box_sep
    print_box_line "[ Current Configuration ]"
    print_box_line "  - GPU Type     : $GPU_TYPE"
    print_box_line "  - Compose File : $COMPOSE_FILE"
    print_box_sep
    print_box_line "[ Available Actions ]"
    print_box_line "  1) Build Image (docker-compose build)"
    print_box_line "  2) Up Container (docker-compose up -d)"
    print_box_line "  3) Reset GPU Configuration"
    print_box_line "  4) Exit Script"
    print_box_bottom
    read -p "Please enter choice [1-4]: " choice
    echo ""

    case $choice in
        1)
            clear
            print_box_top
            print_box_header "Antigravity Docker Tool"
            print_box_sep
            print_box_line "Starting image build process..."
            print_box_bottom
            $DOCKER_COMPOSE -f "$COMPOSE_FILE" build
            echo ""
            print_box_top
            print_box_line "Image build completed!"
            print_box_bottom
            read -p "Press Enter to return to menu..." temp
            ;;
        2)
            clear
            print_box_top
            print_box_header "Antigravity Docker Tool"
            print_box_sep
            print_box_line "Starting containers in background..."
            print_box_bottom
            $DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d
            echo ""
            print_box_top
            print_box_line "Containers started in background!"
            print_box_bottom
            exit 0
            ;;
        3)
            echo "Clearing configuration..."
            rm -f "$CONFIG_FILE"
            select_gpu_config
            ;;
        4)
            clear
            print_box_top
            print_box_header "Antigravity Docker Tool"
            print_box_sep
            print_box_line "Exiting tool. Happy developing!"
            print_box_bottom
            exit 0
            ;;
        *)
            read -p "Invalid choice! Press Enter to retry..." temp
            ;;
    esac
done
