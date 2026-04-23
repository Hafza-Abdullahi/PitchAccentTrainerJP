import requests
import urllib.parse

# URL of your local Flask server
URL = "http://127.0.0.1:5000/process-audio"

# Map the files to the exact keys your Flask app expects!
# Make sure these audio files are actually in the same folder as this script.
files = {
    "files": ("parlselmouth speech analysis/hafza_iru.wav", open("parlselmouth speech analysis/hafza_iru.wav", "rb"), "audio/mpeg"),
    "native_audio": ("parlselmouth speech analysis/nativeSpeaker_iru.wav", open("parlselmouth speech analysis/nativeSpeaker_iru.wav", "rb"), "audio/mpeg")
}
print("Sending audio to local Flask server...")

try:
    response = requests.post(URL, files=files)
    print("Status:", response.status_code)

    if response.status_code == 200:
        # 1. Save the returned spectrogram image
        with open("result.png", "wb") as f:
            f.write(response.content)
        print("✅ Saved output graph as result.png")
        
        # 2. Print the headers containing the AI Grade and Transcriptions
        print("\n--- Grading Results ---")
        transcription = urllib.parse.unquote(response.headers.get("X-Transcription", "Not Found"))
        romaji = urllib.parse.unquote(response.headers.get("X-Transcription-Romaji", "Not Found"))
        ai_score = urllib.parse.unquote(response.headers.get("X-AI-Score", "Not Found"))
        
        print(f"Transcription: {transcription}")
        print(f"Romaji:        {romaji}")
        print(f"AI Match Score: {ai_score}")
        
    else:
        print("❌ Error response:", response.text)

finally:
    # Always close your files! The file object is the second item [1] in the tuple.
    files["files"][1].close()
    files["native_audio"][1].close()