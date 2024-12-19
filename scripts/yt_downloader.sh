#!/bin/bash

# Default settings
default_folder="$HOME/Downloads/Youtube-Downloads"
config_file="$HOME/.yt_downloader_config"
download_log="$HOME/.yt_download_history.log"

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure default directories exist
mkdir -p "$default_folder"
touch "$download_log"

# Load saved preferences if they exist
load_preferences() {
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        # Default preferences
        preferred_quality="720p"
        preferred_format="video"
        echo "preferred_quality=$preferred_quality" > "$config_file"
        echo "preferred_format=$preferred_format" >> "$config_file"
    fi
}

# Function to check and install dependencies
check_and_install_dependencies() {
    local missing_deps=()
    
    # Check for yt-dlp
    if ! command -v yt-dlp >/dev/null 2>&1; then
        missing_deps+=("yt-dlp")
    else
        echo -e "${GREEN}yt-dlp is already installed.${NC}"
        yt-dlp -U
    fi
    
    # Check for jq
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    # Check for bc
    if ! command -v bc >/dev/null 2>&1; then
        missing_deps+=("bc")
    fi

    # Install missing dependencies
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${YELLOW}Installing missing dependencies: ${missing_deps[*]}${NC}"
        
        case "$(uname -s)" in
            Linux)
                if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    case "$ID" in
                        ubuntu|debian)
                            sudo apt update
                            sudo apt install -y "${missing_deps[@]}"
                            ;;
                        fedora|rhel|centos)
                            sudo dnf install -y "${missing_deps[@]}"
                            ;;
                        arch|manjaro)
                            sudo pacman -Sy "${missing_deps[@]}" --noconfirm
                            ;;
                        *)
                            echo "Unsupported Linux distribution. Please install ${missing_deps[*]} manually."
                            exit 1
                            ;;
                    esac
                fi
                ;;
            Darwin)
                if command -v brew >/dev/null 2>&1; then
                    brew install "${missing_deps[@]}"
                else
                    echo "Installing Homebrew first..."
                    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    brew install "${missing_deps[@]}"
                fi
                ;;
        esac
    fi
}

# Add this new function to draw the progress bar
draw_progress_bar() {
    local percent=$1
    local width=50
    local filled=$(printf "%.0f" $(echo "$percent * $width / 100" | bc -l))
    local empty=$((width - filled))
    
    # Create the progress bar
    printf "\r[${GREEN}"
    printf "%${filled}s" '' | tr ' ' '█'
    printf "${NC}"
    printf "%${empty}s" '' | tr ' ' '▒'
    printf "] ${GREEN}%3.1f%%${NC}" "$percent"
}

# Modified show_progress function to use progress bar
show_progress() {
    yt-dlp --newline --progress-template "[download] %(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s|%(progress._total_bytes_str)s" "$@" |
    while IFS='|' read -r percent speed eta size || [ -n "$percent" ]; do
        if [[ $percent =~ ([0-9.]+)% ]]; then
            percentage="${BASH_REMATCH[1]}"
            # Clear the line and draw progress bar
            printf "\033[2K" # Clear the entire line
            draw_progress_bar "$percentage"
            # Print additional information
            printf " Speed: ${BLUE}%s${NC} ETA: ${YELLOW}%s${NC} Size: ${BLUE}%s${NC}" "$speed" "$eta" "$size"
        fi
    done
    echo # New line after completion
}

# Function to get video information
# Modified get_video_info function with better error handling
get_video_info() {
    local link=$1
    echo -e "${BLUE}Fetching video information...${NC}"
    local info
    info=$(yt-dlp -J "$link" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$info" | jq -r '. | "Title: \(.title)\nChannel: \(.channel)\nDuration: \(.duration_string)\nUpload Date: \(.upload_date)"'
    else
        echo -e "${RED}Error fetching video information${NC}"
    fi
}

# Function to get estimated size for a specific format
get_video_size() {
    local link=$1
    local quality=$2
    echo -e "${BLUE}Calculating size for $quality...${NC}"
    yt-dlp -f "$quality" --print "filesize" --print "filesize_approx" "$link" 2>/dev/null |
        awk '{sum+=$1} END {if (sum > 0) print sum; else print "NA"}' | numfmt --to=iec --suffix=B
}

# Function to show available formats
show_formats() {
    local link=$1
    echo -e "${BLUE}Available formats:${NC}"
    yt-dlp -F "$link"
}

# Function to log download
log_download() {
    local link=$1
    local quality=$2
    local format=$3
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Downloaded: $link (Quality: $quality, Format: $format)" >> "$download_log"
}

# Main menu function
show_main_menu() {
    echo -e "${GREEN}!************************!${NC}"
    echo "🎥 YouTube Downloader Menu:"
    echo "1. Download Video 🖥️"
    echo "2. Download Playlist 📟"
    echo "3. Download Audio Only 🎵"
    echo "4. Show Download History 📋"
    echo "5. Settings ⚙️"
    echo "6. Exit ⛔"
    echo -e "${GREEN}!************************!${NC}"
}

# Settings menu function
show_settings_menu() {
    while true; do
        echo -e "${YELLOW}Settings Menu:${NC}"
        echo "1. Set Default Quality"
        echo "2. Set Default Download Format"
        echo "3. Set Default Download Directory"
        echo "4. Back to Main Menu"
        read -p "Enter your choice: " settings_choice

        case $settings_choice in
            1)
                echo "Select Default Quality:"
                echo "1. 1080p"
                echo "2. 720p"
                echo "3. 480p"
                echo "4. 360p"
                read -p "Enter your choice: " quality_choice
                case $quality_choice in
                    1) preferred_quality="1080p";;
                    2) preferred_quality="720p";;
                    3) preferred_quality="480p";;
                    4) preferred_quality="360p";;
                esac
                echo "preferred_quality=$preferred_quality" > "$config_file"
                echo "Default quality set to $preferred_quality"
                ;;
            2)
                echo "Select Default Format:"
                echo "1. Video"
                echo "2. Audio"
                read -p "Enter your choice: " format_choice
                case $format_choice in
                    1) preferred_format="video";;
                    2) preferred_format="audio";;
                esac
                echo "preferred_format=$preferred_format" >> "$config_file"
                echo "Default format set to $preferred_format"
                ;;
            3)
                read -p "Enter new default download directory: " new_folder
                if [ ! -z "$new_folder" ]; then
                    default_folder="$new_folder"
                    mkdir -p "$default_folder"
                    echo "Download directory updated to: $default_folder"
                fi
                ;;
            4) break;;
        esac
    done
}

