import requests
from bs4 import BeautifulSoup # For parsing the HTML content
import os
import time
import pandas as pd
import pykakasi
kks = pykakasi.kakasi()

# Setup folders and headers
save_directory = "./bulk_ojad_audio/"
# Create the directory for the files
os.makedirs(save_directory, exist_ok=True)

# Array to track missing files
missing_files_log = []

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Referer': 'https://www.gavo.t.u-tokyo.ac.jp/ojad/search' 
    # The Referer is important because it tells the server where the request is coming from, which can help prevent blocking.
}

# --- THE COUNTER SYSTEM  ---
# By removing Odaka from this dictionary, the download is skipped
# Odaka Pitch pattern is the same as heiban UNTIL a particle is added to the word
# since the model and flashcards will always be words in isolation, Odaka never pops up
# so including this pattern will confuse the model
TARGET_FILES_PER_PITCH = 300
pitch_counters = {
    "Heiban": 0,
    "Atamadaka": 0,
    "Nakadaka": 0
}


# The Pitch Logic Function
def get_pitch_category(jisho_td_element):
    character_spans = jisho_td_element.find_all('span', class_='inner')
    if not character_spans: return "Unknown"
    
    # Grab all the Japanese characters in the word
    drop_index = -1
    for index, char_span in enumerate(character_spans):
        classes = char_span.parent.get('class', [])
        if 'accent_top' in classes:
            drop_index = index
            break
            
    # catergorize pitch based on the position of the drop index        
    if drop_index == -1: 
        return "Heiban"
    elif drop_index == 0: 
        return "Atamadaka"
    elif drop_index == len(character_spans) - 1: 
        return "Odaka" 
    # --- Identifying Nakadaka Pitch Pattern ---
    # Nakadaka drops somewhere in the middle. So the drop index must be 
    # strictly greater than 0, AND less than the final character.
    elif drop_index > 0 and drop_index < (len(character_spans) - 1): 
        return "Nakadaka"
    else: 
        # If the HTML glitches or an unexpected number, safely reject it
        return "Unknown"

def get_romaji_name(clean_japanese_text):
    """
    Translates clean Japanese text to English letters (Romaji).
    """
    if not clean_japanese_text:
        return "unknown"
        
    converted = kks.convert(clean_japanese_text)
    english_word = "".join([item['hepburn'] for item in converted])
    
    return english_word


# Main Scraping Target
for page_num in range(1, 600):
    print(f"\n=============================")
    print(f" SCRAPING PAGE {page_num} ")
    print(f" QUOTA STATUS: {pitch_counters}")
    print(f"=============================")
    
    # Check if all pitch samples are already collected, before scraping the page
    if all(count >= TARGET_FILES_PER_PITCH for count in pitch_counters.values()):
        print("\nCompleted: 300 files collected for all pitch categories!")
        break # exits the 600-page loop

    url = f"http://www.gavo.t.u-tokyo.ac.jp/ojad/search/index/limit:300/page:{page_num}"
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, 'html.parser')

    # Find the words in each row only
    word_rows = soup.find_all('tr', id=lambda x: x and x.startswith('word_')) 

    # Download Loop
    for row in word_rows:
        try:
            # Get the Word Text and Pitch, midashi is the base word column
            midashi = row.find('td', class_='midashi')
            
            # --- BASE WORD EXTRACTION ---
            raw_word_text = midashi.find('p', class_='midashi_word').text.strip()
            word_text = raw_word_text.split('・')[0]
            
            jisho_td = row.find('td', class_='katsuyo_jisho_js')
            pitch_category = get_pitch_category(jisho_td)
            english_word = get_romaji_name(word_text)
            
            # stop odaka or unknowns from downloading
            if pitch_category not in pitch_counters or pitch_counters[pitch_category] >= TARGET_FILES_PER_PITCH:
                continue 
            
            # Loop through for both genders
            for gender in ['female', 'male']:
                if pitch_counters[pitch_category] >= TARGET_FILES_PER_PITCH:
                    break # break loop since limit is reached

                # Find the specific button for each gender
                button = jisho_td.find('a', class_=f'js_proc_{gender}_button')
                
                if button:
                    audio_id = button.get('id') # Site format "1053_1_1_female" or "1053_1_1_male"
                    word_id = int(audio_id.split('_')[0]) # Only the 1053
                    
                    # The Sites Math Rule for the folder system
                    folder_str = f"{word_id // 100:03d}" 
                    
                    # Master Download URL 
                    mp3_url = f"https://www.gavo.t.u-tokyo.ac.jp/ojad/sound4/mp3/{gender}/{folder_str}/{audio_id}.mp3"
                    
                    print(f"Downloading {word_text} / {english_word} ({pitch_category}) - {gender.capitalize()}... [{pitch_counters[pitch_category] + 1}/{TARGET_FILES_PER_PITCH}]")

                    # Error Logging and Exception Handling
                    try:
                        # 10 second timeout
                        audio_response = requests.get(mp3_url, headers=headers, timeout=10)
                        
                        # Check the HTTP Status Code
                        if audio_response.status_code == 200:
                            # Success and save the MP3 SAFELY with BOTH Japanese and English names
                            # Later some letters will look similar in english but have different kanji
                            safe_jp = word_text.replace('/', '_').replace('\\', '_')
                            file_name = f"{word_id}_{safe_jp}_{english_word}_{gender}_{pitch_category}.mp3"

                            file_path = os.path.join(save_directory, file_name)
                            with open(file_path, 'wb') as file:
                                file.write(audio_response.content)

                            # Increment counter
                            pitch_counters[pitch_category] += 1
                        
                        elif audio_response.status_code == 404:
                            print(f"  -> WARNING: File missing (404) for {word_text}")
                            missing_files_log.append({
                                'word': word_text, 
                                'word_id': word_id, 
                                'gender': gender,
                                'reason': '404 Not Found'
                            })
                        
                        else:
                            print(f"  -> WARNING: Server error {audio_response.status_code} for {word_text}")
                            missing_files_log.append({
                                'word': word_text, 
                                'word_id': word_id, 
                                'gender': gender,
                                'reason': f'HTTP Error {audio_response.status_code}'
                            })

                    # Technical Exceptions
                    except requests.exceptions.RequestException as e:
                        print(f"  -> CRITICAL: Network failure for {word_text} - {e}")
                        missing_files_log.append({
                            'word': word_text, 
                            'word_id': word_id, 
                            'gender': gender,
                            'reason': 'Network Exception/Timeout'
                        })
                        
                    time.sleep(1) # Pause before the next request to avoid overwhelming the server

        except Exception as e:
            print(f"Error on row: {e}")

# Final Audit Reporting
print(f"\nFINAL QUOTA COUNTS: {pitch_counters}")

if len(missing_files_log) > 0:
    print(f"\nPipeline finished, but {len(missing_files_log)} files were missing.")
    df_missing = pd.DataFrame(missing_files_log)
    df_missing.to_csv('missing_audio_audit.csv', index=False)
    print("Saved missing files report to missing_audio_audit.csv")
else:
    print("\nDownloads finished perfectly! 0 files missing.")

print("Batch complete!")