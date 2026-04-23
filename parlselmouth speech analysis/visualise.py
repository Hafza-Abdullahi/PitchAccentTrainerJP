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

#io for saving file in RAM
import io
import os
import tempfile

# converting webM  to wav for site
from pydub import AudioSegment

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
plt.rcParams['font.family'] = ['MS Gothic', 'Meiryo', 'Yu Gothic', 'sans-serif']

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


def moving_average(data, window_size):
    return np.convolve(data, np.ones(window_size)/window_size, mode='same')

def showPitchOnGraph(*audio_files, word_label="Unknown"):
    # Create plot
    plt.figure(figsize=(12, 8))
    
    colors = ['blue', 'red', 'green', 'orange', 'purple']  #Diff colours for eahc file
    for i, audio_file in enumerate(audio_files):
            # Incase of empty file, skip
            if not audio_file:
                continue

            try:

                #load audio
                snd = parselmouth.Sound(audio_file)

                #extract the pitch
                pitch = snd.to_pitch()
                times = pitch.xs()
                frequencies = pitch.selected_array["frequency"]

                #different smoothing algorithms,
                ma_smoothed = moving_average(frequencies, window_size=8)  # Moving Average
                gaussian_smoothed = gaussian_filter1d(frequencies, sigma=2)  # Gaussian Smoothing
                savgol_smoothed = savgol_filter(frequencies, window_length=11, polyorder=2)  # Savitzky-Golay
                average_smoothed = (ma_smoothed + gaussian_smoothed + savgol_smoothed) / 3

            except Exception as e:
                print(f"Error processing {audio_file}: {e}")

            # Force clean names based on the order the files were passed in
            if i == 0:
                label = "Native Speaker"
            else:
                label = "Your Voice"

            # Plot
            plt.plot(times, frequencies, label=f"{label} - Original", alpha=0.3, linewidth=1, color=colors[i])
            plt.plot(times, average_smoothed, label=f"{label} - Average", linewidth=2, color=colors[i])
        
            plt.xlabel("Time (s)")
            plt.ylabel("Frequency (Hz)")
            plt.title("Pitch Contour Comparison for " + word_label)
            plt.legend()
            plt.grid(True, alpha=0.3)

    


#flask app 

#health check
@app.route("/", methods=["GET"])
def health_check():
    return "Pitch Accent API is Live ", 200

@app.route("/process-audio", methods=["POST"])
def process_audio():
    if "files" not in request.files:
        return jsonify({"error": "No audio files uploaded"}), 400

    # Grab the audio file
    user_file = request.files.getlist("files")[0]
    native_file = request.files.get("native_audio") # The anki Audio
    print("files recieved")

    # Save audio temporarily for before and after conversion
    temp_user_webm = None
    temp_user_wav = None
    temp_native_mp3 = None

    try:
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

        # THE SIAMESE AI GRADING BLOCK
        ai_score = "N/A"
        if siamese_model and temp_native_mp3:
            try:
                # Turn both audios into 128x100 pictures
                user_matrix = prepare_audio_for_ai(temp_user_wav)
                native_matrix = prepare_audio_for_ai(temp_native_mp3)
                
                # Ask the twin brains to compare them
                prediction = siamese_model.predict([native_matrix, user_matrix], verbose=0)
                
                # Convert the raw decimal to a percentage
                confidence = prediction[0][0] * 100
                ai_score = f"{confidence:.1f}%"
                print(f"AI Match Score: {ai_score}")
            except Exception as ai_err:
                print(f"AI Grading Failed: {ai_err}")
                ai_score = "Error"

        # Generate the Matplotlib Graph
        combined_label = f"{romaji} : {transcription}"
        showPitchOnGraph(temp_native_mp3, temp_user_wav, word_label=combined_label)

        img_buffer = io.BytesIO()
        plt.savefig(img_buffer, format="png", dpi=150)
        img_buffer.seek(0)
        plt.close()

        response = send_file(img_buffer, mimetype="image/png")

        # Send headers back to Flutter
        response.headers["X-Transcription"] = urllib.parse.quote(transcription)
        response.headers["X-Transcription-Romaji"] = urllib.parse.quote(romaji)
        response.headers["X-AI-Score"] = urllib.parse.quote(ai_score) # Send the AI grade!
        
        return response

    except Exception as e:
        print(f"Server Error: {e}")
        return jsonify({"error": str(e)}), 500
    
    finally:
        # Cleanup all temp files so your server doesn't crash from full memory
        if temp_user_webm and os.path.exists(temp_user_webm): os.remove(temp_user_webm)
        if temp_user_wav and os.path.exists(temp_user_wav): os.remove(temp_user_wav)
        if temp_native_mp3 and os.path.exists(temp_native_mp3): os.remove(temp_native_mp3)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    # Load the AI Model right before starting the server
    print("=======================================")
    print("STARTING SERVER BOOTUP SEQUENCE...")
    print("=======================================")
    try:
        print("Loading Pitch Accent AI...")
        siamese_model = load_model("pitch_accent_model.keras", compile=False, safe_mode=False, custom_objects={'K': K})# load only brain and not the training code for faster loading and less memory usage
        print("Model loaded successfully!")
    except Exception as e:
        print(f"Error loading model (AI grading disabled): {e}")
        siamese_model = None
        
    print("Starting Flask web server...")

    app.run(host="0.0.0.0", port=port)