# Okeymatik — Yayın Kontrol Listesi

Bu klasörde 4 hazır doküman var. Yayına çıkarken sırayla açıp kopyala-yapıştır yaparak Play Console + App Store Connect'i doldurabilirsin.

## Dosyalar

| Dosya | İçerik | Nereye |
|-------|--------|--------|
| `1_store_metinleri.md` | App adı, kısa/uzun açıklama, keywords (TR + EN) | Play Store listing + App Store Connect App Info |
| `2_release_notes.md` | v1.0.0 "What's New" metni (TR + EN, 500 char) | Release oluştururken |
| `3_data_safety_privacy.md` | Data Safety wizard (Play) + Privacy Nutrition (App Store) | Play → App content; App Store → App Privacy |
| `4_icerik_derecelendirme.md` | IARC anketi (Play) + Age Rating (App Store) | Play → Content rating; App Store → Age Rating |

---

## 📋 Play Store — Adım Adım Yayın

### Ön koşullar (bunlar hazır olmadan başlama)

- [ ] Play Console hesabı açıldı + kimlik doğrulaması onaylandı ($25 ödendi, 2-3 gün onay)
- [ ] `.aab` release build hazır (`flutter build appbundle --release --dart-define=UNITY_TEST_MODE=false`)
- [ ] Uygulama icon: 512×512 PNG (kare, şeffaf değil)
- [ ] Feature graphic: 1024×500 PNG
- [ ] En az 2 (ideal 4-8) telefon screenshot: 1080×1920 min
- [ ] Reklam testi Android'de yapıldı, Unity ads geldi

### Play Console'da sırasıyla

**1. Uygulama oluştur**
- Play Console → **Create app**
- Name: `Okeymatik` — Language: `Türkçe` — Type: **Game** — Free — Declarations kabul

**2. App content (sol menüde 7 madde)**
- Privacy policy: `https://not4meer.github.io/okeymatik/privacy.html`
- App access: All functionality available without restrictions
- Ads: **Yes, contains ads**
- Content rating: → `4_icerik_derecelendirme.md`'deki cevapları uygula
- Target audience: → `4_icerik_derecelendirme.md`'de "Target Audience" bölümü
- News app: No
- **Data safety:** → `3_data_safety_privacy.md`'deki cevapları uygula

**3. Main store listing**
- App name: `Okeymatik`
- Short description: → `1_store_metinleri.md` (TR)
- Full description: → `1_store_metinleri.md` (TR uzun açıklama)
- App icon, feature graphic, screenshots yükle
- Category: **Games → Card**
- Contact email: `erdlalkkara12@gmail.com`

**4. Store settings**
- Store settings → app category: **Games → Card**
- Tags: 5 tane seç (Card game, Score, Live multiplayer, Turkish, Family)

