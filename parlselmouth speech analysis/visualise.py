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

matplotlib.use('Agg')  #disable qt5gg for the server

app = Flask(__name__)
# This allows your Flutter app from ANY URL to talk to this server
CORS(app, resources={r"/*": {"origins": "*"}})

def moving_average(data, window_size):
    return np.convolve(data, np.ones(window_size)/window_size, mode='same')

def showPitchOnGraph(*audio_files):
    # Create plot
    plt.figure(figsize=(12, 8))
    
    colors = ['blue', 'red', 'green', 'orange', 'purple']  #Diff colours for eahc file
    for i, audio_file in enumerate(audio_files):
        try:
            #load audio
            snd = parselmouth.Sound(audio_file)

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
            label = audio_file.split('/')[-1]
            plt.plot(times, frequencies, label=f"{label}", linewidth=2, color=colors[i % len(colors)])

            #Get filename for label
            label = audio_file.split('/')[-1]  #just name

            # Plot
            plt.plot(times, frequencies, label=f"{label} - Original", alpha=0.3, linewidth=1, color=colors[i])
            #plt.plot(times, average_smoothed, label=f"{label} - Average", linewidth=2, color=colors[i])

        except Exception as e:
            print(f"Error processing {audio_file}: {e}")
    
    plt.xlabel("Time (s)")
    plt.ylabel("Frequency (Hz)")
    plt.title("Pitch Contour Comparison")
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

    files = request.files.getlist("files")

    # Save all uploaded audio files to the system's temporary directory
    temp_files = []

    try:
        for f in files:
            # delete=False so parselmouth can open it by path
            suffix = os.path.splitext(f.filename)[1] or ".webm"
            t = tempfile.NamedTemporaryFile(delete=False, suffix=suffix)
            f.save(t.name)
            t.close() # Close so other processes can read it
            temp_files.append(t.name)

        # Run analysis
        showPitchOnGraph(*temp_files)

        img_buffer = io.BytesIO()
        plt.savefig(img_buffer, format="png", dpi=150)
        img_buffer.seek(0)
        plt.close()

        # Cleanup temp files
        for tf in temp_files:
            try:
                os.remove(tf)
            except:
                pass

        return send_file(img_buffer, mimetype="image/png")

    except Exception as e:
        print(f"Server Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # Render provides the PORT variable
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port)