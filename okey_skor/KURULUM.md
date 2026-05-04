# Okey Skor — Kurulum Adımları

## 1. Flutter Projesi Oluştur

```bash
flutter create okey_skor --org com.okeyapp --platforms android,ios
cd okey_skor
```

## 2. Kaynak Dosyaları Kopyala

`lib/` ve `assets/` klasörlerini oluşturulan proje dizinine kopyala (mevcut `lib/` üzerine yaz).

## 3. pubspec.yaml'ı Güncelle

Verilen `pubspec.yaml` içeriğini kullan (dependencies dahil).

## 4. Android Manifest — Wakelock İzni

`android/app/src/main/AndroidManifest.xml` dosyasında `<manifest>` tagının hemen altına ekle:

```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## 5. Bağımlılıkları Yükle ve Çalıştır

```bash
flutter pub get
flutter run
```

## Mimari Özeti

```
lib/
├── main.dart               # Entry point, wakelock, SharedPrefs init
├── app.dart                # MaterialApp, tema, ilk ekran seçimi
├── core/theme.dart         # Dark tema, AppColors
├── models/
│   ├── game_enums.dart     # GameType, GameMode, FinishType enums
│   ├── player.dart         # Player modeli
│   ├── round.dart          # RoundScore modeli
│   └── game_session.dart   # GameSession modeli + JSON serializasyon
├── engines/
│   ├── scoring_engine.dart      # Abstract ScoringEngine
│   ├── classic_okey_engine.dart # Klasik Okey hesaplama
│   └── okey101_engine.dart      # Okey 101 hesaplama (siler, işlek, eşli)
├── services/
│   ├── chat_service.dart    # JSON keyword matching AI asistanı
│   └── storage_service.dart # SharedPreferences persist
├── providers/
│   ├── game_provider.dart  # GameSessionNotifier (Riverpod)
│   └── chat_provider.dart  # ChatNotifier (Riverpod)
├── screens/
│   ├── home_screen.dart    # Oyun tipi seçimi
│   ├── setup_screen.dart   # İsim girişi, eşli/tekli mod
│   ├── score_screen.dart   # Skor tablosu (ana ekran)
│   └── chat_screen.dart    # AI kural asistanı chat
└── widgets/
    ├── banner_ad.dart           # Mock banner reklam (alt şerit)
    ├── interstitial_ad.dart     # Mock tam ekran reklam (el sonrası)
    ├── classic_round_sheet.dart # Klasik Okey el girişi
    └── okey101_round_sheet.dart # Okey 101 el girişi
assets/rules/
    ├── okey_rules.json     # Klasik Okey kural tabanı
    └── okey101_rules.json  # Okey 101 kural tabanı
```

## Özellikler

| Özellik | Durum |
|---------|-------|
| Klasik Okey skor | ✅ |
| Okey 101 skor (siler, işlek, eşli) | ✅ |
| Elden bitme (800) | ✅ |
| Eşli mod (2v2) | ✅ |
| Skor gizleme | ✅ |
| El geri alma (Undo) | ✅ |
| Chat AI kural asistanı | ✅ |
| Mock banner reklam | ✅ |
| Mock interstitial reklam | ✅ |
| Veri kalıcılığı (uygulama kapanır açılır) | ✅ |
| Ekran sürekli açık (wakelock) | ✅ |
| Dark mode | ✅ |

## Gerçek Reklam Entegrasyonu (Sonraki Aşama)

`google_mobile_ads` paketi eklenip `BannerAdWidget` ve `InterstitialAd` widget'ları gerçek AdMob implementasyonuyla değiştirilir. Mevcut mock yapısı bu geçişi kolaylaştıracak şekilde tasarlandı.
