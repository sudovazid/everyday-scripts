#!/bin/bash

# Log file
LOG_FILE="/var/log/system_update.log"

# Function to log messages
log_message() {
    local MESSAGE="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $MESSAGE" | tee -a "$LOG_FILE"
}

# Error handling function
handle_error() {
    log_message "Error: $1"
    exit 1
}

# Detect package manager and update system
update_system() {
    if command -v apt > /dev/null 2>&1; then
        log_message "Detected apt package manager."
        sudo apt update && sudo apt upgrade -y || handle_error "apt update/upgrade failed."
        sudo apt autoremove -y && sudo apt clean || handle_error "apt cleanup failed."

    elif command -v yum > /dev/null 2>&1; then
        log_message "Detected yum package manager."
        sudo yum update -y || handle_error "yum update failed."
        sudo yum autoremove -y && sudo yum clean all || handle_error "yum cleanup failed."

    elif command -v pacman > /dev/null 2>&1; then
        log_message "Detected pacman package manager."
        sudo pacman -Syu --noconfirm || handle_error "pacman update failed."
        sudo pacman -Sc --noconfirm || handle_error "pacman cleanup failed."

    elif command -v brew > /dev/null 2>&1; then
        log_message "Detected Homebrew package manager."
        brew update && brew upgrade || handle_error "brew update/upgrade failed."
        brew cleanup || handle_error "brew cleanup failed."

    else
        handle_error "No supported package manager found."
    fi
}

# Optional reboot
optional_reboot() {
    echo "**********************************"
    read -p "System update completed. Do you want to reboot now? (y/N): " REBOOT_ANSWER
    if [[ "$REBOOT_ANSWER" =~ ^[Yy]$ ]]; then
        log_message "Rebooting system."
        sudo reboot
    else
        log_message "Reboot skipped by user."
    fi
}

# Main script
log_message "Starting system update script."
update_system
log_message "System update completed successfully."
optional_reboot
