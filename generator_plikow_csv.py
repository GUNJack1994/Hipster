import csv
import re
import threading
import time
import urllib.parse
import tkinter as tk
from tkinter import messagebox, filedialog, ttk, scrolledtext
import requests
from lxml import html

class YouTubeCSVGeneratorApp:
    def __init__(self, root):
        self.root = root
        self.root.title("YouTube CSV Generator")
        self.root.geometry("800x730")
        self.root.minsize(700, 600)

        # Paleta kolorów DARK MODE
        self.COLOR_BG = "#0F172A"             # Tło główne (ciemny granat/grafit)
        self.COLOR_CARD = "#1E293B"           # Tło kart i pojemników
        self.COLOR_CARD_SECONDARY = "#334155" # Tło podrzędne / obramowania
        self.COLOR_TEXT = "#F8FAFC"            # Główny białawy tekst
        self.COLOR_TEXT_MUTED = "#94A3B8"      # Jasnoszary tekst pomocniczy
        self.COLOR_BORDER = "#334155"          # Kolor obramowań
        
        # Akcenty
        self.COLOR_PRIMARY = "#3B82F6"         # Jasnoniebieski akcent
        self.COLOR_PRIMARY_HOVER = "#2563EB"
        self.COLOR_SUCCESS = "#10B981"         # Zielony dla pobierania
        self.COLOR_SUCCESS_HOVER = "#059669"
        self.COLOR_INPUT_BG = "#0F172A"        # Tło pól tekstowych

        self.root.configure(bg=self.COLOR_BG)

        # Konfiguracja styli ttk
        self.setup_styles()

        # Przechowywanie wyników
        self.processed_results = []

        # Tworzenie interfejsu
        self.create_widgets()

    def setup_styles(self):
        self.style = ttk.Style()
        self.style.theme_use("clam")

        # Styl tabeli dla Dark Mode
        self.style.configure(
            "Treeview",
            background=self.COLOR_CARD,
            foreground=self.COLOR_TEXT,
            rowheight=28,
            fieldbackground=self.COLOR_CARD,
            font=("Segoe UI", 9),
            borderwidth=0
        )
        self.style.configure(
            "Treeview.Heading",
            background=self.COLOR_CARD_SECONDARY,
            foreground=self.COLOR_TEXT,
            font=("Segoe UI", 9, "bold"),
            borderwidth=1,
            relief="flat"
        )
        # Podświetlenie wybranego wiersza
        self.style.map("Treeview", background=[("selected", "#1E3A8A")], foreground=[("selected", "#FFFFFF")])

        # Pasek postępu
        self.style.configure(
            "Custom.Horizontal.TProgressbar",
            thickness=6,
            troughcolor=self.COLOR_CARD_SECONDARY,
            background=self.COLOR_PRIMARY,
            borderwidth=0
        )

    def create_widgets(self):
        # --- NAGŁÓWEK ---
        header_frame = tk.Frame(self.root, bg=self.COLOR_BG)
        header_frame.pack(fill=tk.X, padx=20, pady=(15, 10))

        title_label = tk.Label(
            header_frame, 
            text="YouTube CSV Generator", 
            font=("Segoe UI", 16, "bold"), 
            bg=self.COLOR_BG, 
            fg=self.COLOR_TEXT
        )
        title_label.pack(anchor=tk.W)

        subtitle_label = tk.Label(
            header_frame, 
            text="Automatyczne pobieranie dat wydań oraz linków z YouTube z możliwością walidacji.", 
            font=("Segoe UI", 9), 
            bg=self.COLOR_BG, 
            fg=self.COLOR_TEXT_MUTED
        )
        subtitle_label.pack(anchor=tk.W)

        # --- KROK 1: WPROWADZANIE DANYCH ---
        card_step1 = tk.Frame(self.root, bg=self.COLOR_CARD, bd=1, relief="solid", highlightbackground=self.COLOR_BORDER)
        card_step1.pack(fill=tk.X, padx=20, pady=5)

        step1_title = tk.Label(
            card_step1, 
            text="KROK 1: Wklej listę utworów (Wykonawca - Tytuł)", 
            font=("Segoe UI", 10, "bold"), 
            bg=self.COLOR_CARD, 
            fg=self.COLOR_TEXT
        )
        step1_title.pack(anchor=tk.W, padx=15, pady=(10, 5))

        self.text_area = scrolledtext.ScrolledText(
            card_step1, 
            wrap=tk.WORD, 
            width=50, 
            height=5, 
            font=("Consolas", 9),
            bg=self.COLOR_INPUT_BG,
            fg=self.COLOR_TEXT,
            insertbackground=self.COLOR_TEXT, # Kursor w ciemnym motywie
            bd=1,
            relief="solid",
            highlightthickness=0
        )
        self.text_area.pack(padx=15, pady=(0, 10), fill=tk.BOTH, expand=True)
        
        # Domyślny tekst
        default_songs = "Perfect - Nie płacz Ewka\nLady Pank - Mniej niż zero\nTSA - 51"
        self.text_area.insert(tk.END, default_songs)

        # Przycisk startu
        self.generate_btn = tk.Button(
            card_step1, 
            text="▶ Rozpocznij pobieranie", 
            command=self.start_processing_thread, 
            bg=self.COLOR_PRIMARY, 
            fg="white", 
            font=("Segoe UI", 9, "bold"),
            bd=0,
            padx=15,
            pady=6,
            cursor="hand2",
            activebackground=self.COLOR_PRIMARY_HOVER,
            activeforeground="white"
        )
        self.generate_btn.pack(anchor=tk.E, padx=15, pady=(0, 10))

        # --- PASEK POSTĘPU I STATUS ---
        status_frame = tk.Frame(self.root, bg=self.COLOR_BG)
        status_frame.pack(fill=tk.X, padx=20, pady=5)

        self.progress = ttk.Progressbar(status_frame, orient=tk.HORIZONTAL, mode='determinate', style="Custom.Horizontal.TProgressbar")
        self.progress.pack(fill=tk.X, pady=(0, 2))

        self.status_label = tk.Label(status_frame, text="Gotowy do pracy", font=("Segoe UI", 8), bg=self.COLOR_BG, fg=self.COLOR_TEXT_MUTED)
        self.status_label.pack(anchor=tk.W)

        # --- KROK 2: TABELA Z WALIDACJĄ ---
        card_step2 = tk.Frame(self.root, bg=self.COLOR_CARD, bd=1, relief="solid", highlightbackground=self.COLOR_BORDER)
        card_step2.pack(fill=tk.BOTH, expand=True, padx=20, pady=5)

        step2_header = tk.Frame(card_step2, bg=self.COLOR_CARD)
        step2_header.pack(fill=tk.X, padx=15, pady=10)

        step2_title = tk.Label(
            step2_header, 
            text="KROK 2: Weryfikacja i edycja wyników", 
            font=("Segoe UI", 10, "bold"), 
            bg=self.COLOR_CARD, 
            fg=self.COLOR_TEXT
        )
        step2_title.pack(side=tk.LEFT)

        step2_hint = tk.Label(
            step2_header, 
            text="💡 Kliknij 2x na 'Rok', aby go zmienić ręcznie", 
            font=("Segoe UI", 8, "italic"), 
            bg=self.COLOR_CARD, 
            fg=self.COLOR_PRIMARY
        )
        step2_hint.pack(side=tk.RIGHT)

        # Container na tabelę
        tree_container = tk.Frame(card_step2, bg=self.COLOR_CARD)
        tree_container.pack(fill=tk.BOTH, expand=True, padx=15, pady=(0, 5))

        columns = ("artist", "title", "year", "url")
        self.tree = ttk.Treeview(tree_container, columns=columns, show="headings", selectmode="browse")
        
        self.tree.heading("artist", text="Wykonawca")
        self.tree.heading("title", text="Tytuł")
        self.tree.heading("year", text="Rok wydania ✏️")
        self.tree.heading("url", text="URL YouTube")

        self.tree.column("artist", width=150)
        self.tree.column("title", width=180)
        self.tree.column("year", width=110, anchor=tk.CENTER)
        self.tree.column("url", width=220)

        scrollbar = ttk.Scrollbar(tree_container, orient=tk.VERTICAL, command=self.tree.yview)
        self.tree.configure(yscroll=scrollbar.set)
        
        self.tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.tree.bind("<Double-1>", self.on_double_click_year)

        # Panel narzędzi ponownego wyszukiwania
        retry_frame = tk.Frame(card_step2, bg=self.COLOR_CARD_SECONDARY, padx=10, pady=5)
        retry_frame.pack(fill=tk.X, padx=15, pady=(0, 10))

        tk.Label(retry_frame, text="Szukaj ponownie zaznaczonego w:", font=("Segoe UI", 8, "bold"), bg=self.COLOR_CARD_SECONDARY, fg=self.COLOR_TEXT).pack(side=tk.LEFT, padx=(0, 5))

        btn_style = {
            "font": ("Segoe UI", 8), 
            "bg": self.COLOR_CARD, 
            "fg": self.COLOR_TEXT, 
            "bd": 1, 
            "relief": "solid", 
            "padx": 8, 
            "cursor": "hand2",
            "activebackground": self.COLOR_PRIMARY,
            "activeforeground": "white"
        }

        tk.Button(retry_frame, text="Wikipedia", command=lambda: self.recheck_source("wiki"), **btn_style).pack(side=tk.LEFT, padx=2)
        tk.Button(retry_frame, text="CBPP", command=lambda: self.recheck_source("cbpp"), **btn_style).pack(side=tk.LEFT, padx=2)
        tk.Button(retry_frame, text="Discogs", command=lambda: self.recheck_source("discogs"), **btn_style).pack(side=tk.LEFT, padx=2)

        # --- KROK 3: POBIERANIE ---
        bottom_frame = tk.Frame(self.root, bg=self.COLOR_BG)
        bottom_frame.pack(fill=tk.X, padx=20, pady=(5, 15))

        self.download_btn = tk.Button(
            bottom_frame, 
            text="3. Pobierz gotowy plik CSV", 
            command=self.save_csv_file, 
            bg=self.COLOR_SUCCESS, 
            fg="white", 
            font=("Segoe UI", 10, "bold"),
            bd=0,
            padx=20,
            pady=8,
            cursor="hand2",
            state=tk.DISABLED,
            activebackground=self.COLOR_SUCCESS_HOVER,
            activeforeground="white"
        )
        self.download_btn.pack(side=tk.RIGHT)

    # --- ZDARZENIA I OBSŁUGI TABELI ---
    def on_double_click_year(self, event):
        item_id = self.tree.focus()
        if not item_id:
            return

        column = self.tree.identify_column(event.x)
        if column != "#3":
            return

        x, y, w, h = self.tree.bbox(item_id, column)
        current_val = self.tree.item(item_id, "values")[2]

        entry = tk.Entry(
            self.tree, 
            font=("Segoe UI", 9), 
            bg=self.COLOR_INPUT_BG, 
            fg=self.COLOR_TEXT, 
            insertbackground=self.COLOR_TEXT,
            bd=1, 
            relief="solid"
        )
        entry.place(x=x, y=y, width=w, height=h)
        entry.insert(0, current_val)
        entry.focus()

        def save_edit(event=None):
            new_val = entry.get().strip()
            values = list(self.tree.item(item_id, "values"))
            values[2] = new_val if new_val else "Brak danych"
            self.tree.item(item_id, values=values)
            
            idx = int(item_id)
            self.processed_results[idx]["Rok"] = values[2]
            entry.destroy()

        entry.bind("<Return>", save_edit)
        entry.bind("<FocusOut>", lambda e: entry.destroy())

    def recheck_source(self, source_name):
        selected_item = self.tree.focus()
        if not selected_item:
            messagebox.showwarning("Brak wyboru", "Zaznacz wpierw utwór na liście.")
            return

        idx = int(selected_item)
        item_data = self.processed_results[idx]
        artist = item_data["Wykonawca"]
        title = item_data["Tytuł"]

        def worker():
            self.status_label.config(text=f"Wyszukiwanie w źródle: {source_name.upper()}...")
            new_year = None

            if source_name == "wiki":
                new_year = self.get_wikipedia_year(artist, title)
            elif source_name == "cbpp":
                new_year = self.get_cbpp_year(artist, title)
            elif source_name == "discogs":
                new_year = self.get_discogs_year(artist, title)

            if new_year and new_year != "Brak danych":
                item_data["Rok"] = new_year
                values = list(self.tree.item(selected_item, "values"))
                values[2] = new_year
                self.tree.item(selected_item, values=values)
                messagebox.showinfo("Sukces", f"Zaktualizowano rok na: {new_year}")
            else:
                messagebox.showwarning("Brak wyników", f"Baza {source_name.upper()} nie posiada informacji o dacie.")
            
            self.status_label.config(text="Status: Oczekiwanie")

        threading.Thread(target=worker, daemon=True).start()

    # --- LOGIKA POBIERANIA DANYCH ---
    def get_wikipedia_year(self, artist, title):
        headers = {"User-Agent": "YouTubeCSVGenerator/1.0"}
        languages = ["pl", "en"]
        
        for lang in languages:
            direct_url = f"https://{lang}.wikipedia.org/wiki/{urllib.parse.quote(title)}"
            try:
                response = requests.get(direct_url, headers=headers, timeout=4)
                if response.status_code == 200:
                    tree = html.fromstring(response.content)
                    year = self._extract_year_from_tree(tree)
                    if year:
                        return year
            except Exception:
                pass

            search_query = f"{artist} {title}"
            api_url = f"https://{lang}.wikipedia.org/w/api.php?action=query&list=search&srsearch={urllib.parse.quote(search_query)}&format=json"
            
            try:
                response = requests.get(api_url, headers=headers, timeout=4)
                if response.status_code == 200:
                    data = response.json()
                    search_results = data.get("query", {}).get("search", [])
                    if search_results:
                        page_title = search_results[0]["title"]
                        page_url = f"https://{lang}.wikipedia.org/wiki/{urllib.parse.quote(page_title)}"
                        page_response = requests.get(page_url, headers=headers, timeout=4)
                        tree = html.fromstring(page_response.content)
                        year = self._extract_year_from_tree(tree)
                        if year:
                            return year
            except Exception:
                pass
            
        return None

    def _extract_year_from_tree(self, tree):
        xpath_headers = [
            "Wydany", "Data wydania", "Data premiery", "Nagrany", "Rok",
            "Released", "Publication date", "Recorded", "Issue date"
        ]
        
        for header in xpath_headers:
            xpath_expr = f"//th[contains(translate(text(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '{header.lower()}')]/../td//text()"
            raw_texts = tree.xpath(xpath_expr)
            if raw_texts:
                full_text = "".join(raw_texts).strip()
                match = re.search(r'\b(19[4-9]\d|20[0-2]\d)\b', full_text)
                if match:
                    return match.group(1)

        paragraphs = tree.xpath("//div[@class='mw-parser-output']/p[position() <= 3]//text()")
        if paragraphs:
            full_intro = "".join(paragraphs)
            match = re.search(r'(?:rok\w*|wydan\w*|nagran\w*|releas\w*|record\w*)\s+.*?(\b\d{4}\b)|(\b\d{4}\b)\s+.*?(?:rok\w*|wydan\w*|nagran\w*|releas\w*|record\w*)', full_intro, re.IGNORECASE)
            if match:
                year = next((g for g in match.groups() if g), None)
                if year:
                    return year
            
            simple_match = re.search(r'\b(19[4-9]\d|20[0-2]\d)\b', full_intro)
            if simple_match:
                return simple_match.group(1)
                
        return None

    def get_cbpp_year(self, artist, title):
        base_url = "https://bibliotekapiosenki.pl"
        search_phrase = f"{artist} {title}"
        search_url = f"{base_url}/szukaj/wyniki/{urllib.parse.quote(search_phrase)}"
        
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        
        try:
            response = requests.get(search_url, headers=headers, timeout=6)
            if response.status_code != 200:
                return None
                
            tree = html.fromstring(response.content)
            song_links = tree.xpath("//a[contains(@class, 'articlelink') and contains(@href, '/utwory/')]/@href")
            
            if not song_links:
                return None
            
            song_page_url = f"{base_url}{song_links[0]}"
            song_response = requests.get(song_page_url, headers=headers, timeout=6)
            if song_response.status_code != 200:
                return None
                
            song_tree = html.fromstring(song_response.content)
            xpath_year = "//td[contains(., 'Data powstania:')]/following-sibling::td//text()"
            raw_year_data = song_tree.xpath(xpath_year)
            
            if raw_year_data:
                full_text = "".join(raw_year_data).strip()
                match = re.search(r'\b(19[4-9]\d|20[0-2]\d)\b', full_text)
                if match:
                    return match.group(1)
            return None
        except Exception:
            return None

    def get_discogs_year(self, artist, title):
        token = "hahlZFQfQiHsHFmwqtXzdefYzkIQjYLKUXAOtYlB" 
        base_url = "https://api.discogs.com/database/search"
        params = {"q": f"{artist} {title}", "type": "release", "token": token, "per_page": 10}
        headers = {"User-Agent": "YouTubeCSVGeneratorApp/1.0"}
        
        try:
            response = requests.get(base_url, params=params, headers=headers, timeout=6)
            if response.status_code == 200:
                results = response.json().get("results", [])
                found_years = []
                for result in results:
                    year = result.get("year")
                    if year and str(year).isdigit() and 1920 < int(year) <= 2026:
                        found_years.append(int(year))
                if found_years:
                    return str(min(found_years))
            return None
        except Exception:
            return None

    def get_youtube_url(self, artist, title):
        query = f"{artist} {title}"
        url = f"https://www.youtube.com/results?search_query={urllib.parse.quote(query)}"
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}
        
        try:
            response = requests.get(url, headers=headers, timeout=5)
            if response.status_code == 200:
                video_ids = re.findall(r'"videoId":"([^"]+)"', response.text)
                if video_ids:
                    return f"https://www.youtube.com/watch?v={video_ids[0]}"
        except Exception:
            pass
        return "Nie znaleziono"

    def start_processing_thread(self):
        self.processed_results = []
        for i in self.tree.get_children():
            self.tree.delete(i)

        self.download_btn.config(state=tk.DISABLED)
        
        thread = threading.Thread(target=self.process_songs)
        thread.daemon = True
        thread.start()

    def process_songs(self):
        raw_text = self.text_area.get("1.0", tk.END).strip()
        if not raw_text:
            messagebox.showwarning("Brak danych", "Wpisz utwory do przetworzenia.")
            return

        lines = [line.strip() for line in raw_text.split("\n") if line.strip()]
        total_songs = len(lines)
        
        self.generate_btn.config(state=tk.DISABLED)
        self.progress["value"] = 0
        self.progress["maximum"] = total_songs

        for index, line in enumerate(lines):
            if " - " in line:
                parts = line.split(" - ", 1)
                artist, title = parts[0].strip(), parts[1].strip()
            elif "-" in line:
                parts = line.split("-", 1)
                artist, title = parts[0].strip(), parts[1].strip()
            else:
                artist, title = "Nieznany", line.strip()

            self.status_label.config(text=f"Przetwarzanie ({index + 1}/{total_songs}): {artist} - {title}")
            
            # Kaskadowe sprawdzanie
            year = self.get_wikipedia_year(artist, title)
            if not year:
                year = self.get_cbpp_year(artist, title)
            if not year:
                year = self.get_discogs_year(artist, title)
            if not year:
                year = "Brak danych"

            yt_url = self.get_youtube_url(artist, title)

            song_data = {
                "Wykonawca": artist,
                "Rok": year,
                "Tytuł": title,
                "url": yt_url
            }
            
            self.processed_results.append(song_data)
            self.tree.insert("", tk.END, iid=str(index), values=(artist, title, year, yt_url))

            self.progress["value"] = index + 1
            self.root.update_idletasks()
            
            if index < total_songs - 1:
                time.sleep(0.5)

        self.status_label.config(text="Status: Proces zakończony. Sprawdź lub wyedytuj dane poniżej.")
        self.generate_btn.config(state=tk.NORMAL)
        
        if self.processed_results:
            self.download_btn.config(state=tk.NORMAL)

    def save_csv_file(self):
        if not self.processed_results:
            return

        file_path = filedialog.asksaveasfilename(
            defaultextension=".csv",
            filetypes=[("Pliki CSV", "*.csv"), ("Wszystkie pliki", "*.*")],
            title="Zapisz listę jako CSV"
        )
        
        if file_path:
            try:
                with open(file_path, mode='w', newline='', encoding='utf-8-sig') as csv_file:
                    fieldnames = ['Wykonawca', 'Rok', 'Tytuł', 'url']
                    writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
                    
                    writer.writeheader()
                    for row in self.processed_results:
                        writer.writerow(row)
                
                messagebox.showinfo("Sukces", f"Pomyślnie wygenerowano plik ze {len(self.processed_results)} pozycjami!")
            except Exception as e:
                messagebox.showerror("Błąd", f"Nie udało się zapisać pliku:\n{e}")

if __name__ == "__main__":
    root = tk.Tk()
    app = YouTubeCSVGeneratorApp(root)
    root.mainloop()