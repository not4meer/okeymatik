# Okeymatik — iOS Teslim & Yayın Rehberi

Bu belge, iOS tarafını (Mac ortamı) devralacak arkadaş için hazırlanmıştır.

**Görev:** Uygulamayı App Store'da yayına hazır hâle getirmek — Firebase eklemek, build almak, App Store Connect'e yüklemek, review'e göndermek.

**Süre tahmini:** İlk build + kayıt = ~1 saat aktif iş. Review süresi Apple'da ~1-3 gün.

---

## 0. Proje Özeti (2026-07-12 tarihli güncel durum)

**Uygulama:** Okeymatik  
**Platform:** Flutter (Android + iOS + Web)  
**Dil:** Dart  
**State yönetimi:** Riverpod  
**Backend:** Firebase (Realtime Database + Crashlytics + Analytics)  
**Reklam:** **Unity Ads** (AdMob'dan geçildi — memory'de detay)  
**AI hakem:** **Google Gemini 2.5 Flash** (Groq'tan geçildi)  
**Şikayet maili:** EmailJS → ameerkhn86@gmail.com  
**Gizlilik URL:** https://not4meer.github.io/okeymatik/privacy.html  
**Kullanım koşulları URL:** https://not4meer.github.io/okeymatik/terms.html  

**Bundle ID (iOS):** `com.okeymatik.okeymatik`  
**Package (Android):** `com.okeymatik.app`

---

## 1. Repo ve Kod

```bash
git clone https://github.com/not4meer/okeymatik.git
cd okeymatik/okey_skor
```

Repo eskiden `101` idi, `okeymatik` olarak yeniden adlandırıldı. Eski URL redirect ediyor, bir sorun değil.

**Branch:** `main` üzerinde çalış.

---

## 2. Gerekli Araçlar (Mac)

```bash
# 1) Flutter kur
brew install flutter
# veya https://flutter.dev/docs/get-started/install/macos

flutter --version   # 3.x olmalı

# 2) CocoaPods
sudo gem install cocoapods

# 3) Xcode 15+ (App Store'dan)
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch

# 4) Bağımlılıklar
cd okey_skor
flutter pub get
cd ios && pod install --repo-update && cd ..
```

---

## 3. `config.dart` — Ameer Sana Ayrıca Gönderecek

⚠️ Bu dosya `.gitignore`'da olduğu için repo'da yok. Ameer sana email veya Telegram ile göndersin, şu yola koy:

```
okey_skor/lib/core/config.dart
```

Dosya boş görünse bile uygulama derlenmez — mutlaka doldurulmuş olarak Ameer'den al.

İçinde şunlar var:
- Gemini API key (opsiyonel — boşsa hakem çalışmaz)
- EmailJS servis ID'leri
- Unity Ads Game ID'leri (iOS: 800084264, Android: 800084265)
- `unityTestMode` flag (default `true`, release'de aşağıda anlatıldığı şekilde `false`)

---

## 4. Firebase — GoogleService-Info.plist (ZORUNLU)

Bu adımı **atlama**, uygulama başlangıçta çöker.

### Adımlar

1. https://console.firebase.google.com → **okeymatik-1d379** projesi
2. Dişli → **Project settings**
3. **Your apps** listesinde iOS uygulaması **yoksa** ekle:
   - Apple bundle ID: `com.okeymatik.okeymatik`
   - App nickname: `Okeymatik iOS`
   - Kaydet
4. **GoogleService-Info.plist** dosyasını indir
5. Xcode'da projeyi aç: `okey_skor/ios/Runner.xcworkspace` (**.xcodeproj değil**)
6. Sol panelde `Runner` grubuna sağ tık → **Add Files to "Runner"**
7. İndirdiğin `.plist` dosyasını seç
8. **"Copy items if needed" ✅** işaretli olsun
9. Add bas

> ⚠️ Bu dosyayı git'e commit ETME — `.gitignore`'da zaten var.

---

## 5. Xcode Signing (İmzalama)

```
okey_skor/ios/Runner.xcworkspace  ← BU aç
```

1. Sol panelden **Runner** projesine tıkla
2. **Signing & Capabilities** sekmesi
3. **Team:** Ameer'in Apple Developer hesabını seç (Ameer seni App Manager olarak eklemiş olmalı)
4. **Bundle Identifier:** `com.okeymatik.okeymatik` (**değiştirme**)
5. **Automatically manage signing** ✅

Xcode otomatik provisioning profili oluşturacak.

---

## 6. Yerel Test (İmzasız, Debug)

```bash
# Fiziksel iPhone bağla + güven ver
flutter devices

flutter run -d <device_id>
```

Uygulama açılırsa:
- Splash → skor ekranı çalışıyor mu?
- Dark / Light / Girls Mode tema değişimi
- Klasik Okey oyunu başlat, skor gir, ceza ver, siler kullan
- 101 modu dene
- Alt banner (Unity test reklamı görünmeli, "Unity Ads Test Ad" yazısı ile)
- El bitiminde geçiş reklamı (interstitial) açılıyor mu
- Canlı masa: oda oluştur, kod ile katıl
- Şikayet email butonu çalışıyor mu

---

## 7. App Store Connect'te Uygulama Kaydı

**Sadece Ameer'in Apple Developer hesabına giriş yetkisi varsa yapılabilir.** Ameer seni App Manager olarak ekledi mi?

1. https://appstoreconnect.apple.com → **Apps → +**
2. **New App**
3. Platforms: **iOS**
4. Name: `Okeymatik`
5. Primary language: **Turkish (Turkey)**
6. Bundle ID: **`com.okeymatik.okeymatik`** (dropdown'dan seç — Apple Developer'da provision'lı olmalı)
7. SKU: `okeymatik-ios-001`
8. User access: **Full Access**
9. **Create**

Sonra sol menüde:

### App Information
- Category → Primary: **Games**, Subcategory: **Card**
- Secondary Category (opsiyonel): **Board**
- Age Rating: `okey_skor/store/4_icerik_derecelendirme.md`'deki App Store cevaplarını uygula → 4+ çıkar
- Privacy Policy URL: `https://not4meer.github.io/okeymatik/privacy.html`

### App Privacy
- Get Started → `okey_skor/store/3_data_safety_privacy.md`'deki "App Store Connect" bölümünü uygula

### Pricing and Availability
- Price: **Free**
- Availability: Tüm ülkeler veya sadece Türkiye — Ameer'e sor

### 1.0.0 Version bilgileri
- Subtitle: `Skor, hakem, canlı masa`
- Description: `okey_skor/store/1_store_metinleri.md` → uzun açıklama TR
- Keywords: `okey_skor/store/1_store_metinleri.md` → keywords TR
- Support URL: `https://not4meer.github.io/okeymatik/`
- What's New: `okey_skor/store/2_release_notes.md` → TR versiyonu

### Screenshots

Zorunlu boyutlar:
- **6.7"** (iPhone 15 Pro Max, 14 Pro Max): 1290×2796 — zorunlu
- **6.5"** (iPhone 11 Pro Max, XS Max): 1242×2688 — zorunlu

**Simulator'dan çekmek en kolay:**
```bash
# Simulator'ı aç, uygulamayı çalıştır
flutter run -d "iPhone 15 Pro Max"

# Simulator penceresi aktifken:
Cmd + S   # ekranın masaüstüne kaydeder
```

Her ekrandan çek: Ana skor sayfası, tema seçimi, hakem chat, canlı masa oluşturma, oyun geçmişi. 4-8 tane iyi ss.

### İngilizce Localization ekle
- Sağ üst dropdown → **+ Add Language → English (U.S.)**
- İngilizce metinleri `1_store_metinleri.md` ve `2_release_notes.md`'nin EN kısımlarından kopyala

---

## 8. Release Build + Upload

```bash
cd okey_skor

# Test mode kapalı release build
flutter build ipa --release \
  --dart-define=UNITY_TEST_MODE=false \
  --dart-define=GEMINI_API_KEY="AQ.Ab8..."
```

Alternatif: Xcode'dan **Product → Archive** → Distribute App → App Store Connect → Upload.

Upload sonrası App Store Connect'te **"Processing"** durumunda ~15-30 dk kalır. Sonra version sayfasında **"Build"** kutusundan bu build'i seç.

---

## 9. Submit for Review

App Store Connect → version sayfası → sağ üst **Submit for Review**:

- **Export Compliance:** No (kripto kullanmıyor)
- **Content Rights:** I own or have rights
- **Advertising Identifier (IDFA):** **Yes**
  - ✅ Serve advertisements within the app
  - ✅ Limit Ad Tracking setting will be respected
  - ✅ App uses ATT prompt (Unity Ads bunu otomatik gösteriyor)

Submit → Apple review 24-72 saat. Ret gelirse sebep gösterir, düzelt, tekrar submit.

---

## 10. KESİNLİKLE DOKUNMA — Bu Dosyalar

| Dosya | Neden |
|-------|-------|
| `lib/firebase_options.dart` | Firebase config, yanlış URL uygulamayı kırar |
| `lib/providers/live_provider.dart` | Firebase DB URL hardcode (`europe-west1`) |
| `pubspec.yaml` | Bağımlılıklar dokunulursa pod conflict çıkar |
| `ios/Runner/Info.plist` | Bundle ID, izinler, Privacy URL, Unity SKAdNetwork ID'leri |
| `lib/core/strings.dart` | TR/EN çeviriler |
| `android/` klasörü tümüyle | iOS teslimatında dokunma |

---

## 11. Sık Karşılaşılan Hatalar

**`pod install` başarısız:**
```bash
cd ios
pod repo update
pod deintegrate
pod install --repo-update
```

**`GoogleService-Info.plist not found`:**
- Sadece klasöre kopyalamak yetmez. Xcode'da **Add Files to Runner** ile eklemelisin.

**`No signing certificate`:**
- Xcode → Preferences → Accounts → Apple ID ekle → Team seç

**`firebase_core initialization error`:**
- `.plist` eksik VEYA Bundle ID `.plist` içindeki ile uyuşmuyor

**Unity Ads reklam gelmiyor:**
- İlk 30-60 dk normal, Unity envanteri yükleniyor
- `unityTestMode: true` iken sadece Unity test reklamları gelir (canlı reklam görmezsin, normal)
- Release build'te `--dart-define=UNITY_TEST_MODE=false` verildiyse gerçek reklamlar başlar

**Archive butonu grileşmiş:**
- Xcode sol üst dropdown'dan `Any iOS Device (arm64)` seç, Simulator seçili olmasın

---

## 12. İletişim

- Proje sahibi: **Ameer / not4meer**  
- GitHub: https://github.com/not4meer/okeymatik  
- Ameer email: erdlalkkara12@gmail.com  
- Test / şikayet email destinasyonu: ameerkhn86@gmail.com  

Bir sorunda önce bu belgeyi baştan oku, sonra Ameer'e ulaş. Ekran görüntüsü at, error mesajını kopyala — çözüm hızlanır.

---

## 13. Kısa Checklist

- [ ] Repo clone edildi, `flutter pub get` başarılı
- [ ] Ameer `config.dart`'ı gönderdi, doğru yere kopyalandı
- [ ] `pod install` başarılı
- [ ] Firebase Console'dan iOS için `.plist` indirildi, Xcode'a **Add Files** ile eklendi
- [ ] Xcode Signing & Capabilities → Team seçildi, `com.okeymatik.okeymatik` bundle ID görünüyor
- [ ] `flutter run` ile fiziksel iPhone'da açıldı, temel akış test edildi
- [ ] App Store Connect'te uygulama oluşturuldu
- [ ] App Info, Privacy Nutrition Label dolduruldu
- [ ] Screenshots yüklendi (6.7" + 6.5" zorunlu)
- [ ] Release IPA build alındı ve upload edildi
- [ ] Version sayfasında build seçildi
- [ ] Submit for Review yapıldı

Bittiğinde Ameer'e haber ver — review süreci başlar.
