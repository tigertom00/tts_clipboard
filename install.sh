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

# Update system based on package manager
if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    sudo dnf update -y
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    sudo apt update -y
    sudo apt install -y software-properties-common
    sudo add-apt-repository multiverse -y
    sudo apt update -y
elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
    sudo pacman -Syu --noconfirm
fi

# Check for Python 3.12 and prompt user
if command -v python3.12 >/dev/null 2>&1; then
    PYTHON_CMD="python3.12"
else
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_CMD="python3"
        PY_VER=$($PYTHON_CMD -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        if [[ "$PY_VER" != "3.12" ]]; then
            echo "Warning: Python $PY_VER detected. Kokoro requires Python 3.12."
            echo " "
            read -p "Python 3.12 not found. Install it? (y/N): " install_python
            if [[ "$install_python" =~ ^[Yy]$ ]]; then
                if [ "$PACKAGE_MANAGER" = "dnf" ]; then
                    sudo dnf install -y python3.12
                elif [ "$PACKAGE_MANAGER" = "apt" ]; then
                    sudo add-apt-repository ppa:deadsnakes/ppa -y
                    sudo apt update -y
                    sudo apt install -y python3.12
                elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
                    sudo pacman -S --noconfirm python3.12
                fi
                if command -v python3.12 >/dev/null 2>&1; then
                    PYTHON_CMD="python3.12"
                else
                    echo "Failed to install Python 3.12. Exiting."
                    exit 1
                fi
            else
                echo "Cannot continue without Python 3.12. Exiting."
                exit 1
            fi
        fi
    else
        echo "Error: No suitable Python 3 interpreter found. Please install Python 3.12."
        exit 1
    fi
fi



# Install remaining system dependencies
if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    sudo dnf install -y $PYTHON_CMD-pip $PYTHON_CMD-devel git ffmpeg espeak-ng libnotify xclip yad
elif [ "$PACKAGE_MANAGER" = "apt" ]; then
    sudo apt install -y $PYTHON_CMD-venv git ffmpeg espeak-ng libnotify-bin xclip yad
elif [ "$PACKAGE_MANAGER" = "pacman" ]; then
    sudo pacman -S --noconfirm python-pip python git ffmpeg espeak-ng libnotify xclip yad
fi

# Enter audio output directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_AUDIO_DIR="$SCRIPT_DIR/output"
echo " "
read -p "Enter audio output directory for saved audio files (leave blank for $DEFAULT_AUDIO_DIR): " AUDIO_DIR_INPUT
AUDIO_DIR=${AUDIO_DIR_INPUT:-$DEFAULT_AUDIO_DIR}

# Create the audio directory if it doesn't exist
mkdir -p "$AUDIO_DIR"

# Save the AUDIO_DIR to a config file
echo "AUDIO_DIR=\"$AUDIO_DIR\"" > config.sh
chmod 644 config.sh

# Clone the Kokoro repo
git clone https://huggingface.co/hexgrad/Kokoro-82M

# Create and activate virtual env with selected Python
$PYTHON_CMD -m venv .venv
source .venv/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Make the main script executable
chmod +x tts_clipboard.sh

echo "Setup complete! Run ./tts_clipboard.sh to start."
