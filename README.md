# 🛡️ MediTrack — Elder Care & Vitals Synchronization Platform

MediTrack is a premium, offline-first health assistant app built with Flutter. It helps seniors seamlessly monitor their vitals, manage medicine compliance, coordinate doctor visits, and log health events, while giving caretakers/administrators a dashboard to review historical sync logs.

---

## ✨ Features

- **📊 Vitals Logger & History Graphs**: Log heart rate, SpO2, blood pressure, temperature, and blood glucose. Includes visual trend analysis powered by `fl_chart`.
- **💊 Medication Scheduler**: Create detailed prescription routines, mark doses as taken/missed, and track adherence scores.
- **🚨 Emergency SOS System**: Immediately share location, health status, and emergency details via call, SMS, or WhatsApp integration.
- **📈 PDF Health Report Generator**: Compile, preview, and share comprehensive multi-page medical summaries directly from the mobile app.
- **🛡️ Caregiver Admin Panel**: A dedicated administrative dashboard featuring responsive split-pane/mobile details layouts to review and manage multiple elders' vital streams.
- **⚡ Offline-First Synchronization**: Log data offline seamlessly; background processes automatically sync changes with the remote server once connectivity is restored.
- **🎨 Modern Glassmorphic Design**: Futuristic user interfaces, custom logo integrations, glowing status indicators, pulsing emergency buttons, and staggered slide-in load transitions.

---

## 📸 Branding & Splash Screens
- **Launcher Icon**: Equipped with our custom high-resolution hospital & health cross logo.
- **Native Launch Screen**: Displays the custom logo centered on a pure white background immediately upon tapping the app icon.

---

## 🛠️ Tech Stack

* **Framework**: [Flutter](https://flutter.dev/) (Dart SDK `^3.5.0`)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router)
* **Local Database**: [Sqflite](https://pub.dev/packages/sqflite) (Offline-First cache)
* **Charts**: [fl_chart](https://pub.dev/packages/fl_chart)
* **Reports**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)
* **Local Cache**: [shared_preferences](https://pub.dev/packages/shared_preferences)

---

## 🚀 Getting Started

### Prerequisites
Make sure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and configured on your machine.

### Installation

1. **Clone the repository:**
   ```bash
   git clone <YOUR_GITHUB_REPO_URL>
   cd meditrack
   ```

2. **Fetch packages:**
   ```bash
   flutter pub get
   ```

3. **Configure Launcher Icons and Splash Screens (Optional):**
   If you change the logo at `assets/images/logo.png`, run:
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

4. **Run the app:**
   ```bash
   flutter run
   ```

5. **Build Release APK splits (Optimized):**
   ```bash
   flutter build apk --release --split-per-abi
   ```

---

## 🔑 Demo Credentials
To explore different role experiences:
- **Elder Console:** Log in using `margaret@meditrack.com` (Password: `password123`).
- **Admin Console:** Log in using `admin@meditrack.com` (Password: `admin123`).
