# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "matplotlib",
#     "praat-parselmouth",
#     "pyqt5",
#     "numpy",
#     "scipy",
# ]
# ///

import numpy as np
import parselmouth
import matplotlib.pyplot as plt
import matplotlib
from scipy.ndimage import gaussian_filter1d
from scipy.signal import savgol_filter

#flask and cors, send_file for images
from flask import Flask, request, send_file, jsonify
from flask_cors import CORS

# for render to use
import static_ffmpeg
static_ffmpeg.add_paths()

#io for saving file in RAM
import io
import os
import tempfile

# converting webM  to wav for site
from pydub import AudioSegment

# for reading and writing audio files
import soundfile as sf

# Ai model
import librosa
import tensorflow as tf
from tensorflow.keras.models import load_model
import tensorflow.keras.backend as K

# googles speech recogn 
import speech_recognition as sr 
# for japanese kanji to romaji
import pykakasi
# for parsing urls 
import urllib.parse 
# font that accepts jp
import matplotlib.font_manager as fm 


# register the custom layer so it can be loaded with the model later without crashing
@tf.keras.utils.register_keras_serializable()
def abs_diff(tensors):
    import tensorflow as tf
    return tf.abs(tensors[0] - tensors[1])

matplotlib.use('Agg')

# font for matplot 
plt.rcParams['font.family'] = ['MS Gothic', 'Meiryo', 'Yu Gothic', 'sans-serif', "Noto Sans CJK JP"] 

app = Flask(__name__)
# This allows your Flutter app from ANY URL to talk to this server
siamese_model = None # global variable to hold the AI model in memory after loading it once

CORS(app, resources={r"/*": {"origins": "*"}}, expose_headers=["X-Transcription", "X-Transcription-Romaji", "X-AI-Score"])

# Load Siamese Machine Learning Model for Audio Comparision
#try:
    #print("Loading Pitch Accent AI...")
    #siamese_model = load_model("pitch_accent_model_final.h5", compile=False) # load only brain and not the training code for faster loading and less memory usage
    #print("Model loaded successfully!")
#except Exception as e:
    #print(f"Error loading model (AI grading disabled): {e}")
    #siamese_model = None


# Process Audio for Siamese model (convert audio to mel spectograms)
def prepare_audio_for_ai(file_path, max_time_steps=100):
    """Converts a WAV file into the 128x100 Mel-Spectrogram the AI expects."""
    y, sr = librosa.load(file_path, sr=None)
    # Crop to 500hz to focus on pitch changes
    mel = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=128, fmin=50, fmax=500)
    mel_db = librosa.power_to_db(mel, ref=np.max)
    
    # Normalize 0 to 1
    mel_min, mel_max = np.min(mel_db), np.max(mel_db)
    mel_db = (mel_db - mel_min) / (mel_max - mel_min) if mel_max != mel_min else mel_db - mel_min
    
    # Pad or trim to exactly 100 frames
    if mel_db.shape[1] < max_time_steps:
        mel_db = np.pad(mel_db, pad_width=((0,0), (0, max_time_steps - mel_db.shape[1])), mode='constant')
    else:
        mel_db = mel_db[:, :max_time_steps]
        
    return mel_db.reshape(1, 128, max_time_steps, 1)

def trim_audio_file(file_path):
    try:
        # Load the audio file
        y, sr = librosa.load(file_path, sr=None)
        
        # Trim the silence (top_db=30 means anything 30 decibels quieter than the loudest sound is cut)
        y_trimmed, index = librosa.effects.trim(y, top_db=30)
        
        # Overwrite the original file with the cleanly trimmed version
        sf.write(file_path, y_trimmed, sr)
        print(f"Trimmed silence from {file_path}")
    except Exception as e:
        print(f"Could not trim {file_path}: {e}")

def moving_average(data, window_size):
    return np.convolve(data, np.ones(window_size)/window_size, mode='same')

