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

# googles speech recogn 
import speech_recognition as sr 
# for japanese kanji to romaji
import pykakasi
# for parsing urls 
import urllib.parse 
# font that accepts jp
import matplotlib.font_manager as fm 

matplotlib.use('Agg')

# font for matplot 
plt.rcParams['font.family'] = ['Noto Sans CJK JP', 'sans-serif']

app = Flask(__name__)
# This allows your Flutter app from ANY URL to talk to this server
CORS(app, resources={r"/*": {"origins": "*"}}, expose_headers=["X-Transcription", "X-Transcription-Romaji"])

def moving_average(data, window_size):
    return np.convolve(data, np.ones(window_size)/window_size, mode='same')

def showPitchOnGraph(audio_path, word_label="Unknown"):
    # Create plot
    plt.figure(figsize=(12, 8))
    
    line_colour = 'blue'
    try:
        #load audio
        snd = parselmouth.Sound(audio_path)

        #extract the pitch
        pitch = snd.to_pitch()
        times = pitch.xs()
        frequencies = pitch.selected_array["frequency"]

        #different smoothing algorithms,
        #ma_smoothed = moving_average(frequencies, window_size=8)  # Moving Average
        #gaussian_smoothed = gaussian_filter1d(frequencies, sigma=2)  # Gaussian Smoothing
        #savgol_smoothed = savgol_filter(frequencies, window_length=11, polyorder=2)  # Savitzky-Golay
        #average_smoothed = (ma_smoothed + gaussian_smoothed + savgol_smoothed) / 3

        # Basic plotting if smoothing fails or just simply plot
        label = audio_path.split('/')[-1]
        plt.plot(times, frequencies, label=f"{label}", linewidth=2, color=line_colour)

        #Get filename for label
        label = audio_path.split('/')[-1]  #just name

        # Plot
        plt.plot(times, frequencies, label=f"{label} - Original", alpha=0.3, linewidth=1, color=line_colour)
        #plt.plot(times, average_smoothed, label=f"{label} - Average", linewidth=2, color=line_colour)

    except Exception as e:
        print(f"Error processing {audio_path}: {e}")
    
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
    file = request.files.getlist("files")[0]
    print("files recieved")

    # Save audio temporarily for before and after conversion
    temp_webm = None
    temp_wav = None

    try:
        # save Upload
        # delete=False so parselmouth can open it by path
        suffix = os.path.splitext(file.filename)[1] or ".webm"
        t = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
        file.save(t.name)
        t.close()
        temp_webm = t.name

        # check if file is empty 
        file_size = os.path.getsize(temp_webm)
        print(f"Received file: {temp_webm}, Size: {file_size} bytes")

        # CONVERT TO WAV using FFmpeg
        # This turns the WebM into a standard WAV
        temp_wav = t.name + ".wav"
        
        # Try converting 
        try:
            audio = AudioSegment.from_file(temp_webm)
            audio.export(temp_wav, format="wav")
        except Exception as conv_err:
            print(f"FFmpeg Conversion Failed: {conv_err}")
            # If Flutter sent a WAV but named it WebM, try simple rename
            if file_size > 0:
                print("Attempting to use raw file...")
                temp_wav = temp_webm 
            else:
                raise conv_err

        # Google Transcription 
        recognizer = sr.Recognizer()
        transcription = "Unknown"

        try:
            with sr.AudioFile(temp_wav) as source:
                audio_data = recognizer.record(source)
                # 'ja-JP' tells Google to listen for Japanese
                transcription = recognizer.recognize_google(audio_data, language="ja-JP")
                print(f"Recognized: {transcription}")
        except sr.UnknownValueError:
            transcription = "Could not understand audio"
        except sr.RequestError as e:
            transcription = f"API Error: {e}"

        
        # Convert to romaji 
        romaji = ""
        try:
            kks = pykakasi.kakasi()
            result = kks.convert(transcription)
            # Join the 'hepburn' reading of each word
            romaji = " ".join([item['hepburn'] for item in result])
            print(f"Romaji: {romaji}")
        except Exception as e:
            print(f"Romaji Error: {e}")
            romaji = "Error"

        
        # Run analysis
        combined_label  = f"{romaji} : {transcription}"
        showPitchOnGraph(temp_wav, combined_label)

        img_buffer = io.BytesIO()
        plt.savefig(img_buffer, format="png", dpi=150)
        img_buffer.seek(0)
        plt.close()

        # Send respone back in url
        response = send_file(img_buffer, mimetype="image/png")

        # URL Encode the Japanese text so headers don't break
        # Example: '猫' becomes '%E7%8C%AB'
        response.headers["X-Transcription"] = urllib.parse.quote(transcription)
        response.headers["X-Transcription-Romaji"] = urllib.parse.quote(romaji)
        
        return response

    except Exception as e:
        print(f"Server Error: {e}")
        return jsonify({"error": str(e)}), 500
    
    finally:
        # Cleanup
        if temp_webm and os.path.exists(temp_webm): os.remove(temp_webm)
        if temp_wav and os.path.exists(temp_wav): os.remove(temp_wav)
        

if __name__ == "__main__":
    # Render provides the PORT variable
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)