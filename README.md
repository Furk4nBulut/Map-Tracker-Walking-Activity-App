# Map Tracker Yürüyüş Aktivitesi Uygulaması

Bu proje, Flutter kullanarak geliştirilen bir yürüyüş aktivitesi uygulamasıdır. Uygulama, kullanıcıların yürüyüş/koşu aktivitelerini başlatıp bitirmelerini, bu aktivitelerin süresini ve mesafesini hesaplamalarını, ve verileri SQLite/SpatiaLite veritabanına kaydetmelerini sağlar. Ayrıca geçmiş aktiviteleri görüntüleme ve detaylarını inceleme imkanı sunar. 
## Not: **İlk Flutter projem olup 0'dan öğrenerek 3 haftada geliştirdiğim projedir. Yazılan kodlar profesyonel bir yapıda olmaması muhtemeldir.**

![uygulama.png](uygulama.png)

## Özellikler

1. **Splash Ekranı**
    - Uygulama açıldığında 2-3 saniyelik bir logo animasyonu gösterilir.
    <img src="Screenshot_20240719_125540.png" alt="Splash Ekranı" width="75"/>

2. **Giriş/Kayıt Ekranı**
    - Google hesabı ile giriş (authentication) yapılır.
    - Kullanıcılar mail, ad, soyad, şifre gibi bilgilerle kayıt olabilir.
    - Kayıt bilgileri Firebase üzerinde tutulur ve login aşamasında bu bilgilerle giriş yapılabilir.
    <img src="Screenshot_20240719_125557.png" alt="Giriş Ekranı" width="75"/>
    <img src="Screenshot_20240719_125604.png" alt="Kayıt Ekranı" width="75"/>
    <img src="Screenshot_20240719_125610.png" alt="Giriş/Kayıt Ekranı" width="75"/>

3. **Dashboard**
    - Kullanıcının genel profili ve spor durumu (toplam mesafe, toplam süre, aktivite sayısı) gösterilir.
    - Kullanıcının yeni aktivite başlatabileceği ve geçmiş aktiviteleri görüntüleyebileceği butonlar bulunur.
    <img src="Screenshot_20240719_125727.png" alt="Dashboard" width="75"/>

4. **Yeni Aktivite Ekranı** *(MAJOR)*
    - Kullanıcı, bu ekranda yürüyüş/koşu aktivitesini başlatıp bitirebilir.
    - Aktif olunan süreçte kullanıcı, mevcut konumunu ve rota bilgisini harita üzerinde görebilir.
    - Aktif aktivitenin toplam mesafesi, geçen süresi ve ortalama hızı anlık olarak güncellenir.
    - Aktivite sonuçları Google Firestore veritabanına kaydedilir.
    - Güncel hava durumu bilgisi OpenWeatherMap API'sinden alınır ve gösterilir.
    <img src="Screenshot_20240719_125701.png" alt="Yeni Aktivite Ekranı" width="75"/>

5. **Aktivite Geçmiş Hareketleri İçin Liste Ekranı** *(MAJOR)*
    - Kullanıcının geçmiş aktivitelerini listeleyen bir ekran.
    - Liste satırlarında tarih, yapılan mesafe ve detay butonları yer alır.
    <img src="Screenshot_20240719_125712.png" alt="Aktivite Geçmiş Hareketleri" width="75"/>

6. **Aktivite Geçmiş Detay Ekranı** *(MAJOR)*
    - Geçmiş aktiviteler listesinden seçilen detay ekranı açılır.
    - Rota, toplam mesafe ve süre Google Firestore veritabanından alınarak gösterilir.
    <img src="Screenshot_20240719_125718.png" alt="Aktivite Geçmiş Detay" width="75"/>

7. **Firebase ve Firestore Veritabanı**
    - Firebase ve Firestore yapılandırması ve veri formatları ile ilgili örnek kayıtlar ve ekran görüntüleri proje içine eklenmelidir.
    <img src="img.png" alt="Firebase Veritabanı" width="75"/>
    <img src="img_1.png" alt="Firestore Veritabanı" width="75"/>
    <img src="img_2.png" alt="Firebase Örnek Kayıtlar" width="75"/>

8. **Proje Teslimi**
    - Çalışabilir APK dosyası ile birlikte projeyi teslim etmeniz gerekmektedir.
    [app-release.apk](build%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk)

## Kurulum

1. GitHub'dan projeyi klonlayın:
   ```bash
   git clone https://github.com/Furk4nBulut/Map-Tracker-Flutter

   ```

2. Gerekli paketleri yükleyin:
   ```bash
   flutter pub get
   ```

3. Firebase yapılandırmasını yapın ve `google-services.json` dosyasını ilgili dizine ekleyin.

4. Uygulamayı çalıştırın:
   ```bash
   flutter run
   ```

## Katkıda Bulunanlar

- [Furkan Bulut](https://github.com/Furk4nBulut/Map-Tracker-Flutter)

## İletişim

- [Gmail](mailto:Furkanbtng@gmail.com)
- [LinkedIn](https://www.linkedin.com/in/furkanblt/)
- [Website](https://furk4nbulut.github.io/)

Herhangi bir sorun veya öneriniz olursa lütfen benimle iletişime geçin.
