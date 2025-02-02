from pydub import AudioSegment
import io
import math
from typing import List, Tuple
import os
import soundfile as sf

class AudioProcessor:
    #TARGET_DURATION_MS = 120000  # 2 minutes in milliseconds
    TARGET_DURATION_MS = 30000

    @staticmethod
    def load_audio_from_bytes(audio_bytes: bytes) -> AudioSegment:
        """Load audio from bytes into a PyDub AudioSegment."""
        return AudioSegment.from_wav(io.BytesIO(audio_bytes))

    @staticmethod
    def mp3_to_wav(mp3_bytes: bytes):
        mp3_buff = io.BytesIO(mp3_bytes)
        mp3_buff.name = 'file.mp3'
        data, samplerate = sf.read(mp3_buff)
        wav_buf = io.BytesIO()
        wav_buf.name = 'file.wav'
        sf.write(wav_buf, data, samplerate)
        wav_buf.seek(0)  # Necessary for `.read()` to return all bytes
        return wav_buf.read()

    @staticmethod
    def flac_to_wav(flac_bytes: bytes):
        flac_buff = io.BytesIO(flac_bytes)
        flac_buff.name = 'file.flac'
        data, samplerate = sf.read(flac_buff)
        wav_buf = io.BytesIO()
        wav_buf.name = 'file.wav'
        sf.write(wav_buf, data, samplerate)
        wav_buf.seek(0)  # Necessary for `.read()` to return all bytes
        return wav_buf.read()

    @staticmethod
    def wav_to_mp3(wav_bytes: bytes):
        wav_buff = io.BytesIO(wav_bytes)
        wav_buff.name = 'file.wav'
        data, samplerate = sf.read(wav_buff)
        mp3_buf = io.BytesIO()
        mp3_buf.name = 'file.mp3'
        sf.write(mp3_buf, data, samplerate)
        mp3_buf.seek(0)
        return mp3_buf.read()

    @staticmethod
    def process_audio_segment(audio: AudioSegment) -> AudioSegment:
        """Process a single audio segment to match target duration."""
        if len(audio) > AudioProcessor.TARGET_DURATION_MS:
            # Cut to 2 minutes
            return audio[:AudioProcessor.TARGET_DURATION_MS]
        elif len(audio) < AudioProcessor.TARGET_DURATION_MS:
            # Calculate how many times we need to loop
            repeat_count = math.ceil(AudioProcessor.TARGET_DURATION_MS / len(audio))
            # Loop and then cut to exact duration
            return (audio * repeat_count)[:AudioProcessor.TARGET_DURATION_MS]
        return audio

    @classmethod
    def combine_audio_files(cls, audio_files: List[Tuple[bytes, str]]) -> bytes:
        """
        Combine multiple audio files into a single 2-minute track.

        Args:
            audio_files: List of tuples containing (file_bytes, filename)

        Returns:
            bytes: The processed and combined audio file in WAV format
        """
        if not audio_files:
            raise ValueError("No audio files provided")

        # Convert all files to AudioSegments and process them
        processed_segments = [
            cls.process_audio_segment(cls.load_audio_from_bytes(file_bytes))
            for file_bytes, _ in audio_files
        ]

        # Overlay all segments
        combined = processed_segments[0]
        for segment in processed_segments[1:]:
            combined = combined.overlay(segment)

        # Export to WAV
        output = io.BytesIO()
        combined.export(output, format="wav")
        return output.getvalue()