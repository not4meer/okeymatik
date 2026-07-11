# Veri Güvenliği & Gizlilik Beyanı

Play Console **Data Safety** wizard'ı ve App Store Connect **Privacy Nutrition Label** için hazır cevaplar.

---

## Kullanılan Servisler ve Topladıkları Veri

Okeymatik şu üçüncü taraf servislerini kullanır. Her biri belirli veriyi toplar:

| Servis | Topladığı Veri | Amaç |
|--------|----------------|------|
| **Firebase Analytics** | Yaklaşık konum (IP), cihaz ID, uygulama etkileşimleri | Kullanım istatistikleri |
| **Firebase Crashlytics** | Cihaz bilgisi, kilitlenme günlükleri | Hata teşhisi |
| **Firebase Realtime Database** | Oda kodu, skor (kimliksiz) | Canlı masa senkronizasyonu |
| **Unity Ads** | Reklam ID'si (IDFA/GAID), yaklaşık konum, cihaz bilgisi | Reklam gösterimi |
| **EmailJS** | Kullanıcının yazdığı email + şikayet metni | Kullanıcı destek |

Okeymatik kendi başına **hiçbir kişisel bilgiyi toplamaz veya depolamaz**. Kullanıcı hesabı, giriş sistemi yoktur. Skor verileri sadece cihazda tutulur.

---

## 🟦 Play Console — Data Safety Wizard Cevapları

Play Console → **App content → Data safety** yolunda karşına çıkan sorular. Sırayla:

### 1. Data collection and security

**Does your app collect or share any of the required user data types?**
→ **Yes**

**Is all of the user data collected by your app encrypted in transit?**
→ **Yes** (Firebase HTTPS, Unity Ads HTTPS, EmailJS HTTPS)

**Do you provide a way for users to request that their data be deleted?**
→ **No** *(Kullanıcı hesabı yok; uygulamayı silmek verileri de siler)*

### 2. Data types collected

Aşağıdakileri işaretle:

**Location:**
- [x] Approximate location — Collected, Not shared
   - **Optional:** No (required for ads)
   - **Purpose:** Analytics, Advertising or marketing

**Personal info:**
- [x] Email address — Collected, Not shared
   - **Optional:** Yes (only when user submits complaint form)
   - **Purpose:** App functionality (customer support)

**App activity:**
- [x] App interactions — Collected, Not shared
   - **Optional:** No
   - **Purpose:** Analytics

**App info and performance:**
- [x] Crash logs — Collected, Not shared
   - **Optional:** No
   - **Purpose:** Analytics
- [x] Diagnostics — Collected, Not shared
   - **Optional:** No
   - **Purpose:** Analytics

**Device or other identifiers:**
- [x] Device or other IDs — Collected, Not shared
   - **Optional:** No
   - **Purpose:** Analytics, Advertising or marketing

### 3. Security practices

- [x] Data is encrypted in transit — **YES**
- [ ] You provide a way for users to request that their data be deleted — **NO** (no user accounts)
- [x] Committed to Play Families Policy — **N/A** (13+ app)

### İşaretlenmeyecekler (Toplanmıyor):
- [ ] Precise location
- [ ] Name
- [ ] Phone number
- [ ] User IDs
- [ ] Address
- [ ] Race and ethnicity
- [ ] Political / religious beliefs
- [ ] Sexual orientation
- [ ] Photos, videos, audio, files
- [ ] Contacts
- [ ] Calendar
- [ ] Health & fitness
- [ ] Financial info
- [ ] Web browsing history
- [ ] SMS / call logs

---

## 🍎 App Store Connect — Privacy Nutrition Label Cevapları

App Store Connect → App Privacy → **Get Started**:

### "Do you or your third-party partners collect data from this app?"
→ **Yes, we collect data from this app**

### Data Types — Kategori kategori seç:

#### 🔵 Contact Info
- [x] **Email Address**
  - **Linked to identity:** No
  - **Used for tracking:** No
  - **Purpose:** App Functionality (user-submitted complaint form only)

#### 🟢 Identifiers
- [x] **Device ID**
  - **Linked to identity:** No
  - **Used for tracking:** Yes (advertising ID for Unity Ads)
  - **Purposes:**
    - Analytics
    - Third-Party Advertising
    - Developer's Advertising or Marketing

#### 🟡 Usage Data
- [x] **Product Interaction**
  - **Linked to identity:** No
  - **Used for tracking:** No
  - **Purpose:** Analytics

#### 🟠 Diagnostics
- [x] **Crash Data**
  - **Linked to identity:** No
  - **Used for tracking:** No
  - **Purpose:** App Functionality
- [x] **Performance Data**
  - **Linked to identity:** No
  - **Used for tracking:** No
  - **Purpose:** Analytics

#### 🟣 Location (Sadece Unity Ads için)
- [x] **Coarse Location**
  - **Linked to identity:** No
  - **Used for tracking:** Yes
  - **Purposes:**
    - Third-Party Advertising
    - Analytics

### App Tracking Transparency (ATT)

iOS 14.5+ için `NSUserTrackingUsageDescription` `Info.plist`'te tanımlı (mevcut).

- [x] Uygulama ilk açılışta ATT prompt gösterecek (Unity Ads bunu otomatik yapar)
- Kullanıcı "Allow" derse: IDFA ile kişiselleştirilmiş reklam
- "Ask App Not to Track" derse: sadece bağlamsal reklam (gelir düşer ama çalışır)

---

## Ek Notlar

**Gizlilik Politikası URL** (her iki store'da zorunlu alan):
```
https://not4meer.github.io/okeymatik/privacy.html
```

**Kullanıcı hesabı yok, oturum açma yok:**
- "Account Deletion" özelliği gerekmez (Play Store 2024'ten beri hesap sistemi olan uygulamalardan istiyor)
- KVKK/GDPR açısından "veri işleyen" statüsündeyiz, "veri sorumlusu" değil (çünkü tüm veri anonim veya kullanıcı tarafından gönderilmiş)

**Çocuklara yönelik mi?**
- **Play:** Target age: **13+** (kart oyunu için 13+ standart)
- **App Store:** Age rating **12+** (kumar referansı içeriyor değil, ama kart oyunu → 12+ önerilir)
