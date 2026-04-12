import requests
from bs4 import BeautifulSoup # For parsing the HTML content
import os
import time
import pandas as pd
import pykakasi
kks = pykakasi.kakasi()

# Setup your folders and headers
save_directory = "./ojad_audio/"
# Create the directory for the files
os.makedirs(save_directory, exist_ok=True)

# Array to track our missing files
missing_files_log = []

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Referer': 'https://www.gavo.t.u-tokyo.ac.jp/ojad/search' 
    # The Referer is important because it tells the server where the request is coming from, which can help prevent blocking.
}

# The Pitch Logic Function
# This function looks at the HTML structure of the pitch accent data and categorizes it into Heiban, 
# Atamadaka, Odaka, or Nakadaka based on where the "accent_top" class appears in the character spans.

# This site uses a red line above the letters in the word to indicate pitch accent, where the "accent_top" class is applied to the character that has the highest pitch. 
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
    if drop_index == -1: return "Heiban"
    elif drop_index == 0: return "Atamadaka"
    elif drop_index == len(character_spans) - 1: return "Odaka"
    else: return "Nakadaka"

def get_romaji_name(jisho_td_element):
    """
    Finds the hidden Hiragana in the HTML and translates it to English letters (Romaji).
    """
    char_spans = jisho_td_element.find_all('span', class_='char')
    hiragana_word = "".join([char.text for char in char_spans])
    
    # Fallback just in case a word is missing its characters
    if not hiragana_word:
        return "unknown"
        
    converted = kks.convert(hiragana_word)
    english_word = "".join([item['hepburn'] for item in converted])
    
    return english_word


# Main Scraping Target - Adding loop for pages (range 1 to 2 gets exactly 1 page)
# limit:100 gives us 100 words on that single page
for page_num in range(1, 2):
    print(f"\n=============================")
    print(f" SCRAPING PAGE {page_num} ")
    print(f"=============================")
    
    url = f"http://www.gavo.t.u-tokyo.ac.jp/ojad/search/index/limit:100/page:{page_num}"
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.content, 'html.parser')

    # Find the words in each row only
    word_rows = soup.find_all('tr', id=lambda x: x and x.startswith('word_')) 

    # Download Loop
    for row in word_rows:
        try:
            # Get the Word Text and Pitch, midashi is the base word column, and the pitch info is in the katsuyo_jisho_js column
            midashi = row.find('td', class_='midashi')
            word_text = midashi.find('p', class_='midashi_word').text.strip()
            
            jisho_td = row.find('td', class_='katsuyo_jisho_js')
            pitch_category = get_pitch_category(jisho_td)
            english_word = get_romaji_name(jisho_td)
            
            # Loop through for both genders
            for gender in ['female', 'male']:
                # Find the specific button for each gender
                button = jisho_td.find('a', class_=f'js_proc_{gender}_button')
                
                if button:
                    audio_id = button.get('id') # Site format "1053_1_1_female" or "1053_1_1_male"
                    word_id = int(audio_id.split('_')[0]) # Only the 1053
                    
                    # The Math Rule for the folder, This site stores the audio files in folders of 100 words each, and are labelled as so
                    # word_id 1053 would be in folder "010"
                    folder_str = f"{word_id // 100:03d}" 
                    
                    # Master Download URL (Notice the {gender} variable in the URL)
                    mp3_url = f"https://www.gavo.t.u-tokyo.ac.jp/ojad/sound4/mp3/{gender}/{folder_str}/{audio_id}.mp3"
                    
                    print(f"Downloading {word_text} / {english_word} ({pitch_category}) - {gender.capitalize()}...")

                    # Error Logging and Exception Handling
                    try:
                        # 10 second timeout
                        audio_response = requests.get(mp3_url, headers=headers, timeout=10)
                        
                        # Check the HTTP Status Code
                        if audio_response.status_code == 200:
                            # Success and save the MP3 SAFELY with BOTH Japanese and English names
                            safe_jp = word_text.replace('/', '_').replace('\\', '_')
                            file_name = f"{word_id}_{safe_jp}_{english_word}_{gender}_{pitch_category}.mp3"

                            file_path = os.path.join(save_directory, file_name)
                            with open(file_path, 'wb') as file:
                                file.write(audio_response.content)
                        
                        elif audio_response.status_code == 404:
                            # The file doesn't exist on their server
                            print(f"  -> WARNING: File missing (404) for {word_text}")
                            missing_files_log.append({
                                'word': word_text, 
                                'word_id': word_id, 
                                'gender': gender,
                                'reason': '404 Not Found'
                            })
                        
                        else:
                            # Other errors (like 403 Forbidden or 500 Internal Server Error)
                            print(f"  -> WARNING: Server error {audio_response.status_code} for {word_text}")
                            missing_files_log.append({
                                'word': word_text, 
                                'word_id': word_id, 
                                'gender': gender,
                                'reason': f'HTTP Error {audio_response.status_code}'
                            })

                    # Technical Exceptions (like timeouts or connection errors)
                    except requests.exceptions.RequestException as e:
                        print(f"  -> CRITICAL: Network failure for {word_text} - {e}")
                        missing_files_log.append({
                            'word': word_text, 
                            'word_id': word_id, 
                            'gender': gender,
                            'reason': 'Network Exception/Timeout'
                        })
                        
                    time.sleep(1) # Pause before the next request to avoid overwhelming

        except Exception as e:
            print(f"Error on row: {e}")

if len(missing_files_log) > 0:
    print(f"\nPipeline finished, but {len(missing_files_log)} files were missing.")
    df_missing = pd.DataFrame(missing_files_log)
    df_missing.to_csv('missing_audio_audit.csv', index=False)
    print("Saved missing files report to missing_audio_audit.csv")
else:
    print("\nPipeline finished perfectly! 0 files missing.")

print("Batch complete!")