def showPitchOnGraph(*audio_files, word_label="Unknown"):
    plt.figure(figsize=(12, 8))
    
    colors = ['blue', 'red', 'green', 'orange', 'purple']
    
    # DTW STORAGE FOR ALIGNMENT
    ref_frequencies = None
    ref_times = None

    for i, audio_file in enumerate(audio_files):
        if not audio_file:
            continue

        try:
            # Load audio
            snd = parselmouth.Sound(audio_file)
            pitch = snd.to_pitch()
            times = pitch.xs()
            frequencies = pitch.selected_array["frequency"]

            # Your original smoothing algorithms
            ma_smoothed = moving_average(frequencies, window_size=8)
            gaussian_smoothed = gaussian_filter1d(frequencies, sigma=2)
            savgol_smoothed = savgol_filter(frequencies, window_length=11, polyorder=2)
            average_smoothed = (ma_smoothed + gaussian_smoothed + savgol_smoothed) / 3

            # DTW ALIGNMENT LOGIC
            if i == 0:
                # Store the Native Speaker as the reference
                ref_frequencies = average_smoothed
                ref_times = times
                
                # Plot the native speaker normally
                display_times = times
                display_freqs = average_smoothed
                display_raw = frequencies
                label = "Native Speaker"
            else:
                # This is "Your Voice" - Align it to the Native Reference
                # Use librosa's DTW to find the "rubber band" path
                # Align the smoothed lines because they are less 'noisy' for the math
                D, wp = librosa.sequence.dtw(X=ref_frequencies, Y=average_smoothed, backtrack=True)
                
                # Create empty arrays to hold the warped (stretched) data
                warped_freqs = np.zeros_like(ref_frequencies)
                warped_raw = np.zeros_like(ref_frequencies)
                
                # Map your voice frames to the native speaker's timeline
                for ref_idx, user_idx in wp:
                    warped_freqs[ref_idx] = average_smoothed[user_idx]
                    warped_raw[ref_idx] = frequencies[user_idx]
                
                # Use the Native's time axis so the lines overlap perfectly
                display_times = ref_times
                display_freqs = warped_freqs
                display_raw = warped_raw
                label = "Your Voice"
            # ---------------------------

            # Plot using the aligned data
            plt.plot(display_times, display_raw, label=f"{label} - Original", alpha=0.3, linewidth=1, color=colors[i])
            plt.plot(display_times, display_freqs, label=f"{label} - Aligned Average", linewidth=2, color=colors[i])

        except Exception as e:
            print(f"Error processing {audio_file}: {e}")
            continue

    plt.xlabel("Time (s) - Aligned to Native")
    plt.ylabel("Frequency (Hz)")
    plt.title("Aligned Pitch Contour Comparison: " + word_label)
    plt.legend()
    plt.grid(True, alpha=0.3)

def get_alignment_score(native_path, user_path):
    try:
        # Load both files
        y_n, sr_n = librosa.load(native_path, sr=None)
        y_u, sr_u = librosa.load(user_path, sr=None)

        # Extract MFCCs (Mel-frequency cepstral coefficients) which are commonly used features for audio comparison
        mfcc_n = librosa.feature.mfcc(y=y_n, sr=sr_n)
        mfcc_u = librosa.feature.mfcc(y=y_u, sr=sr_u)

        # Calculate DTW Distance
        # X is the native (reference), Y is the user (target)
        D, wp = librosa.sequence.dtw(X=mfcc_n, Y=mfcc_u, backtrack=True)
        
        # Normalize the distance (Lower is better)
        # We divide by the length of the warping path so long words aren't penalized
        dist = D[-1, -1] / len(wp)

        # Convert distance to a 0-100 Score
        # (Heuristic: 0-20 is usually a great match, 50+ is poor)
        dtw_score = max(0, 100 - (dist * 1.5)) 
        return dtw_score
    except Exception as e:
        print(f"DTW Failed: {e}")
        return 0
    


#flask app 

#health check
@app.route("/", methods=["GET"])
def health_check():
    return "Pitch Accent API is Live ", 200

@app.route("/process-audio", methods=["POST"])
   
