## 🌐 Project Webpage

[https://pitchaccentapp.web.app/](https://pitchaccentapp.web.app/)

-----

## The Problem: The Ignored Half of Japanese

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

## The Goal

When a non-native user speaks into the app, the model will compare their audio directly against a correct speaker saying the exact same word. Because the AI will understand pitch contours, it will accurately score how well the user matched the correct pitch accent, rather than just checking if they pronounced the right letters.

-----

## Features Implemented So Far

  * **Automated Data Sourcing:** A custom web scraper that pulls base-dictionary words from the Online Japanese Accent Dictionary (OJAD).
  * **Sample Balancing System:** Ensures exactly N files per pitch category to prevent AI bias.
  * **Audio Pre-Processing:** Automatically converts raw `.mp3` files into mathematical `.npy` Mel-Spectrogram matrices for AI training.
  * **Visual Spectrogram Generator:** Converts the raw math into PNG heatmaps for visual debugging and checks.
