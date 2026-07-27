# ROS Environment Configuration & Utilities (TUI Style - English)

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

_print_ros_box_top() {
    local w=$(_get_box_width)
    local line=""
    for ((i=0; i<w-2; i++)); do line="${line}─"; done
    echo "┌${line}┐"
}

_print_ros_box_sep() {
    local w=$(_get_box_width)
    local line=""
    for ((i=0; i<w-2; i++)); do line="${line}─"; done
    echo "├${line}┤"
}

_print_ros_box_bottom() {
    local w=$(_get_box_width)
    local line=""
    for ((i=0; i<w-2; i++)); do line="${line}─"; done
    echo "└${line}┘"
}

_print_ros_box_line() {
    local content="$1"
    local w=$(_get_box_width)
    local total_width=$(( w - 2 ))
    local text="  $content" # Left indentation
    
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

_print_ros_box_header() {
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

# Interactive Environment Setup Function
set_env() {
    clear
    # 1. Select Network Mode
    _print_ros_box_top
    _print_ros_box_header "ROS Network Configuration"
    _print_ros_box_sep
    _print_ros_box_line "1) Local Loopback Mode (127.0.0.1)"
    _print_ros_box_line "2) Wired Connection Mode (Master: 192.168.100.2)"
    _print_ros_box_line "3) Wireless Connection Mode (Master: 192.168.1.116)"
    _print_ros_box_line "4) Manual Configuration (Custom IP & Master URI)"
    _print_ros_box_bottom
    
    local net_choice=""
    while true; do
        read -p "Select network configuration [1-4]: " net_choice
        if [[ "$net_choice" =~ ^[1-4]$ ]]; then
            break
        else
            echo "Error: Invalid choice, please enter 1-4."
        fi
    done
    
    local ip=""
    local master=""
    
    case $net_choice in
        1)
            ip="127.0.0.1"
            master="http://127.0.0.1:11311/"
            ;;
        2)
            # Auto-detect IP on 192.168.100.x subnet
            ip=$(hostname -I | tr ' ' '\n' | grep '^192.168.100.' | head -n 1)
            if [ -z "$ip" ]; then
                echo "Warning: No local IP found in 192.168.100.x subnet!"
                read -p "Please enter your local ROS_IP: " ip
            fi
            master="http://192.168.100.2:11311/"
            ;;
        3)
            # Auto-detect IP on 192.168.1.x subnet
            ip=$(hostname -I | tr ' ' '\n' | grep '^192.168.1.' | head -n 1)
            if [ -z "$ip" ]; then
                echo "Warning: No local IP found in 192.168.1.x subnet!"
                read -p "Please enter your local ROS_IP: " ip
            fi
            master="http://192.168.1.116:11311/"
            ;;
        4)
            # Manual edit of IP and Master URI
            read -p "Please enter your ROS_IP: " ip
            read -p "Please enter your ROS_MASTER_URI: " master
            ;;
    esac
    
    clear
    # 2. Select Robot Type
    _print_ros_box_top
    _print_ros_box_header "ROBOT_TYPE Configuration"
    _print_ros_box_sep
    _print_ros_box_line "1) series_legged2"
    _print_ros_box_line "2) standard6"
    _print_ros_box_line "3) hero2"
    _print_ros_box_line "4) standard3"
    _print_ros_box_line "5) Enter custom type manually"
    _print_ros_box_bottom
    
    local robot_choice=""
    while true; do
        read -p "Select or enter type [1-5]: " robot_choice
        if [[ "$robot_choice" =~ ^[1-5]$ ]]; then
            break
        else
            echo "Error: Invalid choice, please enter 1-5."
        fi
    done
    
    local robot=""
    case $robot_choice in
        1) robot="series_legged2" ;;
        2) robot="standard6" ;;
        3) robot="hero2" ;;
        4) robot="standard3" ;;
        5)
            read -p "Please enter custom ROBOT_TYPE: " robot
            ;;
    esac
    
    # 3. Export to active session
    export ROS_IP="$ip"
    export ROS_MASTER_URI="$master"
    export ROBOT_TYPE="$robot"
    
    # 4. Save to persistent cache configuration
    cat <<EOF > ~/.ros_env_config
export ROS_IP="$ip"
export ROS_MASTER_URI="$master"
export ROBOT_TYPE="$robot"
EOF
    
    # 5. Print confirmation TUI
    clear
    _print_ros_box_top
    _print_ros_box_header "Environment Configured Successfully"
    _print_ros_box_sep
    _print_ros_box_line "New terminals will automatically load these settings:"
    _print_ros_box_line ""
    _print_ros_box_line "ROS_IP         : $ROS_IP"
    _print_ros_box_line "ROS_MASTER_URI : $ROS_MASTER_URI"
    _print_ros_box_line "ROBOT_TYPE     : $ROBOT_TYPE"
    _print_ros_box_bottom
}

# Edit Config and Reload Function
openenv() {
    # Initialize default template if config doesn't exist
    if [ ! -f ~/.ros_env_config ]; then
        cat <<EOF > ~/.ros_env_config
export ROS_IP="127.0.0.1"
export ROS_MASTER_URI="http://127.0.0.1:11311/"
export ROBOT_TYPE="series_legged2"
EOF
    fi

    # Edit config file using Vim
    vim ~/.ros_env_config

    # Reload configuration in current terminal session
    if [ -f ~/.ros_env_config ]; then
        source ~/.ros_env_config
        clear
        _print_ros_box_top
        _print_ros_box_header "Environment Reloaded Successfully"
        _print_ros_box_sep
        _print_ros_box_line "ROS_IP         : $ROS_IP"
        _print_ros_box_line "ROS_MASTER_URI : $ROS_MASTER_URI"
        _print_ros_box_line "ROBOT_TYPE     : $ROBOT_TYPE"
        _print_ros_box_bottom
    fi
}