def process_audio():
# Initialize all temp variables to None immediately
    temp_user_webm = None
    temp_user_wav = None
    temp_native_mp3 = None
    temp_native_wav = None # <--- THIS PREVENTS THE "REFERENCED BEFORE ASSIGNMENT" ERROR

    if "files" not in request.files:
        return jsonify({"error": "No audio files"}), 400

    try:
        
        user_file = request.files.getlist("files")[0]
        native_file = request.files.get("native_audio")

        # 1. Save and Convert User Audio
        suffix = os.path.splitext(user_file.filename)[1] or ".webm"
        t_user = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
        user_file.save(t_user.name)
        t_user.close()
        temp_user_webm = t_user.name

        # CONVERT TO WAV using FFmpeg
        temp_user_wav = t_user.name + ".wav"
        try:
            audio = AudioSegment.from_file(temp_user_webm)
            audio.export(temp_user_wav, format="wav")
        except Exception as conv_err:
            print(f"FFmpeg Conversion Failed: {conv_err}")
            # If conversion fails, fallback to using raw file
            temp_user_wav = temp_user_webm 

        # 2. Save Native Audio (if provided by Flutter)
        if native_file:
            t_native = tempfile.NamedTemporaryFile(delete=False, suffix=".mp3")
            native_file.save(t_native.name)
            t_native.close()
            temp_native_mp3 = t_native.name

            # convrt to wav for processing
            temp_native_wav = t_native.name + ".wav"
            try:
                # Convert the Anki MP3 into a WAV file so Parselmouth can read it
                native_audio_seg = AudioSegment.from_file(temp_native_mp3)
                native_audio_seg.export(temp_native_wav, format="wav")
            except Exception as conv_err:
                print(f"FFmpeg Native Conversion Failed: {conv_err}")
                temp_native_wav = temp_native_mp3


        # 3. Google Transcription
        recognizer = sr.Recognizer()
        transcription = "Unknown"
        try:
            with sr.AudioFile(temp_user_wav) as source:
                audio_data = recognizer.record(source)
                transcription = recognizer.recognize_google(audio_data, language="ja-JP")
                print(f"Google heard: {transcription}")

        # more detailed error handling for speech recognition
        except sr.UnknownValueError:
            print("Google Speech: Format is fine, but couldn't recognize any Japanese words.")
            transcription = "Could not understand audio"
        # catch all other exceptions to prevent server crash and provide feedback
        except Exception as sr_err:
            print(f"GOOGLE SPEECH CRASHED: {sr_err}")
            transcription = "Could not understand audio"

        # 4. Kakasi Romaji
        romaji = ""
        try:
            kks = pykakasi.kakasi()
            result = kks.convert(transcription)
            romaji = " ".join([item['hepburn'] for item in result])
        except Exception as kakasi_err:
            print(f"KAKASI ROMAJI CRASHED: {kakasi_err}")
            romaji = "Error"

        # TRIM DEAD AIR AND MIC CLICKS
        if temp_user_wav: trim_audio_file(temp_user_wav)

        # THE SIAMESE AI GRADING BLOCK
        ai_val = 0.0
        final_combined_score = "0.0%"
        if temp_user_wav and temp_native_wav:
            # Get AI Score
            ai_val = 0.0
            if siamese_model:
                u_mat = prepare_audio_for_ai(temp_user_wav)
                n_mat = prepare_audio_for_ai(temp_native_wav)
                prediction = siamese_model.predict([n_mat, u_mat], verbose=0)
                ai_val = float(prediction[0][0] * 100)

            # Get DTW Score [cite: 612-618]
            dtw_val = get_alignment_score(temp_native_wav, temp_user_wav)

            # Weighted Average: 60% DTW (Pattern) + 40% AI (Nuance)
            total = (dtw_val * 0.6) + (ai_val * 0.4)
            final_combined_score = f"{total:.1f}%"
        
        
        print(f"Scores -> AI: {ai_val:.1f} | DTW: {dtw_val:.1f} | Final: {final_combined_score}", flush=True)


        # Generate the Matplotlib Graph
        combined_label = f"{romaji} : {transcription}"
        showPitchOnGraph(temp_native_wav, temp_user_wav, word_label=combined_label)

        img_buffer = io.BytesIO()
        plt.savefig(img_buffer, format="png", dpi=150)
        img_buffer.seek(0)
        plt.close()

        response = send_file(img_buffer, mimetype="image/png")

        # Send headers back to Flutter safely
        response.headers["X-Transcription"] = urllib.parse.quote(str(transcription))
        response.headers["X-Transcription-Romaji"] = urllib.parse.quote(str(romaji))
        response.headers["X-AI-Score"] = urllib.parse.quote(str(final_combined_score)) # Send the AI and DTW combined score as the main feedback, not just the AI score alone
        response.headers["X-AI-Score"] = urllib.parse.quote(str(ai_val))
        response.headers["X-DTW-Score"] = urllib.parse.quote(str(dtw_val))
        return response

    except Exception as e:
        print(f"Server Error: {e}")
        return jsonify({"error": str(e)}), 500
    
    finally:
        # Cleanup all temp files so your server doesn't crash from full memory
        if temp_user_webm and os.path.exists(temp_user_webm): os.remove(temp_user_webm)
        if temp_user_wav and os.path.exists(temp_user_wav): os.remove(temp_user_wav)
        if temp_native_wav and os.path.exists(temp_native_wav): os.remove(temp_native_wav)


print("=======================================")
print("STARTING SERVER BOOTUP SEQUENCE...")
print("=======================================")
try:
    print("Loading Pitch Accent AI...")
    # Make sure you keep your custom_objects fix here!
    siamese_model = load_model("pitch_accent_model.keras", compile=False, safe_mode=False, custom_objects={'K': K})
    print("Model loaded successfully!")
except Exception as e:
    print(f"Error loading model (AI grading disabled): {e}")
    siamese_model = None


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))        
    print("Starting Flask web server...")
    app.run(host="0.0.0.0", port=port)