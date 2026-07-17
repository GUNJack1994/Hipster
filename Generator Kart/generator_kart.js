const qrContainer = document.getElementById("qrcode");
const urlInput = document.getElementById("url-input");
const awersCard = document.getElementById("awers-card");

const artistInput = document.getElementById("txt-artist");
const yearInput = document.getElementById("txt-year");
const titleInput = document.getElementById("txt-title");

const queueContainer = document.getElementById("queue-container");
const queueCountElement = document.getElementById("queue-count");
const factory = document.getElementById("sheet-generator-factory");

const addBtn = document.getElementById("add-btn");
const cancelEditBtn = document.getElementById("cancel-edit-btn");
const testQrBtn = document.getElementById("test-qr-btn");

let savedCardsCollection = [];
let currentlyEditedCardId = null;

const defaultYoutubeUrl = "https://www.youtube.com";

function isValidYoutubeVideoUrl(rawUrl) {
    const trimmedUrl = (rawUrl || "").trim();
    if (!trimmedUrl) return false;

    const lowerUrl = trimmedUrl.toLowerCase();
    if (lowerUrl.includes("youtube.com/results") || lowerUrl.includes("/results")) {
        return false;
    }

    const regExp = /^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
    const match = trimmedUrl.match(regExp);
    const videoId = (match && match[2] && match[2].length === 11) ? match[2] : null;

    return !!videoId;
}

const qrcode = new QRCode(qrContainer, {
    text: defaultYoutubeUrl,
    width: 150,
    height: 150,
    colorDark: "#000000",
    colorLight: "#ffffff",
    correctLevel: QRCode.CorrectLevel.L
});

urlInput.addEventListener("input", function () {
    if (urlInput.value.trim() !== "") {
        urlInput.classList.remove("input-error");
    }
    qrcode.clear();
    let targetUrl = urlInput.value.trim();
    if (targetUrl === "") targetUrl = defaultYoutubeUrl;
    qrcode.makeCode(targetUrl);
});

yearInput.addEventListener("input", function () {
    const txt = yearInput.innerText.trim();
    yearInput.style.fontSize = /^\d+$/.test(txt) ? "22pt" : "18pt";
});

function resetCardToPlaceholders() {
    artistInput.innerHTML = "&lt;Nazwa wykonawcy&gt;";
    yearInput.innerHTML = "&lt;Rok wydania&gt;";
    yearInput.style.fontSize = "18pt";
    titleInput.innerHTML = "&lt;Tytuł utworu&gt;";
    urlInput.value = "";
    urlInput.classList.remove("input-error");
    qrcode.makeCode(defaultYoutubeUrl);

    currentlyEditedCardId = null;
    addBtn.innerText = "➕ Dodaj kartę do listy";
    addBtn.classList.remove("edit-mode");
    cancelEditBtn.style.display = "none";
}

addBtn.addEventListener("click", function () {
    const currentRawUrl = urlInput.value.trim();

    if (currentRawUrl === "") {
        urlInput.classList.add("input-error");
        urlInput.focus();
        alert("Błąd: Pole z linkiem YouTube nie może być puste przed dodaniem lub zapisaniem karty!");
        return;
    }

    if (!isValidYoutubeVideoUrl(currentRawUrl)) {
        urlInput.classList.add("input-error");
        urlInput.focus();
        alert("Błąd: Link musi wskazywać konkretny film YouTube. Linki do wyników wyszukiwania są nieprawidłowe!");
        return;
    }

    const artist = artistInput.innerText.trim();
    const year = yearInput.innerText.trim();
    const title = titleInput.innerText.trim();
    const currentQrSource = qrContainer.querySelector("canvas").toDataURL("image/png");
    const currentBg = awersCard.style.background;
    const currentBgColor = awersCard.style.backgroundColor;

    if (currentlyEditedCardId !== null) {
        const cardIndex = savedCardsCollection.findIndex(c => c.id === currentlyEditedCardId);
        if (cardIndex !== -1) {
            savedCardsCollection[cardIndex].artist = artist;
            savedCardsCollection[cardIndex].year = year;
            savedCardsCollection[cardIndex].title = title;
            savedCardsCollection[cardIndex].qrDataUrl = currentQrSource;
            savedCardsCollection[cardIndex].backgroundStyle = currentBg;
            savedCardsCollection[cardIndex].backgroundColor = currentBgColor;
            savedCardsCollection[cardIndex].rawUrl = currentRawUrl;
            savedCardsCollection[cardIndex].yearFontSize = yearInput.style.fontSize;
            savedCardsCollection[cardIndex].validationStatus = "none";
        }
    } else {
        const cardData = {
            id: Date.now(),
            artist: artist,
            year: year,
            title: title,
            qrDataUrl: currentQrSource,
            backgroundStyle: currentBg,
            backgroundColor: currentBgColor,
            rawUrl: currentRawUrl,
            yearFontSize: yearInput.style.fontSize,
            validationStatus: "none"
        };
        savedCardsCollection.push(cardData);
    }

    updateQueueUI();
    resetCardToPlaceholders();
});

