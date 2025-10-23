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

matplotlib.use('Qt5Agg')

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
    plt.show()

# Example usage:
showPitchOnGraph("nativeSpeaker_iru.mp3", "hafza_iru.mp3")