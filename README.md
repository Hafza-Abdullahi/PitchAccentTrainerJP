## 🌐 Project Webpage

[https://pitchaccentapp.web.app/](https://pitchaccentapp.web.app/)

-----

## The Problem: The Ignored Part of Japanese

Most language learning apps (and learners) completely overlook Japanese pitch accent. Japanese isn't a tonal language like Mandarin, but it uses a high/low pitch system where the melody of a word changes its entire meaning. For example, *Hashi* can mean "Bridge" or "Chopsticks" entirely depending on where your pitch drops.

<img width="430" height="242" alt="image" src="https://github.com/user-attachments/assets/7d544672-eec9-4fe1-b777-ed156bfa5a34" />

  * **Heiban (Flat):** Low -\> High -\> Stays High.
  * **Atamadaka (Head-High):** High -\> Drops immediately. 
  * **Nakadaka (Middle-High):** Low -\> High -\> Low. 

Standard voice-recognition models are only built to listen for vowels and consonants. If you say a word with a completely flat, robotic, or incorrect pitch, standard apps will still give you a 100% score. This project builds a custom AI to actually hear and score the *melody*.

## The Audio Dataset

### Why I Dropped "Odaka" (Tail-High)

Japanese has a 4th pitch accent: Odaka. I removed this from the data collection step

**The reason:** Odaka words stay high and only drop on the *particle* attached after the word (like *ga* or *wa*). Since our app tests users on **bare dictionary words**, a bare Odaka word physically sounds 100% identical to a Heiban word (Low -\> High).

If I included Odaka, it would just confuse the model since its the same pattern as Heiban without a particle.

-----

## Building a Model to "Hear" Pitch Accents

To fix this, we have to teach a computer to hear sound the exact same way a human does.

A normal audio spectrogram maps out frequency, amplitude, and time in a perfectly linear way. But **human hearing is logarithmic, not linear.** \* **Example:** To a human, hearing the difference between the low notes C2 and C4 (65Hz - 262Hz) is pretty obvious. But hearing the difference between the high notes G6 and A6 (1568Hz - 1760Hz) is really difficult.

**The Fix: Mel-Spectrograms**
Instead of feeding the AI raw audio, we convert the audio into Mel-Spectrograms. These are visual heatmaps that warp the frequencies to match human perception. It isolates the pitch contour so the AI can physically "see" the melody of the word through time.

-----

| Heiban (Flat) | Nakadaka (Middle-High) | Atamadaka (Head-High) |
| :---: | :---: | :---: |
| <img alt="Heiban" src="https://github.com/user-attachments/assets/d916f60b-e6bc-41ec-9906-af881de2e6c1" width="100%" />| <img alt="Nakadaka" src="https://github.com/user-attachments/assets/426c713e-ea5f-4680-af34-4c34bc279ff9" width="100%"/>| <img alt="Atamadaka" src="https://github.com/user-attachments/assets/5fbd356f-eec3-4348-a536-7cd83d71a516" width="100%" />|

-----

## The AI Model: Siamese Neural Network

This model will have to "Spot the Difference" using a Siamese Neural Network.

**How it will be trained:**

1.  Feed the model N samples of the **Heiban** (Flat) pitch pattern. This consists of N/2 completely different words, spoken by both male and female native speakers.
2.  Tell the model: *"Even though the vowels and consonants are different, the underlying melody of these files is exactly the same."*
3.  Repeat this process for the **Nakadaka** (Middle-Drop) and **Atamadaka** (Head-Drop) patterns.

Because the words are different but the pitch is the same, the AI is forced to ignore the letters and become better at recognizing the pure pitch shapes.

-----

## Model Performance & Training Data

To ensure the AI learned the abstract concept of pitch rather than just memorizing specific voices, the model was trained using a balanced dataset of **900 native audio samples** (300 per pitch category) with a strict isolation strategy.

### Training Strategy: The 80/20 Split (Testing/Unseen Data Split)

### Dataset Breakdown
| Data Category | Total Pairs | Source Material |
| :--- | :--- | :--- |
| **Training Set** | **1,000 Pairs** | 720 Raw Files (80%) |
| **Validation Set** | **200 Pairs** | 180 Raw Files (20%) |
| **Total Exposure** | **1,200 Comparisons** | 30 Epochs (Rounds) |

### Learning Curves
The graphs below show the AI's progress. The **~88-90% Validation Accuracy** shows that the model successfully generalized the concepts of Heiban, Atamadaka, and Nakadaka.

<img width="1258" height="437" alt="AI Training Graphs" src="https://github.com/user-attachments/assets/3dfd12ed-e627-4379-bc13-1c37b08fef8f" />

---

### Why 1,000 pairs from only 720 files?
By using a **Siamese Architecture**, we can generate multiple unique combinations from the same files (e.g., Word A + Word B, Word B + Word C). This acts as a form of **Data Augmentation**, forcing the AI to see the same "Heiban" pattern across hundreds of different word-pair combinations. This teaches the network to ignore the consonants and focus entirely on the pitch contour.

---

## The Goal

When a non-native user speaks into the app, the model will compare their audio directly against a correct speaker saying the exact same word. Because the AI will understand pitch contours, it will accurately score how well the user matched the correct pitch accent, rather than just checking if they pronounced the right letters.

-----

## 🛠️ Features & Development Roadmap

### ✅ Completed
* **Automated Data Sourcing:** Built a custom web scraper to pull base-dictionary words and native audio from the **Online Japanese Accent Dictionary (OJAD)**.
* **Sample Balancing System:** Implemented a logic gate to ensure exactly 300 files per pitch category, preventing the AI from developing a "majority bias."
* **Audio Pre-Processing:** Created a pipeline to convert raw `.mp3` files into mathematical `.npy` Mel-Spectrogram matrices with a **500Hz Band-Pass filter**.
* **Visual Spectrogram Generator:** Developed a debugger that converts raw math matrices back into PNG heatmaps to visually verify pitch patterns.
* **Siamese Model Training:** Successfully trained a Siamese Neural Network on 1,000+ audio pairs, achieving **~88% validation accuracy** on unseen voices.
* **Cross-Platform UI:** Developed with **Flutter and Dart** to provide high-performance, real-time visual feedback of pitch contours.
* **AnkiConnect API Integration:** Leverages the **AnkiConnect API** to allow users to sync their personal vocabulary decks directly from Anki into the trainer.
* **Automated Asset Serialization:** A custom system that retrieves Anki media files (via base64) and serializes metadata into JSON for optimized local performance.
* **Linguistic Foundations:** Combines Japanese phonetics with **Spaced Repetition (SRS)** logic to ensure long-term retention of pitch patterns.

### 🚧 To Do / In Progress

#### **Siamese Model Integration**
* **AI Integration:** Moving the trained `.h5` model into the production server so it can grade user audio on the fly.
* **Mora-Count Logic:** Implementing a dynamic "Template Vault" that selects the correct native reference based on the number of beats (morae) detected in the user's speech to use as a comparison for the Siamese model input.

#### **Frontend & UX**
* **Model-to-UI Connection:** Connecting the Flutter frontend to the Flask API to display "Match Percentage" scores to the user.
* **Google Authentication:** Implementing Firebase/Google Sign-in so users can track their progress and saved words.
* **UI Polish:** Cleaning up the interface to move from a "Developer Tool" to a consumer-ready language app.

#### **Future Research**
* **Pure Contour Training:** Investigating a "V2" model trained strictly on **F0 Pitch Contours** (line graphs) rather than Mel-Spectrograms (heatmaps) to see if removing all background noise increases accuracy further.

---
