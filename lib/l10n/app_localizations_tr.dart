// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get language => 'Dil';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get login => 'Giriş Yap';

  @override
  String get register => 'Kayıt Ol';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get forgotPassword => 'Şifremi unuttum';

  @override
  String get profile => 'Profil';

  @override
  String get viewProfile => 'Profili Görüntüle';

  @override
  String get editInformation => 'Bilgileri Düzenle';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get dashboard => 'Kontrol Paneli';

  @override
  String get customers => 'Müşteriler';

  @override
  String get measurementHistory => 'Ölçüm Geçmişi';

  @override
  String get orders => 'Siparişler';

  @override
  String get support => 'Destek';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get myAnalysisResults => 'Sonuçlarım';

  @override
  String get store => 'Mağaza';

  @override
  String get departmentAnalysis => 'Departman Değerlendirmesi';

  @override
  String get trends => 'Trendler';

  @override
  String get employees => 'Çalışanlar';

  @override
  String get reports => 'Raporlar';

  @override
  String get salesStatistics => 'Satış İstatistikleri';

  @override
  String get measurementPool => 'Ölçüm Havuzu';

  @override
  String get operations => 'Operasyonlar';

  @override
  String get digitalManufacturingLab => 'Dijital Üretim Laboratuvarı';

  @override
  String get services => 'Hizmetler';

  @override
  String get products => 'Ürünler';

  @override
  String get measurementCenters => 'Ölçüm Merkezleri';

  @override
  String get aboutUs => 'Hakkımızda';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get close => 'Kapat';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get back => 'Geri Dön';

  @override
  String get selectLanguage => 'Dil seçin';

  @override
  String get editInformationComingSoon =>
      'Bilgileri düzenleme ekranını daha sonra bağlayacağız.';

  @override
  String get forgotPasswordTitle => 'Şifremi Unuttum';

  @override
  String get passwordReset => 'Şifre Sıfırlama';

  @override
  String get passwordResetDescription =>
      'Hesabınıza bağlı e-posta adresini girin. Size şifrenizi yenilemeniz için bir bağlantı göndereceğiz.';

  @override
  String get sendResetLink => 'Sıfırlama Bağlantısı Gönder';

  @override
  String get newPassword => 'Yeni Şifre';

  @override
  String get newPasswordAgain => 'Yeni Şifre Tekrar';

  @override
  String get setNewPassword => 'Yeni Şifre Belirle';

  @override
  String get updatePassword => 'Şifreyi Güncelle';

  @override
  String get passwordUpdated => 'Şifre Güncellendi';

  @override
  String get firstName => 'Ad';

  @override
  String get lastName => 'Soyad';

  @override
  String get passwordAgain => 'Şifre Tekrar';

  @override
  String get userType => 'Kullanıcı Tipi';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı? Giriş Yap';

  @override
  String get noAccount => 'Hesabın yok mu? Kayıt Ol';

  @override
  String get continueAction => 'Devam Et';

  @override
  String get invalidInvitation => 'Davet Bağlantısı Geçersiz';

  @override
  String get backToLogin => 'Giriş Ekranına Dön';

  @override
  String get registerWithInvitation => 'Davet Bağlantısı ile Kaydol';

  @override
  String get customerRole => 'Müşteri';

  @override
  String get expertRole => 'Uzman';

  @override
  String get corporateRole => 'Kurumsal';

  @override
  String get optiyouTeamRole => 'Optiyou Ekibi';

  @override
  String get homeLoadError => 'Ana sayfa bilgileri yüklenemedi.';

  @override
  String get partialHomeDataWarning =>
      'Bazı güncel bilgiler yüklenemedi. Diğer bölümleri kullanmaya devam edebilirsiniz.';

  @override
  String get dataUnavailable => 'Bilgi alınamadı';

  @override
  String get noAssessmentYet => 'Henüz değerlendirme yok';

  @override
  String get noAssessmentYetDescription =>
      'Hesabınıza bir ölçüm sonucu bağlandığında burada görüntülenecektir.';

  @override
  String get noActiveOrder => 'Aktif sipariş yok';

  @override
  String get noActiveOrderDescription =>
      'Yeni veya devam eden bir siparişiniz bulunmuyor.';

  @override
  String get recommendationPending => 'Uzman önerisi bekleniyor';

  @override
  String get recommendationPendingDescription =>
      'Değerlendirmenize ait uzman önerisi eklendiğinde burada görüntülenecektir.';

  @override
  String get assessmentSummaryAvailable =>
      'Değerlendirme sonucunuz hazır. Ayrıntılı bulguları ve ölçümleri sonuç ekranından inceleyebilirsiniz.';

  @override
  String orderedOn(String date) {
    return 'Sipariş tarihi: $date';
  }

  @override
  String get browseProducts => 'Ürünleri İncele';

  @override
  String get productSelectionPendingDescription =>
      'Size uygun ürün henüz belirlenmedi. Ürün seçimi uzman değerlendirmesiyle kesinleştirilecektir.';

  @override
  String get notSpecified => 'Belirtilmedi';

  @override
  String helloUser(String name) {
    return 'Merhaba, $name';
  }

  @override
  String get customerHomeIntro =>
      'Ayak sağlığınızla ilgili değerlendirmelerinizi, önerilerinizi ve siparişlerinizi buradan takip edebilirsiniz.';

  @override
  String get viewMyAssessment => 'Değerlendirmemi görüntüle';

  @override
  String get trackMyOrder => 'Siparişimi takip et';

  @override
  String get latestAssessment => 'Son değerlendirme';

  @override
  String get activeOrder => 'Aktif sipariş';

  @override
  String get recommendedProduct => 'Önerilen ürün';

  @override
  String get personalRecommendation => 'Size özel öneri';

  @override
  String get orderProcess => 'Sipariş süreci';

  @override
  String get orderReceived => 'Alındı';

  @override
  String get design => 'Tasarım';

  @override
  String get production => 'Üretim';

  @override
  String get shipped => 'Kargoda';

  @override
  String get delivered => 'Teslim';

  @override
  String estimatedDelivery(String date) {
    return 'Tahmini teslim: $date';
  }

  @override
  String get goToOrderDetails => 'Sipariş detayına git';

  @override
  String get specialistRecommendation => 'Uzmanınızdan öneri';

  @override
  String updatedOn(String date) {
    return 'Güncelleme: $date';
  }

  @override
  String get yourLatestAssessment => 'Son değerlendirmeniz';

  @override
  String get viewDetailedAssessment => 'Detaylı değerlendirmeyi görüntüle';

  @override
  String get productRecommendedForYou => 'Size önerilen ürün';

  @override
  String get viewProduct => 'Ürünü incele';

  @override
  String get haveAQuestion => 'Bir sorunuz mu var?';

  @override
  String get supportTeamCanHelp => 'Destek ekibimiz size yardımcı olabilir.';

  @override
  String get getSupport => 'Destek al';

  @override
  String get assessmentReady => 'Değerlendirme hazır';

  @override
  String get assessmentMockSummary =>
      'Ayak değerlendirmenizde kemer desteği ihtiyacı ve topuk bölgesinde yük artışı gözlemlendi.';

  @override
  String get archSupportNeed => 'Kemer desteği ihtiyacı';

  @override
  String get increasedHeelLoad => 'Topuk yükünde artış';

  @override
  String get personalSupportRecommendation => 'Kişiye özel destek önerisi';

  @override
  String get specialistMockNote =>
      'Uzun süre ayakta kaldığınız günlerde destekli iç taban kullanmanız ve ürününüzü düzenli aralıklarla kontrol ettirmeniz önerilir.';

  @override
  String get inProduction => 'Üretimde';

  @override
  String get customOrthopedicInsole => 'Kişiye Özel Ortopedik İç Taban';

  @override
  String get customInsole => 'Kişiye Özel İç Taban';

  @override
  String get customInsoleDescription =>
      'Günlük kullanımda basınç dağılımını dengelemeye ve ayağınıza uygun desteği sağlamaya yardımcı olur.';

  @override
  String get customInsoleReason =>
      'Son değerlendirmenizde görülen kemer desteği ihtiyacına göre önerildi.';

  @override
  String get enterEmail => 'Lütfen e-posta girin.';

  @override
  String get enterPassword => 'Lütfen şifrenizi girin.';

  @override
  String get genericError => 'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String get invalidCredentials => 'E-posta veya şifre hatalı.';

  @override
  String get emailNotConfirmed => 'E-posta adresiniz doğrulanmamış.';

  @override
  String get tooManyAttempts => 'Çok fazla deneme yaptınız. Lütfen bekleyin.';

  @override
  String get enterValidEmail => 'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get resetLinkSent =>
      'Şifre sıfırlama bağlantısı gönderildi. Lütfen e-posta kutunuzu kontrol edin.';

  @override
  String get sending => 'Gönderiliyor...';

  @override
  String get saving => 'Kaydediliyor...';

  @override
  String get setPasswordDescription =>
      'Hesabınız için yeni bir şifre belirleyin.';

  @override
  String get saveNewPassword => 'Yeni Şifreyi Kaydet';

  @override
  String get enterPasswordTwice => 'Lütfen yeni şifrenizi iki kez girin.';

  @override
  String get passwordMinEight => 'Şifre en az 8 karakter olmalı.';

  @override
  String get passwordMinSix => 'Şifre en az 6 karakter olmalıdır.';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor.';

  @override
  String get registrationComplete => 'Kayıt Tamamlandı!';

  @override
  String get enterFirstAndLastName => 'Lütfen adınızı ve soyadınızı girin.';

  @override
  String get selectUserType => 'Lütfen kullanıcı tipini seçin.';

  @override
  String get qrFootHealthEcosystem => 'Ayak Sağlığı Ekosistemi';

  @override
  String get qrDigitalManufacturing => 'Dijital Üretim';

  @override
  String get qrPerformanceSupport => 'Performans Desteği';

  @override
  String get qrWelcomeTitle => 'Optiyou ekosistemine hoş geldiniz.';

  @override
  String get qrWelcomeDescription =>
      'Ölçüm, uzman değerlendirmesi ve sonuç erişimini tek bir kullanıcı yolculuğunda birleştiriyoruz. QR bağlantısı üzerinden hesabınızı oluşturup kişisel sonuçlarınıza güvenli şekilde ulaşabilirsiniz.';

  @override
  String get qrCheckingLink => 'Sonuç erişim bağlantısı kontrol ediliyor...';

  @override
  String get qrLinkReady =>
      'Bu bağlantı kişisel sonuç erişimi için hazır. Hesap oluşturma veya giriş işlemini aynı sayfa içinde tamamlayabilirsiniz.';

  @override
  String get qrInviteNotFound =>
      'Bu QR kod ile ilişkili ölçüm daveti bulunamadı. Yine de hesap oluşturup uygulamaya geçebilirsiniz.';

  @override
  String qrInviteCheckError(String error) {
    return 'QR daveti kontrol edilirken hata oluştu: $error';
  }

  @override
  String get qrInviteAlreadyUsed =>
      'Bu QR/davet bağlantısı daha önce kullanılmış.';

  @override
  String get qrInviteCancelled => 'Bu QR/davet bağlantısı iptal edilmiş.';

  @override
  String get qrInviteExpired => 'Bu QR/davet bağlantısının süresi dolmuş.';

  @override
  String get qrGoToRegistration => 'Kullanıcı Kaydına Geç';

  @override
  String get qrRegistrationEyebrow => 'Kullanıcı kaydı';

  @override
  String get qrRegistrationTitle =>
      'Sonuçlarınızı size ait güvenli hesaba bağlayın.';

  @override
  String get qrRegistrationDescription =>
      'QR bağlantısı ölçüm kaydınızı tanır. Hesap oluşturduğunuzda veya giriş yaptığınızda değerlendirme sonuçları ve ürün önerisi uygulama hesabınızla ilişkilendirilir.';

  @override
  String get qrCreateAccount => 'Hesap Oluştur';

  @override
  String get qrCreateAndClaim => 'Hesap Oluştur ve Sonuçlarıma Bağla';

  @override
  String get qrCreateAndContinue => 'Hesap Oluştur ve Devam Et';

  @override
  String get qrLoginAndClaim => 'Giriş Yap ve Sonuçlarıma Bağla';

  @override
  String get qrLoginAndContinue => 'Giriş Yap ve Uygulamaya Geç';

  @override
  String get qrAcceptRequiredDocuments =>
      'Devam etmek için sözleşme ve bilgilendirme metinlerini kabul etmelisiniz.';

  @override
  String get qrRegistrationEmailConfirmation =>
      'Kayıt oluşturuldu. E-posta onayı aktifse, gönderilen onay bağlantısından sonra bu sayfadan giriş yapabilirsiniz.';

  @override
  String get qrAccountCreatedAndLinked =>
      'Hesabınız oluşturuldu ve sonuçlarınız hesabınıza bağlandı.';

  @override
  String get qrAccountCreated =>
      'Hesabınız oluşturuldu. Uygulamaya geçebilirsiniz.';

  @override
  String qrRegistrationFailed(String error) {
    return 'Kayıt tamamlanamadı: $error';
  }

  @override
  String get qrEnterEmailAndPassword => 'E-posta ve şifre girin.';

  @override
  String get qrLoginAndLinked =>
      'Giriş yapıldı ve sonuçlarınız hesabınıza bağlandı.';

  @override
  String get qrLoginSuccessful => 'Giriş yapıldı. Uygulamaya geçebilirsiniz.';

  @override
  String qrLoginFailed(String error) {
    return 'Giriş tamamlanamadı: $error';
  }

  @override
  String get qrAuthenticationRequiredForInvite =>
      'Davet hesabınıza bağlanmadan önce oturum açmanız gerekiyor.';

  @override
  String get qrEmailAlreadyRegistered =>
      'Bu e-posta adresi zaten kayıtlı. Giriş sekmesini kullanabilirsiniz.';

  @override
  String get qrDocumentNotFound => 'Belge bulunamadı.';

  @override
  String get qrInviteEmailEditable =>
      'Davetle gelen e-posta adresini gerekirse değiştirebilirsiniz.';

  @override
  String get qrAccessReadyTitle => 'Sonuçlarınıza erişim hazır.';

  @override
  String get qrAccessTitle => 'Sonuçlarınıza erişin.';

  @override
  String get qrAccessDescription =>
      'Kayıt veya giriş işlemini bu sayfadan tamamlayıp sonuçlarınıza güvenli şekilde ulaşabilirsiniz.';

  @override
  String get qrStartSecureAccess => 'Güvenli Erişimi Başlat';

  @override
  String get qrAccessIntroTitle =>
      'Hesabınızı oluşturun ve sonuçlarınıza bağlanın.';

  @override
  String get qrAccessIntroDescription =>
      'Kişisel sonuçlarınızı güvenli şekilde görüntüleyebilmeniz için ölçüm kaydınızı size ait kullanıcı hesabıyla ilişkilendiriyoruz.';

  @override
  String get qrInviteVerified =>
      'Davet doğrulandı. Formdaki e-posta adresini kontrol edip gerekirse değiştirebilirsiniz.';

  @override
  String get qrEmailConfirmationHint =>
      'E-posta onayı aktif görünüyor. Onaydan sonra aynı sayfadan giriş yapabilirsiniz.';

  @override
  String get qrLegalConsentPrefix => 'Devam ederek ';

  @override
  String get qrMembershipAgreement => 'Üyelik Sözleşmesi';

  @override
  String get qrPrivacyNotice => 'Aydınlatma Metni';

  @override
  String get qrLegalAnd => ' ve ';

  @override
  String get qrTermsOfUse => 'Kullanım Koşulları';

  @override
  String get qrLegalConsentSuffix =>
      '’nı okuduğumu ve kabul ettiğimi onaylıyorum.';

  @override
  String get qrReady => 'Hazırsınız.';

  @override
  String get qrClaimSuccess =>
      'Sonuçlarınız hesabınıza bağlandı. Değerlendirme sonuçlarınızı, kullanım önerilerinizi ve destek seçeneklerinizi uygulama içinde görüntüleyebilirsiniz.';

  @override
  String get qrAccountReady =>
      'Hesabınız hazır. Optiyou uygulamasına geçebilirsiniz.';

  @override
  String get qrOpenApp => 'Uygulamaya Geç';

  @override
  String get qrResults => 'Sonuçlar';

  @override
  String get qrResultsTitle =>
      'Değerlendirme sonuçları, ürün önerisi ve takip bilgileri tek yerde.';

  @override
  String get qrResultsDescription =>
      'Kayıt veya giriş tamamlandığında ölçüm geçmişinizi, uzman değerlendirmesini ve size önerilen ürünü bu sayfanın devamında görüntüleyebilirsiniz.';

  @override
  String get qrAnalysisSummary => 'Değerlendirme özeti';

  @override
  String get qrAnalysisSummaryText =>
      'Basınç, denge ve destek ihtiyacı sade başlıklarla sunulur.';

  @override
  String get qrSuitableProduct => 'Size uygun ürün önerisi';

  @override
  String get qrSuitableProductText =>
      'Değerlendirme sonucuna göre ürün listemizden uygun çözüm seçilir.';

  @override
  String get qrTrackingHistory => 'Takip geçmişi';

  @override
  String get qrTrackingHistoryText =>
      'Sonraki ölçümlerde değişim ve kullanım notları karşılaştırılabilir.';

  @override
  String get qrOpenResults => 'Sonuçları Aç';

  @override
  String get qrPersonalResults => 'Kişisel sonuç görünümü';

  @override
  String get qrAnalysisScore => 'Değerlendirme skoru';

  @override
  String get qrSupportNeed => 'Destek ihtiyacı';

  @override
  String get qrMedium => 'Orta';

  @override
  String get qrPersonalInsole => 'Kişisel iç taban';

  @override
  String get qrInlineResultsEyebrow => 'Güvenli kişisel alan';

  @override
  String get qrInlineResultsTitle => 'Değerlendirme sonuçlarınız';

  @override
  String get qrInlineResultsDescription =>
      'Ölçüm bulgularınız ve görselleriniz bu sayfanın devamında güvenli biçimde sunulur.';

  @override
  String analysisResultsLoadError(String error) {
    return 'Değerlendirme sonuçları yüklenirken hata oluştu: $error';
  }

  @override
  String get noAnalysisResults => 'Değerlendirme sonucu bulunamadı.';

  @override
  String get analysisWillAppear =>
      'Ölçüm sonuçlarınız hesabınıza bağlandığında burada görüntülenecektir.';

  @override
  String get checkAgain => 'Tekrar Kontrol Et';

  @override
  String get myProfile => 'Profilim';

  @override
  String get customerProfile => 'Müşteri Profili';

  @override
  String get personalInformation => 'Kişisel Bilgiler';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get phone => 'Telefon';

  @override
  String get role => 'Rol';

  @override
  String get shortSummary => 'Kısa Özet';

  @override
  String get totalAnalyses => 'Toplam Değerlendirme';

  @override
  String get myInsoleImages => 'İç Taban Görsellerim';

  @override
  String get uploadInsoleImage => 'İç Taban Görseli Yükle';

  @override
  String get noInsoleImages => 'Henüz yüklenmiş iç taban görseli bulunmuyor.';

  @override
  String get imageUnavailable => 'Görsel yok';

  @override
  String get insoleImagesTemporaryNote =>
      'Bu alana eklediğiniz görseller yalnızca bu oturumda önizlenir; henüz hesabınıza kaydedilmez.';

  @override
  String get assessmentResults => 'Değerlendirme Sonuçları';

  @override
  String get assessmentNotFound => 'Değerlendirme sonucu bulunamadı.';

  @override
  String get preparingAssessment => 'Değerlendirme verileri hazırlanıyor...';

  @override
  String get measurementHistoryTitle => 'Ölçüm Geçmişi';

  @override
  String get selectMeasurementSession =>
      'Görüntülemek istediğiniz ölçüm oturumunu seçin.';

  @override
  String get preparingPdf => 'PDF hazırlanıyor...';

  @override
  String get savePdf => 'PDF Kaydet';

  @override
  String get assessmentIntro =>
      '3D anatomik ölçümler, görsel incelemeler ve plantar basınç ölçüm sonuçları.';

  @override
  String get locationNotSpecified => 'Konum belirtilmedi';

  @override
  String get anatomicalMeasurements => 'Anatomik Ölçümler';

  @override
  String get anatomicalMeasurementsSubtitle =>
      '3D taramadan alınan anatomik ölçüm değerleri.';

  @override
  String get noParsedScanReport =>
      'Bu ölçüm için ayrıştırılmış 3D tarama raporu bulunmuyor.';

  @override
  String get left => 'Sol';

  @override
  String get right => 'Sağ';

  @override
  String get leftFoot => 'Sol Ayak';

  @override
  String get rightFoot => 'Sağ Ayak';

  @override
  String get footLength => 'Ayak Uzunluğu';

  @override
  String get soleLength => 'Taban Uzunluğu';

  @override
  String get footWidth => 'Ayak Genişliği';

  @override
  String get forefootWidth => 'Parmak Önü Genişliği';

  @override
  String get toeWidth => 'Parmak Genişliği';

  @override
  String get archLength => 'Ark Uzunluğu';

  @override
  String get archHeight => 'Ark Yüksekliği';

  @override
  String get outerArchWidth => 'Dış Ark Genişliği';

  @override
  String get heelWidth => 'Topuk Genişliği';

  @override
  String get firstMetatarsalLength => '1. Metatars Uzunluğu';

  @override
  String get fifthMetatarsalLength => '5. Metatars Uzunluğu';

  @override
  String get metatarsalJointHeight => 'Metatars Eklem Yüksekliği';

  @override
  String get archStructure => 'Ark ve Kemer Yapısı';

  @override
  String get archStructureSubtitle =>
      'Ayak kemeri yüksekliği, genişliği ve yüzey formu.';

  @override
  String get archHeightMap => 'Ark Yükseklik Haritası';

  @override
  String get archIndex => 'Ark İndeksi';

  @override
  String get archSectionImage => 'Ark Kesit Görüntüsü';

  @override
  String get archWidthIndex => 'Ark Genişlik İndeksi';

  @override
  String get footFormHallux => 'Ayak Formu ve Başparmak Hizalanması';

  @override
  String get footFormHalluxSubtitle =>
      'Ön ayak formu ve halluks açısının iki taraflı görünümü.';

  @override
  String get footImage => 'Ayak Görüntüsü';

  @override
  String get halluxAngleType => 'Halluks Açısı ve Tipi';

  @override
  String get rearfootPronation => 'Arka Ayak ve Pronasyon';

  @override
  String get rearfootPronationSubtitle =>
      'Topuk-bilek, pronasyon ve diz hizalanması.';

  @override
  String get ankleAlignment => 'Ayak-Bilek Hizalanması';

  @override
  String get pronationAngleHeelType => 'Pronasyon Açısı ve Topuk Tipi';

  @override
  String get kneeAngleAlignment => 'Diz Açısı ve Hizalanması';

  @override
  String get findingsAndImages => 'Değerlendirme Bulguları ve Görseller';

  @override
  String get findingsAndImagesSubtitle =>
      'Sol ve sağ ayak açıklamaları, görselleri ve değerleri birlikte gösterilir.';

  @override
  String get loadingImages => 'Görseller yükleniyor...';

  @override
  String get productAssessment => 'Ürün Değerlendirmesi';

  @override
  String get productAssessmentSubtitle =>
      'Değerlendirme sonucuna göre önerilen ürün.';

  @override
  String get productRecommended => 'Size Önerilen Ürün';

  @override
  String get productNotDetermined => 'Ürün belirlenmedi.';

  @override
  String get imageNotFound => 'Görsel bulunamadı.';

  @override
  String get imagePathNotFound => 'Görsel yolu bulunamadı.';

  @override
  String get imageCouldNotOpen => 'Görsel açılamadı.';

  @override
  String get noData => 'Veri bulunmuyor';

  @override
  String get normal => 'Normal';

  @override
  String get mild => 'Hafif';

  @override
  String get moderate => 'Orta Düzey';

  @override
  String get severe => 'İleri Düzey';

  @override
  String get highArch => 'Yüksek Ark';

  @override
  String get normalArch => 'Normal Ark';

  @override
  String get mildFlatFoot => 'Hafif Düz Taban';

  @override
  String get moderateFlatFoot => 'Orta Düzey Düz Taban';

  @override
  String get severeFlatFoot => 'İleri Düzey Düz Taban';

  @override
  String get plantarPressureMeasurements => 'Plantar Basınç Ölçümleri';

  @override
  String get plantarPressureSubtitle =>
      'Seçili oturum sırasında kaydedilen basınç ölçüm kayıtları.';

  @override
  String get noPressureRecordings =>
      'Bu oturum için kayıtlı plantar basınç ölçümü bulunmuyor.';

  @override
  String get selectPressureRecording =>
      'Görüntülemek için bir basınç kaydı seçin.';

  @override
  String get pressureHeatmap => 'Basınç Isı Haritası';

  @override
  String frameCounter(int current, int total) {
    return 'Kare $current/$total';
  }

  @override
  String get loadDistribution => 'Yük Dağılımı';

  @override
  String get weight => 'Kilo';

  @override
  String get leftRightLoad => 'Sol / Sağ Yük Dağılımı';

  @override
  String get forefootHeelLoad => 'Ön Ayak / Topuk Dağılımı';

  @override
  String get forefoot => 'Ön Ayak';

  @override
  String get heel => 'Topuk';

  @override
  String get frameCount => 'Kare Sayısı';

  @override
  String get duration => 'Süre';

  @override
  String get maximumRawValue => 'Maksimum Ham Değer';

  @override
  String get averageRawValue => 'Ortalama Ham Değer';

  @override
  String get physicalValueUnavailable => 'Fiziksel değer hesaplanamadı';

  @override
  String framesRecorded(int count) {
    return '$count kare';
  }

  @override
  String get footLengthDescription =>
      'Topuk ile en uzun parmak arasındaki mesafe.';

  @override
  String get soleLengthDescription => 'Ayak tabanının anatomik temas uzunluğu.';

  @override
  String get footWidthDescription => 'Ön ayaktaki en geniş anatomik mesafe.';

  @override
  String get forefootWidthDescription =>
      'Parmak kökleri seviyesindeki genişlik.';

  @override
  String get archLengthDescription => 'Medial longitudinal ark uzunluğu.';

  @override
  String get archHeightDescription => 'Ayak kemerinin maksimum yüksekliği.';

  @override
  String get outerArchWidthDescription => 'Ark bölgesinin dış genişlik ölçümü.';

  @override
  String get heelWidthDescription => 'Topuk bölgesinin toplam genişliği.';

  @override
  String get firstMetatarsalDescription =>
      'Birinci metatarsal anatomik uzunluğu.';

  @override
  String get fifthMetatarsalDescription =>
      'Beşinci metatarsal anatomik uzunluğu.';

  @override
  String get metatarsalJointDescription =>
      'Birinci metatars eklem bölgesindeki yükseklik.';

  @override
  String get halluxNoData =>
      'Halluks açısına ilişkin değerlendirme verisi bulunmuyor.';

  @override
  String get halluxNormal =>
      'Başparmak hizalanması normal açı aralığında görünüyor.';

  @override
  String get halluxMild =>
      'Başparmak açısında hafif düzeyde hizalanma değişimi görülüyor.';

  @override
  String get halluxMarked =>
      'Başparmak açısında belirgin hizalanma değişimi görülüyor.';

  @override
  String get pronationNoData =>
      'Pronasyon açısına ilişkin değerlendirme verisi bulunmuyor.';

  @override
  String get pronationNormal =>
      'Arka ayak hizalanması normal açı aralığında görünüyor.';

  @override
  String get pronationMild =>
      'Arka ayakta hafif pronasyon veya supinasyon eğilimi görülüyor.';

  @override
  String get pronationMarked =>
      'Arka ayak hizalanmasında belirgin açı değişimi görülüyor.';

  @override
  String get sessionIdMissing => 'Bu değerlendirme için oturum ID bulunamadı.';

  @override
  String get assessmentImagesUnavailable =>
      'Bu oturum için kullanılabilir değerlendirme görseli bulunamadı.';

  @override
  String assessmentImagesLoadError(String error) {
    return 'Değerlendirme görselleri yüklenemedi: $error';
  }

  @override
  String pressureRecordingsLoadError(String error) {
    return 'Basınç ölçüm kayıtları yüklenemedi: $error';
  }

  @override
  String pressureDataOpenError(String error) {
    return 'Basınç kayıt verisi açılamadı: $error';
  }

  @override
  String get leftArchDescriptionUnavailable =>
      'Sol ark yapısına ilişkin açıklama bulunmuyor.';

  @override
  String get rightArchDescriptionUnavailable =>
      'Sağ ark yapısına ilişkin açıklama bulunmuyor.';

  @override
  String get pdfSaved => 'PDF raporu kaydedildi.';

  @override
  String pdfCreateError(String error) {
    return 'PDF raporu oluşturulamadı: $error';
  }

  @override
  String get myOrders => 'Siparişlerim';

  @override
  String get customerOrdersIntro =>
      'Siparişlerinizin üretim ve teslimat durumunu buradan takip edebilirsiniz.';

  @override
  String get orderManagementIntro =>
      'Sipariş akışını ve üretim durumlarını buradan takip edebilirsiniz.';

  @override
  String get orderSearchHint => 'Sipariş numarası, ürün veya durum ile ara';

  @override
  String ordersLoadError(String error) {
    return 'Siparişler yüklenirken hata oluştu: $error';
  }

  @override
  String get customerAccountNotLinked =>
      'Hesabınızla eşleşen müşteri kaydı bulunamadı.';

  @override
  String get noCustomerOrders => 'Henüz size ait bir sipariş bulunmuyor.';

  @override
  String get noSavedOrders => 'Kayıtlı sipariş bulunamadı.';

  @override
  String get productLabel => 'Ürün';

  @override
  String get netAmountLabel => 'Net Tutar';

  @override
  String orderedChip(String date) {
    return 'Sipariş: $date';
  }

  @override
  String shippedChip(String date) {
    return 'Kargo: $date';
  }

  @override
  String deliveredChip(String date) {
    return 'Teslim: $date';
  }

  @override
  String get orderDetailTitle => 'Sipariş Detayı';

  @override
  String get orderStatusUpdated => 'Sipariş durumu güncellendi.';

  @override
  String orderStatusUpdateError(String error) {
    return 'Sipariş güncellenemedi: $error';
  }

  @override
  String get orderInformation => 'Sipariş Bilgileri';

  @override
  String get orderNumberLabel => 'Sipariş Numarası';

  @override
  String get orderDateLabel => 'Sipariş Tarihi';

  @override
  String get shipmentDateLabel => 'Kargo Tarihi';

  @override
  String get deliveryDateLabel => 'Teslim Tarihi';

  @override
  String get deliveryAddressTitle => 'Teslimat Adresi';

  @override
  String get deliveryAddressMissing =>
      'Bu sipariş için teslimat adresi bulunamadı.';

  @override
  String get updateOrderStatus => 'Durumu Güncelle';

  @override
  String get orderStatusLabel => 'Sipariş Durumu';

  @override
  String get orderFlowTitle => 'Üretim ve Sipariş Akışı';

  @override
  String completionRate(int percent) {
    return 'Tamamlanma Oranı: $percent%';
  }

  @override
  String get priceInformation => 'Fiyat Bilgileri';

  @override
  String get grossAmount => 'Brüt Tutar';

  @override
  String get discountAmount => 'İndirim';

  @override
  String get currency => 'Para Birimi';

  @override
  String get stepCompleted => 'Tamamlandı';

  @override
  String get stepWaiting => 'Bekliyor';

  @override
  String get pendingStatus => 'Beklemede';

  @override
  String get designingStatus => 'Tasarımda';

  @override
  String get productionStatus => 'Üretimde';

  @override
  String get shippedStatus => 'Kargoda';

  @override
  String get deliveredStatus => 'Teslim Edildi';

  @override
  String get cancelledStatus => 'İptal Edildi';

  @override
  String get insoleProduct => 'Tabanlık';

  @override
  String get sportsInsoleProduct => 'Spor Tabanlık';

  @override
  String get sandalProduct => 'Sandalet';

  @override
  String get orderReceivedDescription =>
      'Siparişiniz sisteme kaydedildi ve işleme alındı.';

  @override
  String get designPreparation => 'Tasarım Hazırlığı';

  @override
  String get designPreparationDescription =>
      'Teknik tasarım ve üretim hazırlıkları yapılıyor.';

  @override
  String get productionDescription => 'Ürününüz üretim sürecinde hazırlanıyor.';

  @override
  String get handedToCarrier => 'Kargoya Verildi';

  @override
  String get shippedDescription =>
      'Siparişiniz sevkiyata hazırlanarak kargo firmasına teslim edildi.';

  @override
  String get deliveredDescription => 'Siparişiniz teslimat adresine ulaştı.';

  @override
  String get orderCancelledDescription =>
      'Bu sipariş iptal edildi. Ayrıntılı bilgi için destek ekibiyle iletişime geçebilirsiniz.';

  @override
  String get actingUser => 'İşlem Yapan Kullanıcı';

  @override
  String get internalOrderId => 'Sipariş ID';

  @override
  String get internalSessionId => 'Oturum ID';

  @override
  String get internalPatientId => 'Müşteri ID';

  @override
  String get internalClinicId => 'Klinik ID';

  @override
  String get internalExpertId => 'Uzman ID';

  @override
  String get internalAssignedUserId => 'Atanan OptiYou Kullanıcı ID';

  @override
  String get profileMenuTooltip => 'Profil menüsü';

  @override
  String get storeIntro =>
      'Kişiselleştirilmiş ürünleri inceleyin ve son değerlendirmenizle ilişkili bilgileri görün.';

  @override
  String get latestMeasurement => 'Son Değerlendirme';

  @override
  String get sessionLabel => 'Oturum';

  @override
  String get dateLabel => 'Tarih';

  @override
  String get locationLabel => 'Konum';

  @override
  String get linkedMeasurementMessage =>
      'Ürün uygunluğu son değerlendirme verileriniz ve uzman görüşüyle birlikte belirlenir.';

  @override
  String get noLinkedMeasurementTitle => 'Bağlı değerlendirme bulunamadı';

  @override
  String get noLinkedMeasurementDescription =>
      'Ürünleri inceleyebilirsiniz; kişiselleştirilmiş üretim için önce bir ölçüm kaydının hesabınıza bağlanması gerekir.';

  @override
  String get mainProducts => 'Kişiselleştirilmiş Ürünler';

  @override
  String get mainProductsSubtitle =>
      'Ölçüm ve uzman değerlendirmesine göre üretilen temel ürünler.';

  @override
  String get accessoryProducts => 'Tamamlayıcı Ürünler';

  @override
  String get accessoryProductsSubtitle =>
      'Günlük kullanım, konfor ve bakım için yardımcı seçenekler.';

  @override
  String get productAbout => 'Ürün Hakkında';

  @override
  String get whoSuitable => 'Kimler için uygun?';

  @override
  String get whyRecommended => 'Uygunluk Notu';

  @override
  String get purchase => 'Satın Al';

  @override
  String get storeRecommendationDisclaimer =>
      'Bu açıklama genel bilgilendirme amaçlıdır. Nihai ürün seçimi, ölçüm sonuçlarınız ve uzman değerlendirmesiyle kesinleştirilir.';

  @override
  String get paymentInvalidUrl => 'Geçersiz ödeme bağlantısı alındı.';

  @override
  String get paymentPageOpenError => 'Ödeme sayfası açılamadı.';

  @override
  String paymentStartError(String error) {
    return 'Ödeme başlatılamadı: $error';
  }

  @override
  String get paymentResultTitle => 'Ödeme Sonucu';

  @override
  String get paymentCheckingTitle => 'Ödeme doğrulanıyor';

  @override
  String get paymentCheckingDescription =>
      'Ödeme sağlayıcısından güvenli sonuç bekleniyor. Ödeme sayfasını tamamladıktan sonra bu ekran otomatik güncellenir.';

  @override
  String get paymentSuccessTitle => 'Ödeme Başarılı';

  @override
  String get paymentSuccessDescription =>
      'Ödemeniz doğrulandı ve siparişiniz oluşturuldu.';

  @override
  String get paymentFailedTitle => 'Ödeme Tamamlanamadı';

  @override
  String get paymentFailedDescription =>
      'Ödeme başarısız oldu veya işlem iptal edildi. Kartınızdan çekim yapıldığını düşünüyorsanız destek ekibiyle iletişime geçin.';

  @override
  String paymentStatusLoadError(String error) {
    return 'Ödeme durumu doğrulanamadı: $error';
  }

  @override
  String orderNumberValue(String orderNo) {
    return 'Sipariş numarası: $orderNo';
  }

  @override
  String paidAmountValue(String amount) {
    return 'Ödenen tutar: $amount';
  }

  @override
  String get goToMyOrders => 'Siparişlerime Git';

  @override
  String ordersNavigationError(String error) {
    return 'Siparişler sayfası açılamadı: $error';
  }

  @override
  String addressLoadError(String error) {
    return 'Adresler yüklenemedi: $error';
  }

  @override
  String addressSaveError(String error) {
    return 'Adres kaydedilemedi: $error';
  }

  @override
  String get deliveryAddressDescription =>
      'Ödeme sayfasına geçmeden önce teslimat adresinizi seçin veya yeni bir adres girin.';

  @override
  String get addNewAddress => 'Yeni Adres Ekle';

  @override
  String get backToList => 'Listeye Dön';

  @override
  String get continueToPayment => 'Ödemeye Geç';

  @override
  String get selectDeliveryAddress => 'Lütfen bir teslimat adresi seçin.';

  @override
  String get noSavedAddress =>
      'Kayıtlı adres bulunamadı. Yeni adres ekleyerek devam edin.';

  @override
  String get addressTitle => 'Adres Başlığı';

  @override
  String get city => 'İl';

  @override
  String get district => 'İlçe';

  @override
  String get addressLine => 'Açık Adres';

  @override
  String requiredField(String field) {
    return '$field zorunludur.';
  }

  @override
  String get customInsoleFullDescription =>
      'Kişiye özel iç taban, son ölçüm verileriniz temel alınarak ayağınıza uygun destek geometrisiyle hazırlanır. Günlük kullanımda konforu ve yük dağılımını desteklemeyi amaçlar.';

  @override
  String get customInsoleUsage =>
      'Uzun süre ayakta kalan, günlük konforunu artırmak isteyen veya kişisel destek ihtiyacı uzman tarafından belirlenen kullanıcılar içindir.';

  @override
  String get sportsInsoleTitle => 'Spor İç Tabanlığı';

  @override
  String get sportsInsoleShort =>
      'Aktif yaşam ve spor kullanımı için dinamik destek sunar.';

  @override
  String get sportsInsoleFull =>
      'Spor iç tabanlığı; yürüyüş, antrenman ve hareketli kullanımda ayağı desteklemek üzere kişiselleştirilir.';

  @override
  String get sportsInsoleUsage =>
      'Düzenli spor yapan veya gün içinde yüksek hareket yoğunluğuna sahip kullanıcılar içindir.';

  @override
  String get heelPadTitle => 'Topuk Pedi';

  @override
  String get heelPadShort =>
      'Topuk bölgesinde ek yastıklama sağlayan tamamlayıcı ürün.';

  @override
  String get heelPadFull =>
      'Topuk pedi, topuk bölgesindeki teması yumuşatmak ve günlük kullanım konforunu desteklemek amacıyla kullanılır.';

  @override
  String get heelPadUsage =>
      'Topuk bölgesinde ek yastıklama ihtiyacı olan kullanıcılar içindir.';

  @override
  String get metPadTitle => 'Metatarsal Destek Pedi';

  @override
  String get metPadShort =>
      'Ön ayak bölgesine ek destek sağlayan tamamlayıcı ürün.';

  @override
  String get metPadFull =>
      'Metatarsal destek pedi, ön ayak bölgesindeki teması ve konforu desteklemek amacıyla kullanılır.';

  @override
  String get metPadUsage =>
      'Ön ayak bölgesinde ek destek ihtiyacı uzman tarafından belirlenen kullanıcılar içindir.';

  @override
  String get cleaningSprayTitle => 'Temizleme Spreyi';

  @override
  String get cleaningSprayShort =>
      'İç taban ve yardımcı ürünlerin bakımı için pratik çözüm.';

  @override
  String get cleaningSprayFull =>
      'Temizleme spreyi, ürünlerin düzenli bakımına ve hijyenik kullanımına yardımcı olur.';

  @override
  String get cleaningSprayUsage =>
      'Kişiselleştirilmiş ürünlerinin bakımını düzenli yapmak isteyen kullanıcılar içindir.';

  @override
  String get carryCaseTitle => 'Taşıma Kılıfı';

  @override
  String get carryCaseShort =>
      'İç tabanları korumak ve taşımak için kompakt kılıf.';

  @override
  String get carryCaseFull =>
      'Taşıma kılıfı, iç tabanları çanta içinde koruyarak daha düzenli taşımaya yardımcı olur.';

  @override
  String get carryCaseUsage =>
      'İç tabanlarını yanında taşıyan kullanıcılar içindir.';

  @override
  String get supportCenter => 'Destek Merkezi';

  @override
  String get customerSupportIntro =>
      'Siparişleriniz, ürünleriniz ve kullanım süreci hakkında destek alabilirsiniz.';

  @override
  String get expertSupportIntro =>
      'Ölçüm süreçleri, kullanıcı kayıtları ve sipariş yönetimi hakkında destek alabilirsiniz.';

  @override
  String get teamSupportIntro =>
      'Operasyon, kullanıcı akışı ve sistem yönetimi için destek seçeneklerini kullanabilirsiniz.';

  @override
  String get genericSupportIntro =>
      'Yardıma ihtiyacınız varsa aşağıdaki iletişim veya sorun bildirim seçeneklerini kullanabilirsiniz.';

  @override
  String get quickSupport => 'Hızlı Destek';

  @override
  String get quickSupportSubtitle =>
      'Destek ekibine telefon veya e-posta ile ulaşın.';

  @override
  String get callSupport => 'Destek Sorumlusunu Ara';

  @override
  String get callSupportDescription =>
      'Aşağıdaki numaralardan destek sorumlusuna ulaşabilirsiniz.';

  @override
  String get tapToCall => 'Aramak için seçin';

  @override
  String get actionCouldNotOpen => 'Bu işlem cihazda açılamadı.';

  @override
  String get reportIssue => 'Sorun Bildir';

  @override
  String get sendIssue => 'Bildirimi Hazırla';

  @override
  String get clinicLabel => 'Klinik';

  @override
  String get messageLabel => 'Mesaj';

  @override
  String get issueReportSubtitle =>
      'Yaşadığınız problemi ayrıntılarıyla iletin. Form, e-posta uygulamanızda hazırlanır.';

  @override
  String get issueType => 'Sorun Türü';

  @override
  String get technicalIssue => 'Teknik Sorun';

  @override
  String get measurementIssue => 'Ölçüm / Değerlendirme Sorunu';

  @override
  String get orderIssue => 'Sipariş Süreci';

  @override
  String get accountIssue => 'Hesap / Kullanıcı Sorunu';

  @override
  String get otherIssue => 'Diğer';

  @override
  String get priority => 'Öncelik';

  @override
  String get lowPriority => 'Düşük';

  @override
  String get highPriority => 'Yüksek';

  @override
  String get urgentPriority => 'Acil';

  @override
  String get subjectTitle => 'Konu Başlığı';

  @override
  String get subjectTitleHint => 'Örn. Değerlendirme sonucu açılmıyor';

  @override
  String get issueDescription => 'Sorun Açıklaması';

  @override
  String get issueDescriptionHint =>
      'Problemin hangi ekranda oluştuğunu ve varsa hata mesajını yazın.';

  @override
  String get subjectRequired => 'Konu başlığı zorunludur.';

  @override
  String get subjectTooShort => 'Konu başlığı biraz daha açıklayıcı olmalıdır.';

  @override
  String get descriptionRequired => 'Sorun açıklaması zorunludur.';

  @override
  String get descriptionTooShort => 'Lütfen sorunu biraz daha ayrıntılandırın.';

  @override
  String supportFormEmailNotice(String email) {
    return 'Gönder dediğinizde e-posta uygulamanız açılır ve ileti $email adresine hazırlanır.';
  }

  @override
  String get emailAppOpened =>
      'Sorun bildirimi e-posta uygulamanızda hazırlandı.';

  @override
  String get supportClosingNote =>
      'Destek talepleriniz en kısa sürede değerlendirilecektir.';

  @override
  String get frequentlyAskedQuestions => 'Sıkça Sorulan Sorular';

  @override
  String get faqSubtitle =>
      'Yaygın konuları ve yönlendirmeleri buradan inceleyin.';

  @override
  String get faqResultsQuestion =>
      'Değerlendirme sonuçlarımı nereden görebilirim?';

  @override
  String get faqResultsAnswer =>
      'Hesabınıza giriş yaptıktan sonra Değerlendirme Sonuçları bölümünden size ait ölçüm sonuçlarını görüntüleyebilirsiniz.';

  @override
  String get faqOrderQuestion => 'Sipariş durumumu nasıl takip ederim?';

  @override
  String get faqOrderAnswer =>
      'Siparişlerim bölümünden tasarım, üretim, kargo ve teslimat durumunu takip edebilirsiniz.';

  @override
  String get faqUsageQuestion => 'Ürünümü kullanırken nelere dikkat etmeliyim?';

  @override
  String get faqUsageAnswer =>
      'İlk kullanımda ürünü kademeli kullanmanız; ağrı veya belirgin rahatsızlık hissederseniz uzmanınızla ya da destek ekibiyle iletişime geçmeniz önerilir.';

  @override
  String get faqContactQuestion => 'Destek ekibine nasıl ulaşırım?';

  @override
  String get faqContactAnswer =>
      'Bu sayfadaki telefon veya e-posta seçeneklerini kullanarak OptiYou destek ekibine ulaşabilirsiniz.';

  @override
  String get faqExpertPatientQuestion =>
      'Yeni kullanıcı kaydı nasıl oluşturulur?';

  @override
  String get faqExpertPatientAnswer =>
      'Uzman panelindeki Kullanıcılar bölümünden yeni kayıt oluşturabilir ve onay bağlantısını kullanıcıya gönderebilirsiniz.';

  @override
  String get faqExpertResultsQuestion =>
      'Ölçüm sonuçları ne zaman görüntülenebilir?';

  @override
  String get faqExpertResultsAnswer =>
      'Zorunlu klinik bilgiler, 3D tarama ve gerekli ölçüm adımları tamamlandıktan sonra sonuçlar görüntülenebilir.';

  @override
  String get faqExpertPhotoQuestion =>
      'Referans iç taban fotoğrafı nasıl çekilmeli?';

  @override
  String get faqExpertPhotoAnswer =>
      'Fotoğraf üstten, net ve ölçek referansı görünür biçimde çekilmelidir.';

  @override
  String get faqExpertApprovalQuestion =>
      'Eksik adım varken ölçüm onaylanabilir mi?';

  @override
  String get faqExpertApprovalAnswer =>
      'Onay için zorunlu adımların tamamlanması gerekir; eksik adım varsa sistem onaya izin vermez.';

  @override
  String get faqTeamMissingQuestion =>
      'Operasyondaki eksik bilgiler nereden kontrol edilir?';

  @override
  String get faqTeamMissingAnswer =>
      'Operasyon ve sipariş detay ekranlarında klinik, kullanıcı, ölçüm ve üretim adımları kontrol edilebilir.';

  @override
  String get faqTeamReportQuestion =>
      'Klinik veya uzman kaynaklı sorunlar nasıl bildirilir?';

  @override
  String get faqTeamReportAnswer =>
      'Sorun bildirim formunda ilgili rolü, ekranı, işlem adımını ve hata ayrıntılarını belirtin.';

  @override
  String get faqTeamQrQuestion =>
      'QR veya sonuç erişim bağlantısı çalışmazsa ne yapılmalı?';

  @override
  String get faqTeamQrAnswer =>
      'Oturumun onaylandığını ve davet bağlantısının geçerli olduğunu kontrol edin; sorun sürerse destek ekibine bildirin.';

  @override
  String get faqTeamSystemQuestion =>
      'Sistemsel hata bildiriminde hangi bilgiler gereklidir?';

  @override
  String get faqTeamSystemAnswer =>
      'Ekran, kullanıcı rolü, işlem adımı, hata mesajı ve mümkünse ekran görüntüsü paylaşılmalıdır.';
}
