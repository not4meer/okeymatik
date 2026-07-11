# İçerik Derecelendirme

Play Console **IARC** anketi ve App Store Connect **Age Rating** anketi cevapları.

Okeymatik bir **skor takip ve kural asistanı** uygulamasıdır — bir oyun uygulaması değildir (kart dağıtma, para bahsi, tur kazanma mekaniği yok). Bu ayrım cevapları basitleştirir.

---

## 🟦 Play Console — IARC Questionnaire

Play Console → **App content → Content rating → Start questionnaire**

### Adım 1: Category (Kategori)

**"Which category best describes your app?"**
→ **Reference, News, or Educational** *(skor takipçisi bir "referans aracı"dır, oyun değil)*

> Alternatif: "Utility, Productivity, Communication, or Other" — bu da kabul edilebilir. Ama "Reference/Educational" seçmek gambling sorularını atlar.

> **Yanlış seçim:** "Game" seçme — kumar/kazanma soruları çıkar ve anlamsızlaşır (biz oyun oynatmıyoruz).

### Adım 2: Violence
- Violence: **No**
- Realistic violence: **No**
- Fantasy violence: **No**
- Prolonged graphic violence: **No**
- Sexual violence: **No**

### Adım 3: Sexuality
- Sexuality: **No**
- Nudity: **No**
- Explicit sexual content: **No**

### Adım 4: Language
- Profanity: **No**
- Crude humor: **No**
- Discrimination: **No**

### Adım 5: Controlled Substance
- Alcohol / tobacco / drugs: **No**

### Adım 6: Gambling
- **"Does your app enable users to gamble with real money or virtual items of value?"** → **No**
- **"Does your app simulate gambling?"** → **No**
   - > Uygulama sadece skor tutar. Kumar mekaniği yoktur (bahis, kart dağıtımı, kazanma-kaybetme sonucu). Kural asistanı skor tutar, biter.
- **"Are the games playable for real money?"** → **No**

### Adım 7: User-Generated Content
- **"Does your app allow users to interact with other users?"** → **Yes** (canlı masa özelliği için)
   - **"Are chat, messaging, or content-sharing features available?"** → **No** (sadece skor senkronizasyonu, chat yok)
   - **"Can users share their location?"** → **No**
   - **"Can users make purchases inside the app?"** → **No** (premium subscription hariç, o da yakında eklenirse "Yes" olacak)

### Adım 8: Miscellaneous
- **"Does your app feature access to social features (leaderboards, achievements)?"** → **No**
- **"Does your app share user's personal info with third parties?"** → **No**
- **"Does your app collect precise location?"** → **No**

### Beklenen Sonuç
- **PEGI:** 3 (Everyone)
- **ESRB:** Everyone
- **USK:** 0
- **IARC Generic:** 3+

---

## 🍎 App Store Connect — Age Rating Questionnaire

App Store Connect → **App Information → Age Rating → Edit**

Tüm sorular için varsayılan **"None"** seçili. Sadece aşağıdakileri güncelle:

### None (Değiştirme):
- Cartoon or Fantasy Violence — **None**
- Realistic Violence — **None**
- Prolonged Graphic or Sadistic Realistic Violence — **None**
- Profanity or Crude Humor — **None**
- Mature/Suggestive Themes — **None**
- Horror/Fear Themes — **None**
- Medical/Treatment Information — **None**
- Alcohol, Tobacco, or Drug Use or References — **None**
- Sexual Content or Nudity — **None**
- Graphic Sexual Content and Nudity — **None**
- Simulated Gambling — **None** *(skor takipçisi kumar simülasyonu değildir)*
- Contests — **None**

### Diğer sorular:
- **"Unrestricted Web Access?"** → **No**
- **"Gambling and Contests"** → **No**
- **"Made for Kids"** → **No**

### Beklenen Sonuç
- **App Store Rating: 4+ (Everyone)**

> Not: Apple, uygulamayı otomatik "4+" veya "12+" olarak derecelendirebilir. Kart oyunu içerse bile skor asistanı olarak "4+" makul.

---

## Target Audience (Hedef Kitle)

### Play Console → App content → Target audience

- **Target age groups:** Sadece **"Ages 13-15"**, **"Ages 16-17"**, **"Ages 18+"** seç.
   - 13 yaş altını **seçme** — Play Store'un çocuk politikaları (COPPA, Play Families) devreye girer, ek yükümlülük gelir.
- **"Does your app unintentionally appeal to children under 13?"** → **No**
- **"Does your store listing target children?"** → **No**

### App Store Connect

Ayrı hedef kitle formu yok, sadece age rating var. Zaten 4+ verildi.

---

## Özet

| Store | Rating | Hedef Yaş |
|-------|--------|-----------|
| Play Store (IARC) | 3+ / Everyone | 13+ |
| App Store | 4+ | Herkes (Made for Kids: No) |
