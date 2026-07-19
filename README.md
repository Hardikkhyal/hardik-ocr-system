# OmniOCR Offline

A premium, production-grade Android application built with Flutter that performs **100% offline Text Recognition (OCR)** on-device. The app prioritizes privacy and performance while providing a stunning, dark-themed user experience.

---

## Key Features

*   **🔒 Privacy-First & 100% Offline:** All text extraction is performed on-device using Google ML Kit. No data is sent to external servers, and no internet connection is required.
*   **📐 Smart Image Preprocessing:** Integrates an image cropper and rotator to allow users to refine document bounds, maximizing text recognition accuracy.
*   **🎙️ Offline Text-to-Speech (TTS):** Read recognized text aloud using native on-device speech engines.
*   **📝 Live Result Actions:**
    *   Full inline text editor to correct OCR typos.
    *   One-tap copy to system clipboard.
    *   Native Android sharing to other applications.
*   **🗄️ Scan History:** Automatically saves scans locally on the device via Hive DB. Users can search through, inspect, or delete previous scan results.
*   **🎨 Premium UI/UX:** Styled with custom space-dark gradients, frosted-glass (glassmorphism) loading indicators, smooth page transitions, and modern typography (Outfit and Inter).

---

## Tech Stack

*   **Framework:** Flutter (Android & iOS capable)
*   **OCR Library:** `google_mlkit_text_recognition`
*   **State Management:** `flutter_riverpod`
*   **Storage Database:** `hive_flutter`
*   **Layout Utilities:** `image_picker`, `image_cropper`, `flutter_tts`, `share_plus`, `animations`
*   **Fonts:** `google_fonts`

---

## Project Structure

```
lib/
├── main.dart                       # App initialization & provider setup
├── core/
│   ├── theme/
│   │   └── app_theme.dart          # Premium light/dark theme definitions
│   ├── database/
│   │   └── local_database.dart     # Hive storage layer for scans and settings
│   └── utils/
│       └── clipboard_helper.dart   # Sharing and clipboard utilities
└── features/
    ├── dashboard/
    │   ├── views/
    │   │   └── dashboard_screen.dart # Home list of history + trigger scan buttons
    │   └── widgets/
    │       └── history_card.dart     # Individual scan history item card
    ├── ocr/
    │   ├── controllers/
    │   │   └── ocr_controller.dart   # Riverpod providers for OCR and Theme states
    │   ├── models/
    │   │   └── scan_result.dart      # Scan record data model
    │   └── views/
    │       └── result_screen.dart    # Details view, editing, search, and TTS
    └── settings/
        └── views/
            └── settings_screen.dart  # Theme and data management settings
```

---

## Quick Start

1.  For environment setup (installing Flutter, Java JDK, Android Studio SDKs), refer to [SETUP.md](file:///d:/ocr/SETUP.md).
2.  Once Flutter is ready, open a terminal in this directory and execute the automated configuration script:
    ```powershell
    ./setup.ps1
    ```
3.  Launch the app:
    ```powershell
    flutter run
    ```
