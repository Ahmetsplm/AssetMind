# AssetMind

**AssetMind**, modern yatırımcılar için tasarlanmış kapsamlı bir kişisel finans ve portföy takip uygulamasıdır. Flutter ile geliştirilen bu uygulama, hisse senetleri (BIST), kripto paralar, döviz ve emtia varlıklarınızı tek bir yerden yönetmenizi, analiz etmenizi ve takip etmenizi sağlar.


## Özellikler

*   **Çoklu Varlık Desteği**: BIST Hisseleri, Kripto Paralar, Döviz ve Altın/Emtia takibi.
*   **Akıllı Portföy Analizi**: Portföy çeşitliliğinizi, risk dağılımınızı ve performansınızı puanlayan yapay zeka destekli analiz motoru.
*   **Canlı Piyasa Verileri**: Yahoo Finance entegrasyonu ile gecikmesiz (Kripto) ve 15dk gecikmeli (BIST) piyasa verileri.
*   **Gizlilik Modu**: Toplu taşıma veya kalabalık ortamlarda bakiyenizi gizlemek için tek tuşla maskeleme.
*   **Gelişmiş Grafikler**: İnteraktif pasta grafikleri ve performans zaman çizelgeleri (`fl_chart`).
*   **Haber Akışı**: Finans dünyasından en son haberler (RSS entegrasyonu).
*   **Koyu/Açık Mod**: Göz yormayan, modern ve şık arayüz tasarımı.
*   **Yerel Veritabanı**: Verileriniz cihazınızda `SQLite` ile güvenle saklanır, buluta gönderilmez.
*   **Yedekleme & Geri Yükleme**: Verilerinizi JSON formatında dışa aktarıp dilediğiniz zaman geri yükleyebilirsiniz.

## Kullanılan Teknolojiler

Bu proje, modern Flutter geliştirme pratikleri ve güçlü kütüphaneler kullanılarak inşa edilmiştir:

*   **Flutter & Dart**: UI ve Logic.
*   **Provider**: State Management (Durum Yönetimi).
*   **SQFLite**: Yerel veritabanı.
*   **FL Chart**: Grafik görselleştirme.
*   **Shimmer**: Yükleme animasyonları.
*   **ShowcaseView**: Kullanıcı rehberliği (Onboarding).
*   **Shared Preferences**: Ayarların kaydedilmesi.
*   **Http & Webfeed**: Ağ istekleri ve RSS ayrıştırma.

## Kurulum

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin:

1.  **Depoyu Klonlayın**:
    ```bash
    git clone https://github.com/username/asset_mind.git
    cd asset_mind
    ```

2.  **Bağımlılıkları Yükleyin**:
    ```bash
    flutter pub get
    ```

3.  **Uygulamayı Başlatın**:
    ```bash
    flutter run
    ```
---
*AssetMind, finansal kararlarınızda size yardımcı olmayı amaçlar ancak bir yatırım tavsiyesi aracı değildir.*
