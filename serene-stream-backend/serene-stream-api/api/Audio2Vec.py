import numpy as np
import io
from speechbrain.pretrained import EncoderClassifier
import soundfile as sf

# Load the pre-trained model for speaker embeddings from SpeechBrain
classifier = EncoderClassifier.from_hparams(source="speechbrain/spkrec-ecapa-voxceleb")

# Normalization function for the embedding
def normalize(v):
    norm = np.linalg.norm(v)
    return v if norm == 0 else v / norm

# Function to decode MP3 bytes to waveform and sample rate using torchaudio
def decode_mp3(mp3_bytes):
    """Decode MP3 audio bytes to waveform and sample rate using torchaudio."""
    mp3_buff = io.BytesIO(mp3_bytes)
    mp3_buff.name = 'file.mp3'
    data, samplerate = sf.read(mp3_buff)
    return data, samplerate

# Function to get an embedding of an audio file using SpeechBrain
def get_embedding(audio_file):  # Takes in mp3 file bytes
    try:
        # Decode the MP3 bytes into waveform and sample rate
        waveform, sample_rate = decode_mp3(audio_file)
        
        # Get the speaker embeddings from the classifier model
        embeddings = classifier.encode_batch(waveform)
        flattened_embedding = embeddings.reshape(1, -1)
        
        # Normalize the embedding vector
        normalized_v = normalize(flattened_embedding.squeeze().numpy())
        return normalized_v
    except Exception as e:
        print(f"Error processing audio file: {audio_file}. Error: {e}")
        return None

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
