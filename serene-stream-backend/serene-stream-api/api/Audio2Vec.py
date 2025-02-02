import numpy as np
import wave
import tempfile

# Normalization function for the embedding
def normalize(v):
    norm = np.linalg.norm(v)
    return v if norm == 0 else v / norm


def get_embedding(audio_file):
    return np.random.uniform(-1, 1, 12)
    model = vosk.Model(model_name="vosk-model-small-en-us-0.15")
    wf = wave.open(audio_file, "rb")
    rec = vosk.KaldiRecognizer(model, wf.getframerate())
    while True:
        data = wf.readframes(4000)
        if len(data) == 0:
            break
        if rec.AcceptWaveform(data):
            result = rec.Result()
            return result


# Function to calculate the dot product similarity between two embeddings
def evaluator(audio_1, audio_2):
    with (tempfile.NamedTemporaryFile(suffix=".wav") as temp_audio_1, 
        tempfile.NamedTemporaryFile(suffix=".wav") as temp_audio_2):
        #temp_audio_1.write(AudioProcessor.mp3_to_wav(audio_1))
        #temp_audio_2.write(AudioProcessor.mp3_to_wav(audio_2))

        embedding1 = get_embedding(temp_audio_1.name)
        embedding2 = get_embedding(temp_audio_2.name)

    if embedding1 is None or embedding2 is None:
        print("Error in getting embeddings.")
        return None

    # Compute the dot product of the two embeddings
    similarity = float(np.dot(embedding1, embedding2))
    return similarity
