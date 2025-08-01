#!/bin/bash

# --- Option parsing for -save ---
SAVE_OUTPUT=""
if [[ "$1" == "-save" && -n "$2" ]]; then
    SAVE_OUTPUT="$2"
fi

# Set working directory
cd "$(dirname "$0")" || { notify-send "TTS Error" "Failed to cd to directory"; exit 1; }

# Source the config file for AUDIO_DIR
if [ -f config.sh ]; then
    source config.sh
else
    echo "Warning: config.sh not found. Using default AUDIO_DIR."
    AUDIO_DIR="$(cd "$(dirname "$0")" && pwd)/output"
    mkdir -p "$AUDIO_DIR"
fi

# Activate venv
source .venv/bin/activate || { notify-send "TTS Error" "Failed to activate venv"; exit 1; }

# Get clipboard text
text=$(xclip -o 2>/dev/null)
if [ -z "$text" ]; then
    notify-send "TTS Warning" "No text in clipboard"
    exit 0
fi

# Write to temp file
echo "$text" > temp.txt || { notify-send "TTS Error" "Failed to write temp.txt"; exit 1; }

# Generate default filename from first 3 words of clipboard text
default_filename="$(echo "$text" | tr '\n' ' ' | awk '{print $1"_"$2"_"$3}' | sed 's/[^a-zA-Z0-9_]/_/g').mp3"


form_output=$(yad --form --title="TTS Settings" \
    --field="Speed:" "1.0" \
    --field="Voice:CB" "US-F: af_heart!US-F: af_bella!US-F: af_alloy!US-F: af_aoede!US-F: af_jessica!US-F: af_kore!US-F: af_nicole!US-F: af_nova!US-F: af_river!US-F: af_sarah!US-F: af_sky!US-M: am_adam!US-M: am_eric!US-M: am_echo!US-M: am_fenrir!US-M: am_liam!US-M: am_michael!US-M: am_onyx!US-M: am_puck!US-M: am_santa!UK-F: bf_emma!UK-F: bf_isabella!UK-F: bf_alice!UK-F: bf_lily!UK-M: bm_daniel!UK-M: bm_george!UK-M: bm_fable!UK-M: bm_lewis" \
    --field="Save and play?:CHK" "FALSE" \
    --field="Save only (do not play):CHK" "FALSE" \
    --field="Filename" "$default_filename")
 

if [ $? -ne 0 ]; then
    notify-send "TTS Cancelled" "User cancelled the dialog"
    rm temp.txt  # Cleanup temp file
    exit 0  # User cancelled
fi

speed=$(echo "$form_output" | cut -d'|' -f1)
voice=$(echo "$form_output" | cut -d'|' -f2 | sed 's/^[^:]*: //')
save_to_file=$(echo "$form_output" | cut -d'|' -f3)
save_only=$(echo "$form_output" | cut -d'|' -f4)
filename=$(echo "$form_output" | cut -d'|' -f5)


