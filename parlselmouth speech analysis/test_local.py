import requests

# URL of your local Flask server
URL = "http://127.0.0.1:5000/process-audio"

# Audio files to send
files = [
    ("files", open("nativeSpeaker_iru.mp3", "rb")),
    ("files", open("highLow_iru.mp3", "rb")),
]

print("Sending audio to Flask server...")

response = requests.post(URL, files=files)

print("Status:", response.status_code)

if response.status_code == 200:
    with open("result.png", "wb") as f:
        f.write(response.content)
    print("Saved output image as result.png")
else:
    print("Error response:", response.text)
