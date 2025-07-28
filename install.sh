#!/bin/bash

# Prompt for distro type at the start
echo "Select your distro type:"
echo "1) Debian (e.g., Ubuntu, Linux Mint)"
echo "2) Fedora (e.g., RHEL, CentOS)"
echo "3) Arch Linux (e.g., Manjaro, Arch Linux)"
read -p "Enter number (1-3): " distro_choice

case $distro_choice in
    1) PACKAGE_MANAGER="apt" ;;
    2) PACKAGE_MANAGER="dnf" ;;
    3) PACKAGE_MANAGER="pacman" ;;
    *) echo "Invalid choice. Exiting."; exit 1 ;;
esac

# Update system and install system dependencies based on package manager
if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    sudo dnf update -y
    sudo dnf install -y python3-pip python3-devel git ffmpeg espeak-ng libnotify xclip yad
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    sudo apt update -y
    sudo apt install -y software-properties-common  # For add-apt-repository
    sudo add-apt-repository multiverse -y  # Enable multiverse for ffmpeg
    sudo apt update -y
    sudo apt install -y python3-pip python3-venv git ffmpeg espeak-ng libnotify-bin xclip yad
elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm python-pip python git ffmpeg espeak-ng libnotify xclip yad
fi

# Prompt for AUDIO_DIR with default to <script dir>/output if blank
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_AUDIO_DIR="$SCRIPT_DIR/output"
read -p "Enter audio output directory (leave blank for $DEFAULT_AUDIO_DIR): " AUDIO_DIR
AUDIO_DIR=${AUDIO_DIR:-$DEFAULT_AUDIO_DIR}

# Create the audio directory if it doesn't exist
mkdir -p "$AUDIO_DIR"

# Save the AUDIO_DIR to a config file
echo "AUDIO_DIR=\"$AUDIO_DIR\"" > config.sh
chmod 644 config.sh

# Clone the Kokoro repo
git clone https://huggingface.co/hexgrad/Kokoro-82M

# Create and activate virtual env
python3 -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install -r requirements.txt

# Make the main script executable
chmod +x tts-from-clipboard.sh

echo "Setup complete! Run ./tts-from-clipboard.sh to start."
