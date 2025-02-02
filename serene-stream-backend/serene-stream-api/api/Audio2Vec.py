import numpy as np
import io
import torchaudio
import vosk
import wave

# Normalization function for the embedding
def normalize(v):
    norm = np.linalg.norm(v)
    return v if norm == 0 else v / norm

# Function to decode MP3 bytes to waveform and sample rate using torchaudio
def decode_mp3(mp3_bytes):
    """Decode MP3 audio bytes to waveform and sample rate using torchaudio."""
    audio_data = io.BytesIO(mp3_bytes)  # Convert bytes into file-like object
    waveform, sample_rate = torchaudio.load(audio_data, format="mp3")  # Use torchaudio to load the mp3 data
    return waveform, sample_rate


def get_embedding(audio_file):
    model = vosk.Model("../vosk-model-small-en-us-0.15")
    wf = wave.open(audio_file, "rb")
    rec = vosk.KaldiRecognizer(model, wf.getframerate())
    while True:
        data = wf.readframes(4000)
        if len(data) == 0:
            break
        if rec.AcceptWaveform(data):
            result = rec.Result()
            print(result)


# Function to calculate the dot product similarity between two embeddings
def evaluator(audio_1, audio_2):
    embedding1 = get_embedding(audio_1)
    embedding2 = get_embedding(audio_2)

    if embedding1 is None or embedding2 is None:
        print("Error in getting embeddings.")
        return None

    # Compute the dot product of the two embeddings
    similarity = float(np.dot(embedding1, embedding2))
    return similarity
