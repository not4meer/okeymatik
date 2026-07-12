# Okeymatik

Okey ve Okey 101 kart oyunları için skor takip, canlı masa paylaşımı ve AI hakem özellikli Flutter uygulaması.

**Platform:** Android • iOS • Web
**State yönetimi:** Riverpod
**Backend:** Firebase Realtime Database + Analytics + Crashlytics
**Reklam:** Google AdMob
**AI hakem:** Google Gemini 2.5 Flash

---

## Özellikler

| Özellik | Durum |
|---------|-------|
| Klasik Okey skor takibi | ✅ |
| Okey 101 (siler, işlek, eşli mod) | ✅ |
| Elden bitme (404 / 808) | ✅ |
| Çiftli mod (2v2) skorboard | ✅ |
| Manuel ceza, siler, undo | ✅ |
| Taş hesaplama popup | ✅ |
| Zar atma animasyonu | ✅ |
| AI hakem (Gemini) | ✅ |
| Canlı masa (Firebase oda kodu ile paylaşım) | ✅ |
| Oyun özeti + paylaşım | ✅ |
| Geçmiş oyunlar (SharedPreferences) | ✅ |
| Dark / Light / Girls Mode tema | ✅ |
| AdMob banner + interstitial | ✅ |
| Ekran sürekli açık (wakelock) | ✅ |
| Şikayet/öneri (EmailJS + Firebase backup) | ✅ |

---

## Gerekli Araçlar

- Flutter SDK (3.x)
- Dart 3.x
- iOS için: Xcode 15+, CocoaPods
- Android için: Android Studio + Android SDK
- Web için: Chrome

---

## Kurulum

```bash
# 1. Repoyu klonla
git clone https://github.com/not4meer/101.git
cd 101/okey_skor

# 2. Bağımlılıklar
flutter pub get

# 3. iOS pod'ları (sadece iOS için)
cd ios && pod install && cd ..
```

### Gizli Dosyalar (git'e gitmez, elle oluştur)

`okey_skor/dart_defines.json`:

```json
{
  "GEMINI_API_KEY": "AQ.Ab8... veya AIzaSy...",
  "UNITY_TEST_MODE": "false"
}
```

`okey_skor/lib/core/config.dart`:

```dart
class AppConfig {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String emailjsServiceId = String.fromEnvironment('EMAILJS_SERVICE_ID', defaultValue: '...');
  static const String emailjsTemplateId = String.fromEnvironment('EMAILJS_TEMPLATE_ID', defaultValue: '...');
  static const String emailjsPublicKey = String.fromEnvironment('EMAILJS_PUBLIC_KEY', defaultValue: '...');
}
```

### Firebase Konfigürasyonu

- **Android:** `android/app/google-services.json` (git'e gitmez)
- **iOS:** `ios/Runner/GoogleService-Info.plist` (git'e gitmez)

İndirme: Firebase Console → `okeymatik-1d379` projesi → Project Settings → Your apps.
iOS dosyası ayrıca Xcode'da Runner target'a "Add Files to Runner" ile eklenmeli.

---

## Çalıştırma

```bash
# Web (tarayıcı)
flutter run -d chrome --dart-define-from-file=dart_defines.json

# Bağlı Android cihaz
flutter run --dart-define-from-file=dart_defines.json

# Bağlı iPhone (release modu — Mac'siz çalışır)
flutter run --release --dart-define-from-file=dart_defines.json -d <device_id>
```

`flutter devices` ile bağlı cihazların ID'lerini görebilirsin.

---

## Build

```bash
# iOS release
flutter build ios --release --dart-define-from-file=dart_defines.json

# Android APK
flutter build apk --release --dart-define-from-file=dart_defines.json

# Android App Bundle (Play Store)
flutter build appbundle --release --dart-define-from-file=dart_defines.json

# Web
flutter build web --release --dart-define-from-file=dart_defines.json
```

iOS App Store dağıtımı için: Xcode → `ios/Runner.xcworkspace` aç → Product → Archive → App Store Connect → TestFlight.

---

## Proje Yapısı

```
okey_skor/
├── lib/
│   ├── main.dart                  # Uygulama girişi, Firebase init
│   ├── app.dart                   # Tema + routing
│   ├── firebase_options.dart      # Firebase web + android config
│   ├── core/
│   │   ├── theme.dart             # Dark / Light / Girls Mode renkler
│   │   ├── strings.dart           # TR / EN çeviriler
│   │   └── config.dart            # API anahtarları (gitignore'da)
│   ├── models/                    # Player, RoundScore, GameSession
│   ├── engines/                   # ClassicOkeyEngine, Okey101Engine
│   ├── providers/                 # Riverpod state notifier'ları
│   ├── screens/                   # Home, Setup, Score, Chat, Live, History
│   ├── widgets/                   # RoundSheets, TileCalculator, Dice, Ads
│   └── services/                  # ChatService, AdMob, Analytics, Crashlytics
├── ios/                           # iOS native (Xcode workspace burada)
├── android/                       # Android native
├── web/                           # Web shell
├── assets/
│   ├── images/                    # Logolar, ikonlar
│   ├── fonts/                     # Caveat
│   └── rules/                     # AI hakem kural JSON'ları
├── pubspec.yaml                   # Bağımlılıklar
└── DEVHANDED_IOS.md               # iOS teslim belgesi
```

---

## Detaylı Belgeler

- [DEVHANDED_IOS.md](../DEVHANDED_IOS.md) — iOS test teslim belgesi (kurulum, Firebase, signing)
- [KURULUM.md](KURULUM.md) — Temel kurulum notları

---

## Firebase Bilgileri

| Alan | Değer |
|------|-------|
| Project ID | `okeymatik-1d379` |
| Realtime DB | `https://okeymatik-1d379-default-rtdb.europe-west1.firebasedatabase.app` |
| Region | Europe West 1 |

---

## İletişim

Repo: https://github.com/not4meer/101