cancelEditBtn.addEventListener("click", function () {
    resetCardToPlaceholders();
});

function updateQueueUI() {
    queueContainer.innerHTML = "";
    queueCountElement.innerText = savedCardsCollection.length;

    savedCardsCollection.forEach((card, index) => {
        const item = document.createElement("div");
        item.className = "queue-item";

        let statusBadge = `<span class="qr-status-badge status-none">Niesprawdzony</span>`;
        if (card.validationStatus === "ok") {
            statusBadge = `<span class="qr-status-badge status-ok">✅ QR OK</span>`;
        } else if (card.validationStatus === "fail") {
            statusBadge = `<span class="qr-status-badge status-fail">❌ BŁĄD QR / YT</span>`;
        }

        item.innerHTML = `
            <div class="item-info-block">
                <span><strong>#${index + 1}</strong> ${card.artist} - ${card.title} (${card.year})</span>
                ${statusBadge}
            </div>
            <div class="item-actions">
                <button class="edit-item-btn" onclick="startEditingCard(${card.id})">✏️ Edytuj</button>
                <button class="remove-btn" onclick="removeCardFromQueue(${card.id})">Usuń</button>
            </div>
        `;
        queueContainer.appendChild(item);
    });
}

window.startEditingCard = function (id) {
    const cardToEdit = savedCardsCollection.find(c => c.id === id);
    if (!cardToEdit) return;

    currentlyEditedCardId = id;
    artistInput.innerText = cardToEdit.artist;
    yearInput.innerText = cardToEdit.year;
    yearInput.style.fontSize = cardToEdit.yearFontSize;
    titleInput.innerText = cardToEdit.title;
    urlInput.value = cardToEdit.rawUrl;

    urlInput.classList.remove("input-error");

    qrcode.clear();
    let targetUrl = cardToEdit.rawUrl || defaultYoutubeUrl;
    qrcode.makeCode(targetUrl);

    addBtn.innerText = "💾 Zapisz zmiany w karcie";
    addBtn.classList.add("edit-mode");
    cancelEditBtn.style.display = "block";
    window.scrollTo({ top: 0, behavior: 'smooth' });
};

window.removeCardFromQueue = function (id) {
    if (currentlyEditedCardId === id) {
        resetCardToPlaceholders();
    }
    savedCardsCollection = savedCardsCollection.filter(c => c.id !== id);
    updateQueueUI();
};

