from kokoro import KPipeline
import soundfile as sf
import sys
import re  # For sentence splitting
import numpy as np  # For audio concatenation
import os  # For environment variables

# Initialize the pipeline (using 'a' for American English)
pipeline = KPipeline(lang_code='a')

# Speed control: 1.0 default, >1 faster (e.g., 1.2), <1 slower (e.g., 0.8)
speed = float(os.environ.get('TTS_SPEED', 1.0))  # Read from env, default 1.0

# Read from stdin if provided, otherwise use default text
if sys.stdin.isatty():  # No input piped/redirected, use default text
    text = "Hello, this is a test of Kokoro TTS reading Grok's response."
else:  # Read from stdin
    text = sys.stdin.read().strip()

# Split text into sentences using re (basic regex for periods, handling abbreviations minimally)
sentences = re.split(r'(?<=\.) ', text)  # Split after '.' followed by space

# Build chunks: Prefer sentence breaks, but group to meet min 20 / max 60 words
chunks = []
current_chunk = ""
current_words = 0
min_words = 20
max_words = 60

for sentence in sentences:
    sentence_words = len(sentence.split())
    if current_words + sentence_words > max_words and current_words >= min_words:
        # End current chunk if over max and at min
        chunks.append(current_chunk.strip())
        current_chunk = sentence
        current_words = sentence_words
    else:
        # Add to current
        current_chunk += sentence + " "
        current_words += sentence_words

# Add any remaining chunk if it meets min (or force if last)
if current_chunk.strip() and (current_words >= min_words or not chunks):
    chunks.append(current_chunk.strip())
elif current_chunk.strip():  # If under min, append to last chunk
    if chunks:
        chunks[-1] += " " + current_chunk.strip()

# If no natural breaks, fall back to hard word split (rare)
if not chunks:
    words = text.split()
    chunks = [' '.join(words[i:i + max_words]) for i in range(0, len(words), max_words)]

# Process each chunk
audio_files = []
for i, chunk_text in enumerate(chunks):
    if not chunk_text.strip():
        continue
    voice = os.environ.get('TTS_VOICE', 'af_heart')  # Read voice from env, default 'af_heart'
    generator = pipeline(chunk_text, voice=voice, speed=speed)  # Pass speed here
    audio_chunks = []
    for j, (gs, ps, audio) in enumerate(generator):
        print(f"Chunk {i}.{j}: {gs}, {ps}")
        # Ensure audio is a numpy array (in case it's a list or tensor)
        if not isinstance(audio, np.ndarray):
            audio = np.array(audio)
        audio_chunks.append(audio)
    if audio_chunks:
        # Concatenate audio segments
        full_audio = np.concatenate(audio_chunks) if len(audio_chunks) > 1 else audio_chunks[0]
        output_file = f"chunk_{i}.wav"
        sf.write(output_file, full_audio, 24000)
        audio_files.append(output_file)
        print(f"Audio chunk saved as {output_file}")

# Exit if no audio
if not audio_files:
    print("No audio generated—check text/voice.")
    sys.exit(1)