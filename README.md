# 🏡 Birlikteyapp

**Birliktey**, aile üyelerinin günlük görevleri ve market ihtiyaçlarını kolayca paylaşabileceği, organize olabileceği bir Flutter uygulamasıdır.  
Amaç: **Ev işleri & market alışverişini basitleştirmek, görevleri adil şekilde paylaştırmak.**

---

## ✨ Özellikler

- 👨‍👩‍👧‍👦 **Aile Üyeleri Yönetimi**
    - Üye ekleme, silme, arama
    - Landing page’de 2x2 grid ile hızlı seçim
    - Üye başına görev & alışveriş takibi

- ✅ **Görev Yönetimi**
    - Günlük yapılacaklar listesi
    - Haftalık planlama (ör. Pazartesi → Çöp at)
    - Görevleri üyeye atama & tamamlama durumu
    - “Show all / Pending / Completed” filtreleri

- 🛒 **Market Listesi**
    - Alışveriş listesi oluşturma
    - Hazır ürün önerileri + custom ürün ekleme
    - “To buy / Bought” filtreleri

- 📅 **Haftalık Plan → Günlük Senkronizasyon**
    - Belirlenen haftalık görevler o gün geldiğinde otomatik günlük listede görünür

- 💾 **Kalıcı Veri Saklama**
    - Hive / SharedPreferences entegrasyonu
    - Uygulama kapansa bile veriler korunur

- 🎨 **Modern Arayüz**
    - Material 3 uyumlu
    - Responsive grid & card tasarımı
    - Quick panel ve toggle butonlarla hızlı erişim

---

## 🚀 Kurulum

1. Reponun kopyasını al:
   ```bash
   git clone https://github.com/cyberturk01/birlikteyapp.git
   cd birlikteyapp

2. Paketleri yükle:
    ```bash
    flutter pub get


3. Uygulamayı Çalıştır:
    ```bash
    flutter run


📌 Flutter SDK kurulu olmalı. Kurulum rehberi

📂 Proje Yapısı (özet)
lib/
├─ models/         # Task, Item, WeeklyTask, ViewSection
├─ providers/      # State management (Provider)
├─ pages/
│   ├─ landing/    # Splash + Landing
│   ├─ home/       # HomePage + MemberCard + QuickPanel
│   ├─ tasks/      # Görev yönetimi
│   ├─ market/     # Market listesi
│   └─ weekly/     # Haftalık görev planı


🛠️ Teknolojiler

    **Flutter

    **Provider
    (state management)

    **Hive
    / SharedPreferences (persistent storage)

    **Material 3 Design

🤝 Katkı

Katkılarınızı memnuniyetle karşılıyoruz!

    **Fork edin
    
    **Branch açın (feature/yenilik)
    
    **Commit yapın (git commit -m "özellik eklendi")
    
    **Push edin (git push origin feature/yenilik)
    
    **Pull Request açın