# Main script execution
echo -e "${GREEN}Checking and installing dependencies...${NC}"
check_and_install_dependencies

# Load preferences
load_preferences

# Main loop
while true; do
    show_main_menu
    read -p "Enter your choice: " option

    case $option in
        1) # Download Video
            read -p "Enter video link: " link
            get_video_info "$link"
            
            
            echo -e "${YELLOW}Select Quality:${NC}"
            echo "1. 1080p (HD) 🎮"
            echo "2. 720p (HD) 🎮"
            echo "3. 480p 📺"
            echo "4. 360p 📱"
            echo "5. Custom Format Code 🔧"
            read -p "Enter your choice: " quality_option

            case $quality_option in
                1) quality="bestvideo[height<=1080]+bestaudio/best";;
                2) quality="bestvideo[height<=720]+bestaudio/best";;
                3) quality="bestvideo[height<=480]+bestaudio/best";;
                4) quality="bestvideo[height<=360]+bestaudio/best";;
                5) show_formats "$link"
                    read -p "Enter format code: " format_code
                    quality="$format_code"
                    ;;
                *) 
                    echo -e "${RED}Invalid quality option.${NC}"
                    continue
                    ;;
            esac

            read -p "Enter download folder (leave blank for default: $default_folder): " folder
            folder=${folder:-$default_folder}
            mkdir -p "$folder"

            show_progress -f "$quality" -o "$folder/%(title)s.%(ext)s" "$link"
            log_download "$link" "$quality" "video"
            ;;
            
        2) # Download Playlist
            read -p "Enter playlist link: " link
            echo -e "${YELLOW}Select Quality:${NC}"
            echo "1. 1080p (HD) 🎮"
            echo "2. 720p (HD) 🎮"
            echo "3. 480p 📺"
            echo "4. 360p 📱"
            read -p "Enter your choice: " quality_option

            case $quality_option in
                1) quality="bestvideo[height<=1080]+bestaudio/best";;
                2) quality="bestvideo[height<=720]+bestaudio/best";;
                3) quality="bestvideo[height<=480]+bestaudio/best";;
                4) quality="bestvideo[height<=360]+bestaudio/best";;
                *) 
                    echo -e "${RED}Invalid quality option.${NC}"
                    continue
                    ;;
            esac

            read -p "Enter download folder (leave blank for default: $default_folder): " folder
            folder=${folder:-$default_folder}
            mkdir -p "$folder"

            show_progress -f "$quality" --yes-playlist -o "$folder/%(playlist_index)s-%(title)s.%(ext)s" "$link"
            log_download "$link" "$quality" "playlist"
            ;;

        3) # Download Audio Only
            read -p "Enter video/playlist link: " link
            echo -e "${YELLOW}Select Audio Quality:${NC}"
            echo "1. Best Audio Quality 🎵"
            echo "2. Medium Quality 🎵"
            echo "3. Low Quality 🎵"
            read -p "Enter your choice: " audio_option

            case $audio_option in
                1) quality="bestaudio/best";;
                2) quality="bestaudio[abr<=128]/best";;
                3) quality="bestaudio[abr<=96]/best";;
                *) 
                    echo -e "${RED}Invalid audio quality option.${NC}"
                    continue
                    ;;
            esac

            read -p "Enter download folder (leave blank for default: $default_folder): " folder
            folder=${folder:-$default_folder}
            mkdir -p "$folder"

            show_progress -f "$quality" -x --audio-format mp3 -o "$folder/%(title)s.%(ext)s" "$link"
            log_download "$link" "$quality" "audio"
            ;;

        4) # Show Download History
            echo -e "${BLUE}Download History:${NC}"
            if [ -s "$download_log" ]; then
                cat "$download_log"
            else
                echo "No download history available."
            fi
            read -p "Press Enter to continue..."
            ;;

        5) # Settings
            show_settings_menu
            ;;

        6) # Exit
            echo -e "${GREEN}Thanks for using YouTube Downloader! Goodbye! 👋${NC}"
            exit 0
            ;;

        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done