/* --- TEST QR KODÓW + WALIDACJA DOSTĘPNOŚCI FILMÓW YT Z RAPORTEM --- */
testQrBtn.addEventListener("click", async function () {
    if (savedCardsCollection.length === 0) {
        alert("Kolejka jest pusta, dodaj karty do przetestowania!");
        return;
    }

    const originalBtnText = testQrBtn.innerText;
    testQrBtn.innerText = "⏳ Testowanie w toku...";
    testQrBtn.disabled = true;

    const reportSection = document.getElementById("report-section");
    const reportContainer = document.getElementById("report-table-container");
    reportSection.style.display = "none";
    reportContainer.innerHTML = "";

    let passedTests = 0;
    let failedTests = 0;
    let failedCardsLogs = [];

    for (let cardIndex = 0; cardIndex < savedCardsCollection.length; cardIndex++) {
        const card = savedCardsCollection[cardIndex];
        const cardPosition = `#${cardIndex + 1}`;
        let isUrlAlive = false;
        let failureReason = "";

        const normalizedYear = (card.year || "").toString().trim();
        const missingYear = !normalizedYear || normalizedYear === "[BRAK DANYCH]" || normalizedYear.toLowerCase().includes("brak danych");

        if (missingYear) {
            failureReason = `Brak roku wydania — pozycja ${cardPosition}`;
            card.validationStatus = "fail";
            failedTests++;
            failedCardsLogs.push({
                position: cardPosition,
                artist: card.artist,
                title: card.title,
                year: card.year,
                url: card.rawUrl,
                reason: failureReason
            });
            continue;
        }

        const regExp = /^.*(youtu\.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=)([^#\&\?]*).*/;
        const match = card.rawUrl.match(regExp);
        const videoId = (match && match[2] && match[2].length === 11) ? match[2] : null;

        if (isValidYoutubeVideoUrl(card.rawUrl) && videoId) {
            try {
                const response = await fetch(`https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=${videoId}&format=json`);
                if (response.ok) {
                    isUrlAlive = true;
                } else {
                    failureReason = `Błąd YT (Status ${response.status}) - Film usunięty lub prywatny`;
                }
            } catch (error) {
                failureReason = "Błąd połączenia / polityki CORS podczas sprawdzania linku";
                isUrlAlive = false;
            }
        } else {
            failureReason = "Nieprawidłowa struktura adresu URL YouTube (brak ID filmu lub link do wyników wyszukiwania)";
        }

        const isQrReadable = await new Promise((resolve) => {
            const img = new Image();
            img.src = card.qrDataUrl;

            img.onload = function () {
                const tempCanvas = document.createElement("canvas");
                const ctx = tempCanvas.getContext("2d");
                tempCanvas.width = 150;
                tempCanvas.height = 150;

                ctx.drawImage(img, 0, 0, 150, 150);
                const imageData = ctx.getImageData(0, 0, 150, 150);

                const decodedCode = jsQR(imageData.data, imageData.width, imageData.height, {
                    inversionAttempts: "dontInvert",
                });

                resolve(decodedCode && decodedCode.data === card.rawUrl);
            };

            img.onerror = () => resolve(false);
        });

        if (!isQrReadable && isUrlAlive) {
            failureReason = "Kod QR wygenerował się niepoprawnie lub proces renderowania Canvas został przerwany";
        } else if (!isQrReadable && !isUrlAlive && failureReason === "") {
            failureReason = "Zarówno link YT jest uszkodzony, jak i kod QR jest nieczytelny";
        }

        if (isQrReadable && isUrlAlive) {
            card.validationStatus = "ok";
            passedTests++;
        } else {
            card.validationStatus = "fail";
            failedTests++;

            failedCardsLogs.push({
                position: cardPosition,
                artist: card.artist,
                title: card.title,
                year: card.year,
                url: card.rawUrl,
                reason: failureReason
            });
        }
    }

    updateQueueUI();

    testQrBtn.innerText = originalBtnText;
    testQrBtn.disabled = false;

    if (failedTests === 0) {
        alert(`✅ Sukces! Przetestowano ${passedTests} kodów. Wszystkie QR są czytelne, a filmy są DOSTĘPNE na YouTube!`);
    } else {
        let tableHtml = `
            <table style="width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; color: #fff; text-align: left;">
                <thead>
                    <tr style="border-bottom: 2px solid #ff1744; color: #ff8a80;">
                        <th style="padding: 6px;">Pozycja</th>
                        <th style="padding: 6px;">Utwór (Wykonawca - Tytuł)</th>
                        <th style="padding: 6px;">Błędny URL</th>
                        <th style="padding: 6px;">Powód błędu</th>
                    </tr>
                </thead>
                <tbody>
        `;

        failedCardsLogs.forEach(log => {
            tableHtml += `
                <tr style="border-bottom: 1px solid #443344;">
                    <td style="padding: 8px 6px; font-weight: bold; color: #ff8a80;">${log.position}</td>
                    <td style="padding: 8px 6px;"><strong>${log.artist}</strong> - ${log.title} (${log.year})</td>
                    <td style="padding: 8px 6px; color: #ff8a80; word-break: break-all;"><code>${log.url}</code></td>
                    <td style="padding: 8px 6px; color: #ff1744; font-style: italic;">${log.reason}</td>
                </tr>
            `;
        });

        tableHtml += `</tbody></table>`;
        reportContainer.innerHTML = tableHtml;
        document.getElementById("error-count").innerText = failedTests;
        document.getElementById("report-dropdown-content").classList.add("collapsed");
        document.getElementById("dropdown-icon").classList.add("collapsed");
        reportSection.style.display = "block";

        window.currentFailedLogsTxt = failedCardsLogs.map((l, i) =>
            `[BŁĄD #${i + 1}]\nPozycja: ${l.position}\nUtwór: ${l.artist} - ${l.title} (${l.year})\nLink: ${l.url}\nPowód: ${l.reason}\n----------------------------------------`
        ).join("\n");

        alert(`⚠️ Znaleziono problemy w ${failedTests} kartach! Raport wygenerowano poniżej.`);
    }
});

/* --- OBSŁUGA POBIERANIA RAPORTU TXT --- */
document.getElementById("download-report-btn").addEventListener("click", function () {
    if (!window.currentFailedLogsTxt) return;

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const header = `RAPORT Z WALIDACJI LINKÓW YT I KODÓW QR\nData: ${new Date().toLocaleString()}\n========================================\n\n`;
    const blob = new Blob([header + window.currentFailedLogsTxt], { type: "text/plain;charset=utf-8;" });

    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.download = `raport_walidacji_${timestamp}.txt`;
    link.click();
});

/* --- OBSŁUGA EKSPORTU CSV --- */
document.getElementById("export-csv-btn").addEventListener("click", function () {
    if (savedCardsCollection.length === 0) {
        alert("Brak kart do wyeksportowania!");
        return;
    }

    let csvContent = "data:text/csv;charset=utf-8,\uFEFF";
    csvContent += "Rok;Wykonawca;Tytuł;URL\n";

    savedCardsCollection.forEach(card => {
        const rok = card.year.includes(";") ? `"${card.year.replace(/"/g, '""')}"` : card.year;
        const artysta = card.artist.includes(";") ? `"${card.artist.replace(/"/g, '""')}"` : card.artist;
        const tytul = card.title.includes(";") ? `"${card.title.replace(/"/g, '""')}"` : card.title;
        const url = card.rawUrl.includes(";") ? `"${card.rawUrl.replace(/"/g, '""')}"` : card.rawUrl;
        
        const row = [rok, artysta, tytul, url].join(";");
        csvContent += row + "\n";
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `lista_utworow_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
});

/* --- OBSŁUGA IMPORTU CSV Z PASKIEM ŁADOWANIA I OBSŁUGĄ BŁĘDÓW --- */
const csvFileInput = document.getElementById("csv-file-input");
const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

function showLoading(message = "Ładowanie pliku CSV...") {
    document.getElementById("loading-overlay").classList.add("active");
    document.getElementById("loading-text").innerText = message;
    document.getElementById("loading-progress-bar").style.width = "0%";
}

function hideLoading() {
    document.getElementById("loading-overlay").classList.remove("active");
}

function showErrorModal(title, errors) {
    document.getElementById("error-title").innerText = title;
    document.getElementById("error-modal-content").innerHTML = "";
    
    if (Array.isArray(errors)) {
        errors.forEach(error => {
            const errorDiv = document.createElement("div");
            errorDiv.className = "error-item";
            errorDiv.innerHTML = `<div class="error-item-title">${error.title}</div>${error.message}`;
            document.getElementById("error-modal-content").appendChild(errorDiv);
        });
    } else {
        document.getElementById("error-modal-content").innerHTML = `<div class="error-item">${errors}</div>`;
    }
    
    document.getElementById("error-modal-overlay").classList.add("active");
    document.getElementById("error-modal").classList.add("active");
}

window.closeErrorModal = function() {
    document.getElementById("error-modal-overlay").classList.remove("active");
    document.getElementById("error-modal").classList.remove("active");
};

function showSuccessNotification(message) {
    const notification = document.createElement("div");
    notification.className = "success-notification";
    notification.innerHTML = `✅ ${message}`;
    document.body.appendChild(notification);
    setTimeout(() => notification.remove(), 5000);
}

function updateProgressBar(progress) {
    document.getElementById("loading-progress-bar").style.width = progress + "%";
}

function toggleReportDropdown() {
    const content = document.getElementById("report-dropdown-content");
    const icon = document.getElementById("dropdown-icon");
    content.classList.toggle("collapsed");
    icon.classList.toggle("collapsed");
}

// Funkcja do prawidłowego parsowania CSV z obsługą cudzysłowów i przecinków
function parseCSVLine(line, delimiter = ',') {
    const result = [];
    let current = '';
    let inQuotes = false;
    
    for (let i = 0; i < line.length; i++) {
        const char = line[i];
        
        if (char === '"') {
            if (i + 1 < line.length && line[i + 1] === '"') {
                current += '""';
                i++;
            } else {
                inQuotes = !inQuotes;
            }
        } else if (char === delimiter && !inQuotes) {
            result.push(current.trim());
            current = '';
        } else {
            current += char;
        }
    }
    
    result.push(current.trim());
    return result;
}

// Funkcja do czyszczenia wartości CSV (usuwanie cudzysłowów)
function cleanCSVValue(value) {
    let cleaned = value.trim();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    return cleaned.replace(/""/g, '"');
}

// Funkcja do detekcji indeksów kolumn z nagłówka
function detectColumnIndexes(headerLine, delimiter) {
    const headers = parseCSVLine(headerLine, delimiter).map(h => cleanCSVValue(h).toLowerCase());
    
    const yearIdx = headers.findIndex(h => h.includes('rok'));
    const artistIdx = headers.findIndex(h => h.includes('wykonawca') || h.includes('artysta') || h.includes('artist'));
    const titleIdx = headers.findIndex(h => h.includes('tytuł') || h.includes('title'));
    const urlIdx = headers.findIndex(h => h.includes('url') || h.includes('link'));
    
    return { yearIdx: yearIdx >= 0 ? yearIdx : 0, artistIdx: artistIdx >= 0 ? artistIdx : 1, titleIdx: titleIdx >= 0 ? titleIdx : 2, urlIdx: urlIdx >= 0 ? urlIdx : 3 };
}

document.getElementById("import-csv-trigger").addEventListener("click", function () {
    csvFileInput.click();
});

csvFileInput.addEventListener("change", async function (e) {
    const file = e.target.files[0];
    if (!file) return;

    const errors = [];
    
    if (!file.type.includes("text") && !file.name.endsWith(".csv")) {
        showErrorModal("❌ Błędny typ pliku", [{
            title: "Nieprawidłowy plik",
            message: `Wybrany plik to: <strong>${file.type || "nieznany typ"}</strong>. Proszę wybrać plik CSV.`
        }]);
        csvFileInput.value = "";
        return;
    }

    if (file.size > MAX_FILE_SIZE) {
        const sizeMB = (file.size / (1024 * 1024)).toFixed(2);
        const maxMB = (MAX_FILE_SIZE / (1024 * 1024)).toFixed(0);
        showErrorModal("❌ Plik za duży", [{
            title: "Rozmiar przekroczony",
            message: `Rozmiar pliku: <strong>${sizeMB} MB</strong>. Maksymalny rozmiar to <strong>${maxMB} MB</strong>.`
        }]);
        csvFileInput.value = "";
        return;
    }

    showLoading("Czytanie pliku CSV...");
    updateProgressBar(20);

    try {
        const text = await new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = (event) => resolve(event.target.result);
            reader.onerror = () => reject(new Error("Nie można przeczytać pliku"));
            reader.readAsText(file, "UTF-8");
        });

        updateProgressBar(40);

        const lines = text.split(/\r?\n/);
        if (lines.length < 2) {
            hideLoading();
            showErrorModal("❌ Plik CSV jest pusty", [{
                title: "Brak danych",
                message: "Plik CSV musi zawierać co najmniej nagłówek i jeden wiersz z danymi."
            }]);
            csvFileInput.value = "";
            return;
        }

        let delimiter = ',';
        if (lines[0].includes(';')) {
            delimiter = ';';
        }

        const columnIndexes = detectColumnIndexes(lines[0], delimiter);
        
        let importedCount = 0;
        let skippedCount = 0;
        let rowErrors = [];
        let hiddenGen = document.getElementById("qr-hidden-generator");

        updateProgressBar(50);

        for (let i = 1; i < lines.length; i++) {
            const line = lines[i].trim();
            if (line === "") continue;

            try {
                let columns = parseCSVLine(line, delimiter);
                columns = columns.map(col => cleanCSVValue(col));

                const maxIdx = Math.max(columnIndexes.yearIdx, columnIndexes.artistIdx, columnIndexes.titleIdx, columnIndexes.urlIdx);
                if (columns.length <= maxIdx) {
                    rowErrors.push({
                        title: `Wiersz ${i}: Zbyt mało kolumn`,
                        message: `Znaleziono ${columns.length} kolumn, wymagane są ${maxIdx + 1}`
                    });
                    skippedCount++;
                    continue;
                }

                const rok = columns[columnIndexes.yearIdx]?.trim() || "";
                const artysta = columns[columnIndexes.artistIdx]?.trim() || "";
                const tytul = columns[columnIndexes.titleIdx]?.trim() || "";
                const url = columns[columnIndexes.urlIdx]?.trim() || "";

                let hasError = false;
                let errorMessage = "";

                if (url === "") {
                    hasError = true;
                    errorMessage += `Brak URL. `;
                }

                if (artysta === "") {
                    hasError = true;
                    errorMessage += `Brak wykonawcy. `;
                }

                if (tytul === "") {
                    hasError = true;
                    errorMessage += `Brak tytułu. `;
                }

                let isValidUrl = true;
                if (url !== "") {
                    try {
                        new URL(url);
                    } catch (e) {
                        hasError = true;
                        isValidUrl = false;
                        errorMessage += `Nieprawidłowy URL. `;
                    }

                    if (isValidUrl && !isValidYoutubeVideoUrl(url)) {
                        hasError = true;
                        isValidUrl = false;
                        errorMessage += `Link YouTube musi wskazywać konkretny film, a nie wyniki wyszukiwania. `;
                    }
                }

                let qrSrc = "";
                if (isValidUrl && url !== "") {
                    hiddenGen.innerHTML = "";
                    const hiddenQr = new QRCode(hiddenGen, {
                        text: url,
                        width: 150,
                        height: 150,
                        colorDark: "#000000",
                        colorLight: "#ffffff",
                        correctLevel: QRCode.CorrectLevel.L
                    });

                    const canvas = hiddenGen.querySelector("canvas");
                    if (canvas) {
                        qrSrc = canvas.toDataURL("image/png");
                    }
                }

                const cardData = {
                    id: Date.now() + i,
                    artist: artysta || "[BRAK DANYCH]",
                    year: rok || "[BRAK DANYCH]",
                    title: tytul || "[BRAK DANYCH]",
                    qrDataUrl: qrSrc || "",
                    backgroundStyle: "",
                    backgroundColor: "",
                    rawUrl: url || "[BRAK DANYCH]",
                    yearFontSize: /^\d+$/.test(rok) ? "22pt" : "18pt",
                    validationStatus: "none"
                };

                savedCardsCollection.push(cardData);
                importedCount++;

                if (hasError) {
                    rowErrors.push({
                        title: `Wiersz ${i}: Ostrzeżenie`,
                        message: `${artysta} - ${tytul}: ${errorMessage}`
                    });
                    skippedCount++;
                }

            } catch (err) {
                const cardData = {
                    id: Date.now() + i,
                    artist: "[BŁĄD PARSOWANIA]",
                    year: "????",
                    title: "[BŁĄD PARSOWANIA]",
                    qrDataUrl: "",
                    backgroundStyle: "",
                    backgroundColor: "",
                    rawUrl: "[BŁĄD]",
                    yearFontSize: "18pt",
                    validationStatus: "none"
                };
                
                savedCardsCollection.push(cardData);
                importedCount++;

                rowErrors.push({
                    title: `Wiersz ${i}: Błąd krytyczny`,
                    message: `${err.message} - Wiersz dodany ze zmienionymi danymi.`
                });
                skippedCount++;
            }
        }

        updateProgressBar(90);

        hiddenGen.innerHTML = "";
        updateQueueUI();

        updateProgressBar(100);
        hideLoading();

        csvFileInput.value = "";

        if (importedCount === 0) {
            hideLoading();
            showErrorModal("❌ Import nie powiódł się", [{
                title: "Brak danych",
                message: "Nie udało się zaimportować żadnych wierszy z pliku CSV."
            }]);
        } else if (rowErrors.length > 0) {
            const table = document.createElement("table");
            table.style.cssText = "width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 12px; color: #fff; text-align: left;";
            
            const thead = document.createElement("thead");
            const headerRow = document.createElement("tr");
            headerRow.style.cssText = "border-bottom: 2px solid #ff1744; color: #ff8a80;";
            
            const th1 = document.createElement("th");
            th1.textContent = "Typ błędu";
            th1.style.cssText = "padding: 12px; width: 25%;";
            const th2 = document.createElement("th");
            th2.textContent = "Szczegóły";
            th2.style.cssText = "padding: 12px; width: 75%;";
            
            headerRow.appendChild(th1);
            headerRow.appendChild(th2);
            thead.appendChild(headerRow);
            table.appendChild(thead);
            
            const tbody = document.createElement("tbody");
            rowErrors.forEach(error => {
                const row = document.createElement("tr");
                row.style.cssText = "border-bottom: 1px solid #443344;";
                
                const td1 = document.createElement("td");
                td1.style.cssText = "padding: 12px; word-wrap: break-word; overflow-wrap: break-word;";
                const strong = document.createElement("strong");
                strong.textContent = error.title;
                td1.appendChild(strong);
                
                const td2 = document.createElement("td");
                td2.style.cssText = "padding: 12px; color: #ff8a80; word-wrap: break-word; overflow-wrap: break-word;";
                td2.textContent = error.message;
                
                row.appendChild(td1);
                row.appendChild(td2);
                tbody.appendChild(row);
            });
            table.appendChild(tbody);
            
            const reportContainer = document.getElementById("report-table-container");
            reportContainer.innerHTML = "";
            reportContainer.appendChild(table);
            
            document.getElementById("error-count").innerText = rowErrors.length;
            document.getElementById("report-section").style.display = "block";
            document.getElementById("report-dropdown-content").classList.add("collapsed");
            document.getElementById("dropdown-icon").classList.add("collapsed");

            window.currentFailedLogsTxt = rowErrors.map((l, i) => {
                const num = i + 1;
                const line1 = `[BŁĄD #${num}]`;
                const line2 = l.title;
                const line3 = l.message;
                const sep = "----------------------------------------";
                return `${line1}\n${line2}\n${line3}\n${sep}`;
            }).join("\n");

            showSuccessNotification(`✅ Zaimportowano ${importedCount} utworów ${skippedCount > 0 ? `(z ${skippedCount} ostrzeżeniami)` : ''}!`);
        } else {
            hideLoading();
            showSuccessNotification(`✅ Pomyślnie zaimportowano wszystkie ${importedCount} utworów!`);
        }

    } catch (err) {
        hideLoading();
        showErrorModal("❌ Błąd podczas czytania pliku", [{
            title: "Nieudana operacja odczytu",
            message: `${err.message || "Nieznany błąd"}`
        }]);
    }
});

/* --- SZYBKI I NIEZAWODNY GENERATOR ARKUSZY PDF (AWERS + REWERS NA JEDNEJ STRONIE A4 POZIOMO) --- */
/* --- ZMODYFIKOWANY GENERATOR PDF: 4 KARTY NA STRONIE A4 (PIONOWO) --- */
document.getElementById("download-sheets-btn").addEventListener("click", async function () {
    if (savedCardsCollection.length === 0) {
        alert("Kolejka kart jest pusta! Dodaj utwory przed wygenerowaniem PDF.");
        return;
    }

    const { jsPDF } = window.jspdf;
    const doc = new jsPDF({
        orientation: 'portrait',
        unit: 'mm',
        format: 'a4'
    });

    const originalText = this.innerText;
    this.innerText = "⏳ Generowanie PDF...";
    this.disabled = true;

    try {
        const cardW = 60;
        const cardH = 90;
        const cardsPerPage = 4;

        const scaledW = 48;
        const scaledH = 72;
        const spacingY = 1.5;

        const totalContentH = (cardsPerPage * scaledH) + ((cardsPerPage - 1) * spacingY);
        const startY = (297 - totalContentH) / 2;
        const currentStartX = (210 - (scaledW * 2)) / 2;

        for (let i = 0; i < savedCardsCollection.length; i++) {
            const card = savedCardsCollection[i];
            const pageIndex = Math.floor(i / cardsPerPage);
            const cardIndexOnPage = i % cardsPerPage;

            if (i > 0 && cardIndexOnPage === 0) {
                doc.addPage(['a4', 'portrait']);
            }

            const currentScaleY = startY + (cardIndexOnPage * (scaledH + spacingY));

            const tempWrapper = document.createElement("div");
            tempWrapper.style.position = "absolute";
            tempWrapper.style.left = "-9999px";
            tempWrapper.style.top = "-9999px";

            tempWrapper.innerHTML = `
                <div class="card-print print-front" style="width: 60mm; height: 90mm;">
                    <div class="front-header">Quiz Muzyczny</div>
                    <div class="artist">${card.artist}</div>
                    <div class="title">${card.title}</div>
                    <div class="front-divider"></div>
                    <div class="year" style="font-size: ${card.yearFontSize || '18pt'};">${card.year}</div>
                </div>
            `;
            factory.appendChild(tempWrapper);

            const canvasFront = await html2canvas(tempWrapper.firstElementChild, {
                scale: 3,
                useCORS: true,
                allowTaint: true
            });
            const imgDataFront = canvasFront.toDataURL("image/jpeg", 0.95);
            factory.removeChild(tempWrapper);

            doc.addImage(imgDataFront, 'JPEG', currentStartX, currentScaleY, scaledW, scaledH);

            const rewersX = currentStartX + scaledW;
            doc.setFillColor(15, 23, 42);
            doc.rect(rewersX, currentScaleY, scaledW, scaledH, 'F');

            doc.setDrawColor(224, 169, 109);
            doc.setLineWidth(0.2);
            doc.rect(rewersX + 2.4, currentScaleY + 2.4, scaledW - 4.8, scaledH - 4.8, 'D');

            doc.setTextColor(148, 163, 184);
            doc.setFont("Helvetica", "bold");
            doc.setFontSize(7);
            doc.text("ZESKANUJ UTWÓR", rewersX + (scaledW / 2), currentScaleY + 10, { align: "center" });

            const qrSize = 21;
            const qrX = rewersX + ((scaledW - qrSize) / 2);
            const qrY = currentScaleY + ((scaledH - qrSize) / 2) + 3;

            doc.setDrawColor(224, 169, 109);
            doc.setLineWidth(0.4);
            doc.setFillColor(255, 255, 255);
            doc.rect(qrX - 2, qrY - 2, qrSize + 4, qrSize + 4, 'FD');

            doc.addImage(card.qrDataUrl, 'PNG', qrX, qrY, qrSize, qrSize);

            doc.setDrawColor(224, 169, 109);
            doc.setLineWidth(0.25);
            doc.setLineDashPattern([1.5, 1.5], 0);
            doc.line(currentStartX + scaledW, currentScaleY, currentStartX + scaledW, currentScaleY + scaledH);
            doc.setLineDashPattern([], 0);
        }

        doc.save(`Arkusze_Premium_Cards_4szt_${Date.now()}.pdf`);

    } catch (err) {
        console.error(err);
        alert("Wystąpił błąd podczas generowania pliku PDF.");
    } finally {
        this.innerText = originalText;
        this.disabled = false;
    }
});