if ! [[ "$speed" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    notify-send "TTS Error" "Speed must be a number"
    exit 1
fi

if [[ "$save_only" == "TRUE" ]]; then
    save_to_file="TRUE"
fi

# Set SAVE_OUTPUT if checkbox is checked
if [[ "$save_to_file" == "TRUE" ]]; then
    # Ensure the directory exists (already set from config.sh)
    mkdir -p "$AUDIO_DIR"
    SAVE_OUTPUT="$AUDIO_DIR/$filename"
else
    SAVE_OUTPUT=""
fi

# Export for tts.py
export TTS_SPEED="$speed"
export TTS_VOICE="$voice"

# Show generating notification (persistent with -t 0)
notify-send "TTS Generating" "Creating audio, please wait..." -i media-playback-start -t 6000 &

# Run TTS
uv run python tts.py < temp.txt || { notify-send "TTS Error" "Failed to run tts.py"; exit 1; }

# Get audio chunks and sort numerically
audio_files=($(ls -v chunk_*.wav 2>/dev/null))
if [ ${#audio_files[@]} -gt 0 ]; then
    # If -save is given, concatenate chunks and save
    if [ -n "$SAVE_OUTPUT" ]; then
    # Concatenate chunks to a temp WAV first
    TMP_WAV="${SAVE_OUTPUT%.*}.tmp_concat.wav"
    if command -v sox >/dev/null 2>&1; then
        sox "${audio_files[@]}" "$TMP_WAV"
    elif command -v ffmpeg >/dev/null 2>&1; then
        ffmpeg -y -i "concat:$(printf "%s|" "${audio_files[@]}" | sed 's/|$//')" -acodec copy "$TMP_WAV"
    else
        notify-send "TTS Error" "Neither sox nor ffmpeg found for concatenation"
        exit 1
    fi

    # Compress to MP3 or OGG based on extension
    case "${SAVE_OUTPUT##*.}" in
        mp3)
            ffmpeg -y -i "$TMP_WAV" -codec:a libmp3lame -qscale:a 4 "$SAVE_OUTPUT"
            ;;
        ogg)
            ffmpeg -y -i "$TMP_WAV" -codec:a libvorbis -qscale:a 5 "$SAVE_OUTPUT"
            ;;
        wav)
            mv "$TMP_WAV" "$SAVE_OUTPUT"
            ;;
        *)
            # Default to mp3 if unknown extension
            ffmpeg -y -i "$TMP_WAV" -codec:a libmp3lame -qscale:a 4 "${SAVE_OUTPUT%.*}.mp3"
            SAVE_OUTPUT="${SAVE_OUTPUT%.*}.mp3"
            ;;
    esac
    rm -f "$TMP_WAV"
    notify-send "TTS Saved" "Audio saved to $SAVE_OUTPUT"
    if [[ "$save_only" == "TRUE" ]]; then
    rm temp.txt chunk_*.wav
    
    exit 0
    fi
    # Optionally, skip playback if saving only:
    # rm temp.txt chunk_*.wav
    # exit 0
fi

    # Trap Ctrl+C to stop all playback
    trap 'kill -9 $(jobs -p) 2>/dev/null; notify-send "TTS Stopped" "Playback halted"; rm /tmp/tts_pid 2>/dev/null; exit 0' INT

    # Start a persistent notification loop in background
    (
        while true; do
            ACTION=$(notify-send "TTS Playing" "Click to control playback." -i media-playback-start -t 0 --action="Pause=Pause" --action="Resume=Resume" --action="Stop=Stop")
            PID=$(cat /tmp/tts_pid 2>/dev/null)
            case $ACTION in
                Pause) kill -STOP $PID 2>/dev/null ;;
                Resume) kill -CONT $PID 2>/dev/null ;;
                Stop) kill -TERM $PID 2>/dev/null; break ;;
            esac
            if [ "$ACTION" = "Stop" ]; then
                break
            fi
        done
    ) &
    CONTROL_PID=$!

    for file in "${audio_files[@]}"; do
        ffplay -nodisp -autoexit "$file" &  # Hidden playback
        FFPLAY_PID=$!
        echo $FFPLAY_PID > /tmp/tts_pid  # Write PID for action handling

        # Wait for chunk to finish (script progresses automatically)
        wait $FFPLAY_PID || { notify-send "TTS Error" "Failed to play $file"; break; }
    done

    # Kill the control loop to close notification after all chunks
    if kill -0 $CONTROL_PID 2>/dev/null; then
        kill $CONTROL_PID 2>/dev/null
        sleep 0.5  # Short delay to ensure closure
    fi
    rm /tmp/tts_pid 2>/dev/null
else
    notify-send "TTS Error" "No audio chunks generated"
    exit 1
fi



# Cleanup
rm temp.txt chunk_*.wav

# Success notification
notify-send "TTS Success" "Audio played from clipboard" -i media-playback-stop