**5. Closed testing (ZORUNLU yeni hesaplar için)**
- Sol menü → Testing → **Closed testing → Create track**
- Track adı: `alpha`
- **En az 20 tester** ekle (Gmail listesi)
- `.aab` dosyasını upload et
- Release notes ekle → `2_release_notes.md`
- Review → Start rollout
- **14 gün boyunca aktif bekle** (test'çiler giriş yapsın)
- 14 gün sonra "Apply for production access" butonu aktif olur

**6. Production**
- Production → **Create new release**
- `.aab` yükle
- Release notes → `2_release_notes.md`
- %100 rollout
- Submit → 1-3 gün Google review

---

## 📋 App Store — Adım Adım Yayın

### Ön koşullar

- [ ] Apple Developer üyeliği aktif ($99/yıl ödendi)
- [ ] Mac'te Xcode 15+ kurulu (arkadaş halledecek)
- [ ] `GoogleService-Info.plist` Runner klasörüne eklendi (arkadaş halledecek)
- [ ] Uygulama icon: 1024×1024 PNG (App Store için)
- [ ] iPhone 6.7" screenshot seti (1290×2796): zorunlu
- [ ] iPhone 6.5" screenshot seti (1242×2688): zorunlu
- [ ] iPad screenshot seti (2048×2732): opsiyonel

### App Store Connect'te

**1. Uygulama oluştur**
- appstoreconnect.apple.com → My Apps → **+ New App**
- Platform: iOS — Name: `Okeymatik` — Primary language: Turkish
- Bundle ID: `com.okeymatik.okeymatik` (dropdown'dan seç, Developer'da tanımlı olmalı)
- SKU: `okeymatik-ios-001` (istediğin string)

**2. App Information**
- Category → Primary: **Games** — Subcategory: **Card** — Secondary: **Board**
- Age rating → `4_icerik_derecelendirme.md`'deki App Store cevaplarını uygula (4+ çıkar)
- Privacy Policy URL: `https://not4meer.github.io/okeymatik/privacy.html`

**3. App Privacy** (sol menü)
- Get Started → `3_data_safety_privacy.md`'deki "App Store Connect — Privacy Nutrition Label" bölümünü uygula

**4. Version Information (1.0.0)**
- Subtitle: → `1_store_metinleri.md` (TR: "Skor, hakem, canlı masa")
- Promotional Text: (opsiyonel, boş bırakılabilir)
- Description: → `1_store_metinleri.md` (uzun açıklama TR)
- Keywords: → `1_store_metinleri.md` (TR keywords)
- Support URL: `https://not4meer.github.io/okeymatik/`
- Marketing URL: (opsiyonel)

**5. Screenshots yükle**
- 6.7" iPhone (zorunlu)
- 6.5" iPhone (zorunlu)
- iPad (opsiyonel — desteklemiyorsan skip)

**6. Build yükle** (Mac'ten)
- Xcode → Product → Archive
- Distribute App → App Store Connect → Upload
- 15-30 dk sonra Connect'te "Processing" biter, build seçilebilir

**7. Localization (İngilizce ekle)**
- Language dropdown → **+ English**
- İngilizce metinleri kopyala (`1_store_metinleri.md` EN kısımları)

**8. What's New** (release notes)
- → `2_release_notes.md`

**9. Submit for Review**
- Export Compliance: **No** (kripto kullanmıyor)
- Content Rights: I own or have rights
- Advertising Identifier: **Yes** (Unity Ads IDFA kullanıyor)
  - "Serve advertisements within the app" ✅
  - "Attribute an action taken within this app to a previously served advertisement" ✅
  - "Limit ad tracking setting in iOS": User will grant permission via ATT prompt ✅
- Submit → 24-48 saat Apple review

---

## 🔴 Kritik Notlar

**1. Release build'te Unity test mode kapatmayı unutma:**
```bash
flutter build appbundle --release --dart-define=UNITY_TEST_MODE=false
flutter build ipa --release --dart-define=UNITY_TEST_MODE=false
```

**2. Version bumping:**
Sonraki release'lerde `pubspec.yaml`'da `version: 1.0.0+1` satırındaki:
- `1.0.0` → versionName (kullanıcıya görünür)
- `+1` → versionCode (store için, her yükleme artmalı)

Örn: `1.0.1+2`, `1.1.0+3` ...

**3. Google Play 20-tester + 14 gün şartı:**
- Kimlik onaylı yeni bireysel hesaplar için ZORUNLU
- Şirket hesabı isim değişimi yapabiliyorsan bunu atlarsın
- 20 test'çi bulmak zor olabilir → arkadaş, aile, yakın çevreden Gmail adresi topla

**4. iOS için Mac gerekli:**
- Xcode Windows'ta yok
- Arkadaşın yardımı olmadan iOS build/archive/upload yapamayız

---

## Şu Andaki Durum (2026-07-12)

✅ Reklam: Unity Ads entegre, ID'ler kodda
✅ Privacy Policy: GitHub Pages'te canlı
✅ Store metinleri: Bu klasörde hazır
⏳ Reklam testi (Android — sen yapacaksın)
⏳ Screenshot (Android — sen, iOS — arkadaş yarın)
⏳ Play Console kimlik doğrulama (~2-3 gün)
⏳ 20 tester listesi
