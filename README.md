# 101 — Okeymatik

Okey ve Okey 101 kart oyunları için skor takip, canlı masa paylaşımı ve AI hakem özellikli Flutter uygulaması.

**Platform:** Android • iOS • Web
**State yönetimi:** Riverpod
**Backend:** Firebase Realtime Database + Analytics + Crashlytics
**Reklam:** Google AdMob
**AI hakem:** Groq API (LLaMA)

---

## Repo Yapısı

```
101/
├── okey_skor/          # Flutter uygulaması (ana proje)
├── docs/               # Tasarım ve geliştirme notları
└── DEVHANDED_IOS.md    # iOS teslim belgesi
```

Detaylı kurulum ve çalıştırma talimatları için: **[okey_skor/README.md](okey_skor/README.md)**

---

## Hızlı Başlangıç

```bash
git clone https://github.com/not4meer/101.git
cd 101/okey_skor

flutter pub get
cd ios && pod install && cd ..   # iOS için

# Gizli dosyaları oluştur (okey_skor/README.md içinde açıklı)
# - dart_defines.json
# - lib/core/config.dart
# - ios/Runner/GoogleService-Info.plist
# - android/app/google-services.json

flutter run --release --dart-define-from-file=dart_defines.json
```

---

## Belgeler

- [okey_skor/README.md](okey_skor/README.md) — Tam kurulum, çalıştırma, build
- [DEVHANDED_IOS.md](DEVHANDED_IOS.md) — iOS teslim belgesi (Firebase, signing, test listesi)
- [okey_skor/KURULUM.md](okey_skor/KURULUM.md) — Temel kurulum notları

---

## İletişim

Şikayet/öneri uygulama içinden gönderilebilir (EmailJS → ameerkhn86@gmail.com).
