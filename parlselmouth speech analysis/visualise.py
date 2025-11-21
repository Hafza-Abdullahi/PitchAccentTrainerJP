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
CORS(app)

def moving_average(data, window_size):
    return np.convolve(data, np.ones(window_size)/window_size, mode='same')

def showPitchOnGraph(*audio_files):
    # Create plot
    plt.figure(figsize=(12, 8))
    
    colors = ['blue', 'red', 'green', 'orange', 'purple']  #Diff colours for eahc file
    for i, audio_file in enumerate(audio_files):
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

        #Get filename for label
        label = audio_file.split('/')[-1]  #just name

        # Plot
        plt.plot(times, frequencies, label=f"{label} - Original", alpha=0.3, linewidth=1, color=colors[i])
        plt.plot(times, average_smoothed, label=f"{label} - Average", linewidth=2, color=colors[i])
    
    plt.xlabel("Time (s)")
    plt.ylabel("Frequency (Hz)")
    plt.title("Pitch Contour Comparison")
    plt.legend()
    plt.grid(True, alpha=0.3)


#flask app 

@app.route("/process-audio", methods=["POST"])
def process_audio():
    """
    Accepts audio files from Flutter.
    Runs showPitchOnGraph() using your code.
    Returns the generated pitch graph as a PNG image.
    """

    if "files" not in request.files:
        return jsonify({"error": "No audio files uploaded"}), 400

    files = request.files.getlist("files")

    # Save all uploaded audio files to temp directory
    #
    temp_files = []
    for f in files:
        temp_path = os.path.join(tempfile.gettempdir(), f.filename)
        f.save(temp_path)
        temp_files.append(temp_path)

    # Run your original function
    showPitchOnGraph(*temp_files)

    #save plot to png instead og displaying gui
    img_buffer = io.BytesIO()
    plt.savefig(img_buffer, format="png", dpi=150)
    img_buffer.seek(0)

    #clear the figure 
    plt.close()

    #return img
    return send_file(img_buffer, mimetype="image/png")


#running the server 

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
