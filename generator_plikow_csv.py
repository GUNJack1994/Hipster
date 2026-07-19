import csv
import re
import threading
import time
import urllib.parse
import tkinter as tk
from tkinter import messagebox, filedialog, ttk
import requests
from bs4 import BeautifulSoup
from lxml import html
import requests
from tkinter import scrolledtext
import sys

class TkinterConsoleRedirector:
    def __init__(self, text_widget):
        self.text_widget = text_widget

    def write(self, string):
        # Dopisywanie tekstu na koniec pola logów
        self.text_widget.insert(tk.END, string)
        # Automatyczne przewijanie na sam dół, aby widzieć najnowsze logi
        self.text_widget.see(tk.END)

    def flush(self):
        # Wymagane przez architekturę sys.stdout
        pass

class YouTubeCSVGeneratorApp:
    def __init__(self, root):
        self.root = root
        self.root.title("YouTube CSV Generator")
        self.root.geometry("600x550")
        self.root.minsize(550, 450)

        # Przechowywanie wyników w pamięci aplikacji
        self.processed_results = []

        # UI Elements
        self.create_widgets()

    def create_widgets(self):
        # Etykieta instruująca
        instruction_label = tk.Label(
            self.root, 
            text="Wklej utwory w formacie: Wykonawca - Tytuł (jeden pod drugim)", 
            font=("Arial", 10, "bold")
        )
        instruction_label.pack(pady=10)

        # Pole tekstowe na utwory
        self.text_area = scrolledtext.ScrolledText(self.root, wrap=tk.WORD, width=50, height=10)
        self.text_area.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)
        
        # Domyślny tekst pomocniczy
        self.text_area.insert(
            tk.END, "Perfect - Nie płacz Ewka\nLady Pank - Mniej niż zero\nTSA - 51"
        )

        # Pasek postępu (Progressbar)
        self.progress = ttk.Progressbar(self.root, orient=tk.HORIZONTAL, mode='determinate')
        self.progress.pack(padx=15, pady=5, fill=tk.X)
        
        log_label = tk.Label(self.root, text="Logi systemowe (Konsola):", font=("Arial", 10, "bold"))
        log_label.pack(padx=10, pady=(10, 0), anchor=tk.W)

        # --- NOWE POLE TEKSTOWE NA LOGI ---
        # Ustawiamy state=tk.NORMAL na starcie, żeby system mógł tam pisać. 
        # Kolor tła zmieniamy na lekko szary/czarny dla efektu konsoli (opcjonalnie).
        self.console_area = scrolledtext.ScrolledText(
            self.root, 
            wrap=tk.WORD, 
            width=60, 
            height=8, 
            bg="#f0f0f0", 
            fg="#333333"
        )
        self.console_area.pack(padx=10, pady=5, fill=tk.BOTH, expand=True)

        # --- KLUCZOWY MOMENT: Przekierowanie sys.stdout ---
        # Od tej linijki każdy print() wyląduje w self.console_area
        sys.stdout = TkinterConsoleRedirector(self.console_area)

        # Status Label
        self.status_label = tk.Label(self.root, text="Gotowy do działania", fg="gray")
        self.status_label.pack(pady=5)

        # Kontener na przyciski na dole
        btn_frame = tk.Frame(self.root)
        btn_frame.pack(pady=15)

        # Przycisk startu generowania
        self.generate_btn = tk.Button(
            btn_frame, 
            text="Uruchom pobieranie", 
            command=self.start_processing_thread, 
            bg="#2980b9", 
            fg="white", 
            font=("Arial", 11, "bold"),
            padx=15,
            pady=5
        )
        self.generate_btn.pack(side=tk.LEFT, padx=10)

        # Nowy przycisk pobierania pliku CSV (domyślnie wyłączony)
        self.download_btn = tk.Button(
            btn_frame, 
            text="Pobierz plik CSV", 
            command=self.save_csv_file, 
            bg="#2ecc71", 
            fg="white", 
            font=("Arial", 11, "bold"),
            padx=15,
            pady=5,
            state=tk.DISABLED  # Aktywuje się po skończeniu pracy
        )
        self.download_btn.pack(side=tk.LEFT, padx=10)

    def start_processing_thread(self):
        # Czyścimy stare wyniki przed nowym pobieraniem
        self.processed_results = []
        self.download_btn.config(state=tk.DISABLED)
        
        # Uruchamiamy wątek roboczy
        thread = threading.Thread(target=self.process_songs)
        thread.daemon = True
        thread.start()

    def get_wikipedia_year(self, artist, title):
        """Wyszukuje rok wydania na Wikipedii."""
        headers = {
            "User-Agent": "YouTubeCSVGenerator/1.0 (kontakt: tester@example.com)"
        }

        # --- KROK 1: Spróbujmy wejść bezpośrednio na stronę o tytule piosenki ---
        # Automatycznie upewniamy się, że popularne frazy mają odpowiednie przecinki (np. "tam, gdzie")
        formatted_title = title
        if "tam gdzie" in formatted_title.lower():
            formatted_title = formatted_title.replace("tam gdzie", "tam, gdzie")
            
        formatted_title = formatted_title.replace(" ", "_")
        direct_url = f"https://pl.wikipedia.org/wiki/{urllib.parse.quote(formatted_title)}"
        
        try:
            response = requests.get(direct_url, headers=headers, timeout=4)
            if response.status_code == 200:
                tree = html.fromstring(response.content)
                year = self._extract_year_from_tree(tree)
                if year:
                    return year
        except Exception as e:
            print(f"[WIKIPEDIA DIRECT ERROR] {e}")

        # --- KROK 2: Jeśli bezpośredni link nie istnieje, korzystamy z API wyszukiwarki ---
        search_query = f"{artist} {title}"
        url = f"https://pl.wikipedia.org/w/api.php?action=query&list=search&srsearch={urllib.parse.quote(search_query)}&format=json"
        
        try:
            response = requests.get(url, headers=headers, timeout=4)
            if response.status_code == 200:
                data = response.json()
                search_results = data.get("query", {}).get("search", [])
                
                if search_results:
                    page_title = search_results[0]["title"]
                    page_url = f"https://pl.wikipedia.org/wiki/{urllib.parse.quote(page_title)}"
                    
                    page_response = requests.get(page_url, headers=headers, timeout=4)
                    tree = html.fromstring(page_response.content)
                    year = self._extract_year_from_tree(tree)
                    if year:
                        return year
        except Exception as e:
            print(f"Błąd wyszukiwania API Wikipedia ({artist} - {title}): {e}")
            
        return None

    def _extract_year_from_tree(self, tree):
        """Pomocnicza funkcja wyciągająca rok z drzewa HTML Wikipedii."""
        # 1. Sprawdzamy tabelę (infobox) po prawej stronie
        xpath_headers = ["Wydany", "Data wydania", "Data premiery", "Nagrany", "Rok"]
        for header in xpath_headers:
            # Twój oryginalny, precyzyjny XPath rozszerzony o brakujące nagłówki
            xpath_expr = f"//th[contains(text(), '{header}')]/../td//text()"
            raw_texts = tree.xpath(xpath_expr)
            if raw_texts:
                full_text = "".join(raw_texts).strip()
                # Szukamy 4 cyfr z przedziału lat 1940-2029
                match = re.search(r'\b(19[4-9]\d|20[0-2]\d)\b', full_text)
                if match:
                    return match.group(1)

        # 2. Sprawdzamy pierwszy akapit tekstu (częsty opis: "...wydany w 1971 roku...")
        paragraphs = tree.xpath("//div[@class='mw-parser-output']/p[position() <= 3]//text()")
        if paragraphs:
            full_intro = "".join(paragraphs)
            match = re.search(r'(?:rok\w*|wydan\w*|nagran\w*)\s+.*?(\b\d{4}\b)|(\b\d{4}\b)\s+.*?(?:rok\w*|wydan\w*|nagran\w*)', full_intro, re.IGNORECASE)
            if match:
                year = next((g for g in match.groups() if g), None)
                if year:
                    return year
            
            # Ostateczny test akapitu na obecność jakichkolwiek 4 cyfr
            simple_match = re.search(r'\b(19[4-9]\d|20[0-2]\d)\b', full_intro)
            if simple_match:
                return simple_match.group(1)
                
        return None

    def get_cbpp_year(self, artist, title):
        """
        Wyszukuje rok powstania utworu w Cyfrowej Bibliotece Polskiej Piosenki (CBPP).
        Buduje bezpośredni adres URL wyszukiwania: /szukaj/wyniki/Wykonawca Tytuł
        """
        base_url = "https://bibliotekapiosenki.pl"
        
        # Formatowanie frazy: "Wykonawca Tytuł" (bez myślnika)
        search_phrase = f"{artist} {title}"
        
        # Budujemy pełny URL wyszukiwania z zakodowanymi znakami (np. spacje jako %20)
        search_url = f"{base_url}/szukaj/wyniki/{urllib.parse.quote(search_phrase)}"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
            "Referer": base_url
        }
        
        try:
            # --- KROK 1: Pobranie wyników wyszukiwania ---
            response = requests.get(search_url, headers=headers, timeout=8)
            
            if response.status_code != 200:
                print(f"[CBPP] Błąd połączenia z wyszukiwarką (Status: {response.status_code})")
                return None
                
            tree = html.fromstring(response.content)
            
            # Wyciągamy hiperłącze pasujące do klasy i struktury /utwory/
            song_links = tree.xpath("//a[contains(@class, 'articlelink') and contains(@href, '/utwory/')]/@href")
            
            if not song_links:
                # Jeśli miks Wykonawca + Tytuł nic nie dał, spróbujmy wyszukać sam Tytuł
                search_url_title_only = f"{base_url}/szukaj/wyniki/{urllib.parse.quote(title)}"
                response = requests.get(search_url_title_only, headers=headers, timeout=8)
                tree = html.fromstring(response.content)
                song_links = tree.xpath("//a[contains(@class, 'articlelink') and contains(@href, '/utwory/')]/@href")
                
                if not song_links:
                    print(f"[CBPP] Nie znaleziono utworów dla: {artist} {title}")
                    return None
            
            # Pobieramy pierwszy znaleziony link do docelowej strony utworu
            song_page_url = f"{base_url}{song_links[0]}"
            print(f"[CBPP] Przechodzę do strony utworu: {song_page_url}")
            
            # --- KROK 2: Pobranie docelowej strony utworu ---
            song_response = requests.get(song_page_url, headers=headers, timeout=8)
            if song_response.status_code != 200:
                return None
                
            song_tree = html.fromstring(song_response.content)
            
            # --- KROK 3: Wyciągnięcie roku na podstawie tekstu 'Data powstania:' ---
            xpath_year = "//td[contains(., 'Data powstania:')]/following-sibling::td//text()"
            raw_year_data = song_tree.xpath(xpath_year)
            
            if raw_year_data:
                # Łączymy napisy i czyścimy ze zbędnych spacji/nowych linii
                full_text = "".join(raw_year_data).strip()
                
                # Szukamy 4-cyfrowego roku
                match = re.search(r'\b(19[4-9]\d|20[0-2]\d)\b', full_text)
                if match:
                    detected_year = match.group(1)
                    print(f"[CBPP SUCCESS] Wykryto rok: {detected_year}")
                    return detected_year
            
            print(f"[CBPP] Nie znaleziono roku w sekcji 'Data powstania:'")
            return None
            
        except Exception as e:
            print(f"[CBPP BŁĄD] Wystąpił błąd: {e}")
            return None
        
    # Umieść tę metodę wewnątrz swojej klasy, obok Wikipedii i CBPP
    def get_discogs_year(self, artist, title):
        """
        Wyszukuje rok wydania utworu w bazie Discogs API.
        Wymaga wygenerowania darmowego tokena deweloperskiego na discogs.com.
        """
        # Ustaw tutaj swój token wygenerowany w panelu dewelopera Discogs
        token = "hahlZFQfQiHsHFmwqtXzdefYzkIQjYLKUXAOtYlB" 

        base_url = "https://api.discogs.com/database/search"
        
        params = {
            "q": f"{artist} {title}",
            "type": "release",
            "token": token,
            "per_page": 10 # Sprawdzamy top 10 wyników, żeby znaleźć najstarszy
        }
        
        headers = {
            "User-Agent": "YouTubeCSVGeneratorApp/1.0 (kontakt@twojadomena.pl)"
        }
        
        try:
            response = requests.get(base_url, params=params, headers=headers, timeout=6)
            
            if response.status_code == 200:
                data = response.json()
                results = data.get("results", [])
                
                found_years = []
                
                # Przeszukujemy wyniki i zbieramy wszystkie poprawne lata
                for result in results:
                    year = result.get("year")
                    if year:
                        year_str = str(year).strip()
                        # Interesują nas tylko sensowne, 4-cyfrowe roczniki
                        if year_str.isdigit() and len(year_str) == 4:
                            year_int = int(year_str)
                            # Zabezpieczenie przed błędami w bazie (np. rok 0 albo z przyszłości)
                            if 1920 < year_int <= 2026: 
                                found_years.append(year_int)
                
                if found_years:
                    # Wybieramy najwcześniejszy rok (MINIMUM) - to da nam 1976 zamiast 2022
                    original_year = min(found_years)
                    print(f"[DISCOGS SUCCESS] Znaleziono najstarszy rok: {original_year} dla {artist} - {title}")
                    return str(original_year)
                            
                print(f"[DISCOGS] Brak zdefiniowanego roku dla frazy: {artist} - {title}")
                return None
                
        except Exception as e:
            print(f"[DISCOGS BŁĄD EXCEPTION] {e}")
            return None

    def get_youtube_url(self, artist, title, retries=3, delay=2):
        """
        Wyszukuje link do filmu na YouTube. 
        W przypadku błędu połączenia lub timeoutu, ponawia próbę do 'retries' razy.
        """
        query = f"{artist} {title}"
        url = f"https://www.youtube.com/results?search_query={urllib.parse.quote(query)}"
        
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"
        }
        
        for attempt in range(retries):
            try:
                # Dodaliśmy timeout=5 na żądanie – jeśli YouTube nie odpowie w 5s, rzuci błąd i spróbuje ponownie
                response = requests.get(url, headers=headers, timeout=5)
                
                if response.status_code == 200:
                    video_ids = re.findall(r'"videoId":"([^"]+)"', response.text)
                    if video_ids:
                        for video_id in video_ids:
                            return f"https://www.youtube.com/watch?v={video_id}"
                
                # Jeśli kod odpowiedzi to np. 429 Too Many Requests, odczekaj chwilę przed ponowieniem
                if response.status_code == 429:
                    print(f"YouTube zwrócił błąd 429 (Too Many Requests) dla {artist} - {title}. Próba {attempt + 1}/{retries}...")
                    time.sleep(delay * 2)
                    continue

            except (requests.exceptions.RequestException, requests.exceptions.Timeout) as e:
                print(f"Timeout lub błąd sieci dla {artist} - {title} (Próba {attempt + 1}/{retries}): {e}")
                if attempt < retries - 1:
                    time.sleep(delay)  # Odczekaj chwilę przed kolejną próbą
                else:
                    return "Błąd (Timeout)"
                    
        return "Nie znaleziono"

    def process_songs(self):
        # Czyszczenie okna konsoli przed nowym zadaniem
        self.console_area.delete("1.0", tk.END)
        
        raw_text = self.text_area.get("1.0", tk.END).strip()
        # ... reszta Twojego kodu process_songs ...
        
        raw_text = self.text_area.get("1.0", tk.END).strip()
        if not raw_text:
            messagebox.showwarning("Brak danych", "Wpisz najpierw utwory do przetworzenia.")
            return

        lines = [line.strip() for line in raw_text.split("\n") if line.strip()]
        total_songs = len(lines)
        
        self.generate_btn.config(state=tk.DISABLED)
        self.progress["value"] = 0
        self.progress["maximum"] = total_songs

        for index, line in enumerate(lines):
            if " - " in line:
                parts = line.split(" - ", 1)
                artist = parts[0].strip()
                title = parts[1].strip()
            elif "-" in line:
                parts = line.split("-", 1)
                artist = parts[0].strip()
                title = parts[1].strip()
            else:
                artist = "Nieznany"
                title = line.strip()

            self.status_label.config(text=f"Przetwarzanie ({index + 1}/{total_songs}): {artist} - {title}")
            
            # --- KROK 1: Próba pobrania z Wikipedii ---
            year = self.get_wikipedia_year(artist, title)
            
            if year and year != "Brak danych":
                print(f"[WIKIPEDIA] Znaleziono rok wydania dla '{artist} - {title}': {year}")
            else:
                # --- KROK 2: Jeśli Wikipedia zawiodła, szukamy w CBPP ---
                print(f"[WIKIPEDIA] Brak danych dla '{artist} - {title}'. Uruchamiam wyszukiwanie w CBPP...")
                self.status_label.config(text=f"Szukanie w CBPP ({index + 1}/{total_songs}): {artist} - {title}")
                
                year = self.get_cbpp_year(artist, title)
                
                if year and year != "Brak danych":
                    print(f"[CBPP] Znaleziono rok wydania dla '{artist} - {title}': {year}")
                else:
                    # --- KROK 3: Ostateczna broń - Google Playwright z AI ---
                    print(f"[CBPP] Brak danych dla '{artist} - {title}'. Uruchamiam zaawansowane wyszukiwanie w Discogs...")
                    self.status_label.config(text=f"Szukanie w Discogs ({index + 1}/{total_songs}): {artist} - {title}")
                    
                    year = self.get_discogs_year(artist, title)
                    
                    if year and year != "Brak danych":
                        print(f"[DISCOGS] Znaleziono rok wydania dla '{artist} - {title}': {year}")
                    else:
                        print(f"[BŁĄD/BRAK DANYCH] Nie udało się znaleźć roku wydania dla '{artist} - {title}' (Wiki, CBPP oraz Discogs zawiodły).")
                        year = "Brak danych"
            
            # --- KROK 4: Pobieranie linku z YouTube ---
            self.status_label.config(text=f"Szukanie linku YT ({index + 1}/{total_songs}): {artist} - {title}")
            yt_url = self.get_youtube_url(artist, title)

            self.processed_results.append({
                "Wykonawca": artist,
                "Rok": year,
                "Tytuł": title,
                "url": yt_url
            })

            self.progress["value"] = index + 1
            self.root.update_idletasks()
            
            # Odpoczynek dla serwerów (1 sekunda)
            if index < total_songs - 1:
                time.sleep(1)

        self.status_label.config(text="Zakończono pobieranie! Możesz teraz pobrać plik.")
        self.generate_btn.config(state=tk.NORMAL)
        
        # Aktywacja przycisku zapisu CSV po udanym zakończeniu
        if self.processed_results:
            self.download_btn.config(state=tk.NORMAL)

    def save_csv_file(self):
        """Uruchamia systemowe okienko zapisu i eksportuje zebrane dane do formatu CSV."""
        if not self.processed_results:
            return

        file_path = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("Pliki CSV", "*.csv"), ("Wszystkie pliki", "*.*")],
            title="Zapisz listę utworów jako"
        )
        
        if file_path:
            try:
                with open(file_path, mode='w', newline='', encoding='utf-8-sig') as csv_file:
                    fieldnames = ['Wykonawca', 'Rok', 'Tytuł', 'url']
                    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
                    
                    writer.writeheader()
                    for row in self.processed_results:
                        writer.writerow(row)
                
                messagebox.showinfo("Sukces", f"Zapisano pomyślnie {len(self.processed_results)} utworów!")
            except Exception as e:
                messagebox.showerror("Błąd zapisu", f"Nie udało się zapisać pliku:\n{e}")


if __name__ == "__main__":
    root = tk.Tk()
    app = YouTubeCSVGeneratorApp(root)
    root.mainloop()