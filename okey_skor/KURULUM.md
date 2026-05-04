# Okey Skor — Kurulum

## Gereksinimler

- Flutter SDK (flutter.dev/install)
- Chrome (web'de çalıştırmak için) veya Android telefon

## Kurulum Adımları

```bash
# 1. Proje klasörüne gir
cd okey_skor

# 2. Platform klasörlerini oluştur (ilk kurulumda bir kez)
flutter create . --project-name okey_skor --org com.okeyapp

# 3. Bağımlılıkları yükle
flutter pub get

# 4. Çalıştır
flutter run -d chrome          # Tarayıcıda
flutter run                    # Bağlı Android telefonda
```

## Android — Wakelock İzni

`android/app/src/main/AndroidManifest.xml` dosyasında `<manifest>` tagının altına ekle:

```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## Mimari

```
lib/
├── main.dart               # Wakelock, SharedPrefs, ProviderScope
├── app.dart                # MaterialApp + başlangıç ekranı
├── core/theme.dart         # Dark tema, AppColors
├── models/                 # Player, RoundScore, GameSession, Enums
├── engines/                # ClassicOkeyEngine, Okey101Engine
├── services/               # ChatService (JSON AI), StorageService
├── providers/              # GameSessionNotifier, ChatNotifier
├── screens/                # Home, Setup, Score, Chat
└── widgets/                # RoundSheets, TileCalculator, Dice, Ads
assets/rules/
├── okey_rules.json         # Klasik Okey kural tabanı
└── okey101_rules.json      # Okey 101 kural tabanı
```

## Özellikler

| Özellik | Durum |
|---------|-------|
| Klasik Okey skor | ✅ |
| Okey 101 skor (siler, işlek, eşli) | ✅ |
| Elden bitme (404/808) | ✅ |
| Eşli mod (2v2) | ✅ |
| 2x2 oyuncu grid ekranı | ✅ |
| + Ceza butonu (manuel ceza) | ✅ |
| Taş hesaplayıcı popup | ✅ |
| Zar atma popup | ✅ |
| Skor gizleme | ✅ |
| El geri alma (Undo) | ✅ |
| Tur sayısı limiti | ✅ |
| Oyun sonu özet | ✅ |
| Chat AI kural asistanı | ✅ |
| Mock banner reklam | ✅ |
| Mock interstitial reklam | ✅ |
| Veri kalıcılığı (SharedPreferences) | ✅ |
| Ekran sürekli açık (wakelock) | ✅ |
| Dark mode | ✅ |

## Gerçek Reklam (Sonraki Aşama)

`google_mobile_ads` eklenip `BannerAdWidget` ve `InterstitialAd` AdMob implementasyonuyla değiştirilir.
