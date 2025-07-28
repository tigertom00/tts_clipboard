# Kokoro TTS Clipboard Reader

This project is a simple yet powerful tool that converts text from your clipboard into natural-sounding speech using the open-source Kokoro TTS engine. It's designed for Linux users who want quick TTS playback with customizable options like voice and speed, playback controls (pause, resume, stop), and the ability to save audio files. The script is ideal for reading articles, notes, or any copied text aloud, with chunking for long content to avoid memory issues.

Kokoro is a lightweight neural TTS model (82M parameters) that runs offline, supporting multiple voices and languages (primarily English). It uses ONNX for inference, making it efficient even on modest hardware. This script integrates Kokoro with clipboard access, audio generation, and playback, all in a user-friendly way.

The project is open-source, MIT-licensed, and tested on Fedora, Debian/Ubuntu-based systems (like Linux Mint), and Arch Linux. It requires a few system dependencies but sets up everything via a virtual environment for isolation.

![TTS Screenshot](https://github.com/tigertom00/tts_clipboard/tts_screenshot.png)

## Features

- **Clipboard Integration**: Automatically reads text from your clipboard using `xclip`.
- **Customizable TTS**: Select speed (e.g., 1.2 for faster, 0.8 for slower) and voice (e.g., af_heart for neutral American female, adam for male) via a YAD dialog.
- **Chunking for Long Text**: Splits long text into chunks (min 20/max 60 words, preferring sentence breaks) to handle memory limits and generate audio in parts.
- **Playback Controls**: Pause (p), resume (r), stop (s) via terminal keys, or desktop notifications with buttons.
- **Save Options**: Save and play, or save only (no playback). Supports MP3, OGG, WAV formats with compression using FFmpeg or SoX.
- **Default Filename**: Generates a filename from the first 3 words of the text for convenience.
- **Notifications**: Desktop notifications for progress, errors, and success (using libnotify).
- **CLI Flags**: Optional -save flag for command-line saving without dialog.
- **Cross-Distro Support**: Install script handles Fedora (dnf), Debian/Ubuntu/Mint (apt), Arch (pacman).

## Prerequisites

- **Operating System**: Linux (tested on Fedora 42, Linux Mint/Ubuntu, Arch).
- **Python**: 3.8+ (installed by default on most distros).
- **System Packages** (installed by `install.sh`):
  - Clipboard: xclip
  - Audio: ffmpeg (includes ffplay for playback)
  - Dialogs: yad (for GUI settings)
  - Notifications: libnotify (or libnotify-bin on Debian)
  - TTS Deps: espeak-ng (for phonetics)
  - Tools: git, python3-pip, python3-venv/python3-devel
- **Hardware**: Works on CPU; GPU (NVIDIA with CUDA) speeds up generation if available (Kokoro auto-detects via PyTorch).
- **No Internet Needed After Setup**: Kokoro model is downloaded during install; TTS runs offline.

## Installation

1. **Clone the repository**:

   ```
   git clone https://github.com/tigertom00/tts_clipboard.git
   cd tts_clipboard
   ```

2. **Run the installer**:

   ```
   ./install.sh
   ```

   - Select your distro (1 for Debian/Ubuntu/Mint, 2 for Fedora, 3 for Arch).
   - It updates your system, installs deps, clones the Kokoro model repo, sets up a virtual env, and installs Python packages.
   - If prompted, enter sudo password for package installation.
   - The script makes the main file executable.

3. **Verify Setup**:
   - Test with `source .venv/bin/activate` then `python tts.py --help` to see flags.
   - Run `./tts_clipboard.sh` with text in clipboard.

### Potential Pitfalls During Install

- **Permission Issues**: If sudo fails, ensure your user has sudo rights (`sudo whoami` to test).
- **Missing Repos**: On Ubuntu/Mint, if ffmpeg/espeak-ng fails, enable universe/multiverse repos:
  ```
  sudo add-apt-repository universe
  sudo add-apt-repository multiverse
  sudo apt update
  ```
- **Python Version**: If Python 3.8+ is missing, install manually (e.g., `sudo apt install python3.10` on Ubuntu).
- **Kokoro Clone Fails**: If Hugging Face git clone errors, check internet or run manually: `git clone https://huggingface.co/hexgrad/Kokoro-82M`.
- **YAD/Libnotify Not Found**: On older distros, add PPA: `sudo add-apt-repository ppa:ubuntuhandbook1/yad` (for yad).
- **No GPU Detection**: If slow, install NVIDIA drivers/CUDA: `sudo apt install nvidia-cuda-toolkit` on Ubuntu.
- **Venv Activation**: Always run from the repo dir or activate venv manually if using globally.

## Usage

1. **Copy text to clipboard** (e.g., select text and Ctrl+C).
2. **Run the script**:
   ```
   ./tts_clipboard.sh
   ```
   - YAD dialog pops for speed, voice, save options, filename.
   - Generates chunks, plays audio with controls (notifications for pause/resume/stop).
3. **CLI Save Flag**:
   ```
   ./tts_clipboard.sh -save output.mp3
   ```
   - Overrides dialog for saving, uses default speed/voice unless set.

### Keyboard Controls (During Playback)

- p: Pause
- r: Resume
- s: Stop (skips remaining chunks)

### Saving Audio

- Checkbox in dialog: Save and play, or save only (skips playback).
- Formats: MP3 (libmp3lame), OGG (libvorbis), WAV (copy).
- Default dir: $HOME/Music/Audio (created if missing).
- Filename: First 3 words from text + extension.

## File Overview

- `tts_clipboard.sh`: Main Bash script for clipboard handling, dialog, playback, saving.
- `tts.py`: Python backend for TTS generation (chunking, Kokoro integration).
- `requirements.txt`: Python deps (kokoro, soundfile, numpy, etc.).
- `install.sh`: Automated setup for distros, clones Kokoro model.

## Troubleshooting During Run

- **No Audio**: Check clipboard (xclip -o), Kokoro model downloaded, voice valid (from VOICES.md in Kokoro-82M).
- **Playback Errors**: Ensure ffmpeg/ffplay installed (`ffplay -version`). If "command not found", reinstall ffmpeg.
- **Slow Generation**: Reduce max-words (e.g., 40) for chunks, or use GPU (check torch.cuda.is_available() in Python).
- **Invalid Speed**: Must be a number (e.g., 1.2)—script checks and errors if not.
- **YAD Dialog Fails**: If no yad, install manually (`sudo apt install yad`).
- **Notification Issues**: If buttons don't work, fallback to terminal controls or debug libnotify.
- **Large Text**: Chunks prevent crashes; adjust min/max-words if needed.
- **Custom Voices**: Add to YAD CB field in script (e.g., "af_heart!new_voice").

## Credits

- **Kokoro TTS**: By hexgrad on Hugging Face – [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M).
- **Dependencies**: yad for dialogs, ffmpeg for audio, xclip for clipboard.

## License

MIT License – Feel free to modify and distribute.

---

If you encounter bugs or have suggestions, open an issue on the GitHub repo! Happy TTS-ing! 🎙️
