import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @language.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get language;

  /// No description provided for @turkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In tr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @login.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap'**
  String get login;

  /// No description provided for @register.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Ol'**
  String get register;

  /// No description provided for @email.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get email;

  /// No description provided for @password.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi unuttum'**
  String get forgotPassword;

  /// No description provided for @profile.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @viewProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profili Görüntüle'**
  String get viewProfile;

  /// No description provided for @editInformation.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri Düzenle'**
  String get editInformation;

  /// No description provided for @logout.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış Yap'**
  String get logout;

  /// No description provided for @dashboard.
  ///
  /// In tr, this message translates to:
  /// **'Kontrol Paneli'**
  String get dashboard;

  /// No description provided for @customers.
  ///
  /// In tr, this message translates to:
  /// **'Müşteriler'**
  String get customers;

  /// No description provided for @measurementHistory.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm Geçmişi'**
  String get measurementHistory;

  /// No description provided for @orders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler'**
  String get orders;

  /// No description provided for @support.
  ///
  /// In tr, this message translates to:
  /// **'Destek'**
  String get support;

  /// No description provided for @home.
  ///
  /// In tr, this message translates to:
  /// **'Ana Sayfa'**
  String get home;

  /// No description provided for @myAnalysisResults.
  ///
  /// In tr, this message translates to:
  /// **'Analiz Sonuçlarım'**
  String get myAnalysisResults;

  /// No description provided for @store.
  ///
  /// In tr, this message translates to:
  /// **'Mağaza'**
  String get store;

  /// No description provided for @departmentAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Departman Analizi'**
  String get departmentAnalysis;

  /// No description provided for @trends.
  ///
  /// In tr, this message translates to:
  /// **'Trendler'**
  String get trends;

  /// No description provided for @employees.
  ///
  /// In tr, this message translates to:
  /// **'Çalışanlar'**
  String get employees;

  /// No description provided for @reports.
  ///
  /// In tr, this message translates to:
  /// **'Raporlar'**
  String get reports;

  /// No description provided for @salesStatistics.
  ///
  /// In tr, this message translates to:
  /// **'Satış İstatistikleri'**
  String get salesStatistics;

  /// No description provided for @measurementPool.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm Havuzu'**
  String get measurementPool;

  /// No description provided for @operations.
  ///
  /// In tr, this message translates to:
  /// **'Operasyonlar'**
  String get operations;

  /// No description provided for @digitalManufacturingLab.
  ///
  /// In tr, this message translates to:
  /// **'Dijital Üretim Laboratuvarı'**
  String get digitalManufacturingLab;

  /// No description provided for @services.
  ///
  /// In tr, this message translates to:
  /// **'Hizmetler'**
  String get services;

  /// No description provided for @products.
  ///
  /// In tr, this message translates to:
  /// **'Ürünler'**
  String get products;

  /// No description provided for @measurementCenters.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm Merkezleri'**
  String get measurementCenters;

  /// No description provided for @aboutUs.
  ///
  /// In tr, this message translates to:
  /// **'Hakkımızda'**
  String get aboutUs;

  /// No description provided for @loading.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor...'**
  String get loading;

  /// No description provided for @cancel.
  ///
  /// In tr, this message translates to:
  /// **'İptal'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In tr, this message translates to:
  /// **'Kaydet'**
  String get save;

  /// No description provided for @close.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Dene'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In tr, this message translates to:
  /// **'Geri Dön'**
  String get back;

  /// No description provided for @selectLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Dil seçin'**
  String get selectLanguage;

  /// No description provided for @editInformationComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Bilgileri düzenleme ekranını daha sonra bağlayacağız.'**
  String get editInformationComingSoon;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In tr, this message translates to:
  /// **'Şifremi Unuttum'**
  String get forgotPasswordTitle;

  /// No description provided for @passwordReset.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Sıfırlama'**
  String get passwordReset;

  /// No description provided for @passwordResetDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza bağlı e-posta adresini girin. Size şifrenizi yenilemeniz için bir bağlantı göndereceğiz.'**
  String get passwordResetDescription;

  /// No description provided for @sendResetLink.
  ///
  /// In tr, this message translates to:
  /// **'Sıfırlama Bağlantısı Gönder'**
  String get sendResetLink;

  /// No description provided for @newPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre'**
  String get newPassword;

  /// No description provided for @newPasswordAgain.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre Tekrar'**
  String get newPasswordAgain;

  /// No description provided for @setNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifre Belirle'**
  String get setNewPassword;

  /// No description provided for @updatePassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifreyi Güncelle'**
  String get updatePassword;

  /// No description provided for @passwordUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Güncellendi'**
  String get passwordUpdated;

  /// No description provided for @firstName.
  ///
  /// In tr, this message translates to:
  /// **'Ad'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In tr, this message translates to:
  /// **'Soyad'**
  String get lastName;

  /// No description provided for @passwordAgain.
  ///
  /// In tr, this message translates to:
  /// **'Şifre Tekrar'**
  String get passwordAgain;

  /// No description provided for @userType.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Tipi'**
  String get userType;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In tr, this message translates to:
  /// **'Zaten hesabın var mı? Giriş Yap'**
  String get alreadyHaveAccount;

  /// No description provided for @noAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın yok mu? Kayıt Ol'**
  String get noAccount;

  /// No description provided for @continueAction.
  ///
  /// In tr, this message translates to:
  /// **'Devam Et'**
  String get continueAction;

  /// No description provided for @invalidInvitation.
  ///
  /// In tr, this message translates to:
  /// **'Davet Bağlantısı Geçersiz'**
  String get invalidInvitation;

  /// No description provided for @backToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Ekranına Dön'**
  String get backToLogin;

  /// No description provided for @registerWithInvitation.
  ///
  /// In tr, this message translates to:
  /// **'Davet Bağlantısı ile Kaydol'**
  String get registerWithInvitation;

  /// No description provided for @customerRole.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri'**
  String get customerRole;

  /// No description provided for @expertRole.
  ///
  /// In tr, this message translates to:
  /// **'Uzman'**
  String get expertRole;

  /// No description provided for @corporateRole.
  ///
  /// In tr, this message translates to:
  /// **'Kurumsal'**
  String get corporateRole;

  /// No description provided for @optiyouTeamRole.
  ///
  /// In tr, this message translates to:
  /// **'Optiyou Ekibi'**
  String get optiyouTeamRole;

  /// No description provided for @homeLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Ana sayfa bilgileri yüklenemedi.'**
  String get homeLoadError;

  /// No description provided for @partialHomeDataWarning.
  ///
  /// In tr, this message translates to:
  /// **'Bazı güncel bilgiler yüklenemedi. Diğer bölümleri kullanmaya devam edebilirsiniz.'**
  String get partialHomeDataWarning;

  /// No description provided for @dataUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bilgi alınamadı'**
  String get dataUnavailable;

  /// No description provided for @noAssessmentYet.
  ///
  /// In tr, this message translates to:
  /// **'Henüz değerlendirme yok'**
  String get noAssessmentYet;

  /// No description provided for @noAssessmentYetDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza bir ölçüm sonucu bağlandığında burada görüntülenecektir.'**
  String get noAssessmentYetDescription;

  /// No description provided for @noActiveOrder.
  ///
  /// In tr, this message translates to:
  /// **'Aktif sipariş yok'**
  String get noActiveOrder;

  /// No description provided for @noActiveOrderDescription.
  ///
  /// In tr, this message translates to:
  /// **'Yeni veya devam eden bir siparişiniz bulunmuyor.'**
  String get noActiveOrderDescription;

  /// No description provided for @recommendationPending.
  ///
  /// In tr, this message translates to:
  /// **'Uzman önerisi bekleniyor'**
  String get recommendationPending;

  /// No description provided for @recommendationPendingDescription.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmenize ait uzman önerisi eklendiğinde burada görüntülenecektir.'**
  String get recommendationPendingDescription;

  /// No description provided for @assessmentSummaryAvailable.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme sonucunuz hazır. Ayrıntılı bulguları ve ölçümleri sonuç ekranından inceleyebilirsiniz.'**
  String get assessmentSummaryAvailable;

  /// No description provided for @orderedOn.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş tarihi: {date}'**
  String orderedOn(String date);

  /// No description provided for @browseProducts.
  ///
  /// In tr, this message translates to:
  /// **'Ürünleri İncele'**
  String get browseProducts;

  /// No description provided for @productSelectionPendingDescription.
  ///
  /// In tr, this message translates to:
  /// **'Size uygun ürün henüz belirlenmedi. Ürün seçimi uzman değerlendirmesiyle kesinleştirilecektir.'**
  String get productSelectionPendingDescription;

  /// No description provided for @notSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Belirtilmedi'**
  String get notSpecified;

  /// No description provided for @helloUser.
  ///
  /// In tr, this message translates to:
  /// **'Merhaba, {name}'**
  String helloUser(String name);

  /// No description provided for @customerHomeIntro.
  ///
  /// In tr, this message translates to:
  /// **'Ayak sağlığınızla ilgili değerlendirmelerinizi, önerilerinizi ve siparişlerinizi buradan takip edebilirsiniz.'**
  String get customerHomeIntro;

  /// No description provided for @viewMyAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirmemi görüntüle'**
  String get viewMyAssessment;

  /// No description provided for @trackMyOrder.
  ///
  /// In tr, this message translates to:
  /// **'Siparişimi takip et'**
  String get trackMyOrder;

  /// No description provided for @latestAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Son değerlendirme'**
  String get latestAssessment;

  /// No description provided for @activeOrder.
  ///
  /// In tr, this message translates to:
  /// **'Aktif sipariş'**
  String get activeOrder;

  /// No description provided for @recommendedProduct.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen ürün'**
  String get recommendedProduct;

  /// No description provided for @personalRecommendation.
  ///
  /// In tr, this message translates to:
  /// **'Size özel öneri'**
  String get personalRecommendation;

  /// No description provided for @orderProcess.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş süreci'**
  String get orderProcess;

  /// No description provided for @orderReceived.
  ///
  /// In tr, this message translates to:
  /// **'Alındı'**
  String get orderReceived;

  /// No description provided for @design.
  ///
  /// In tr, this message translates to:
  /// **'Tasarım'**
  String get design;

  /// No description provided for @production.
  ///
  /// In tr, this message translates to:
  /// **'Üretim'**
  String get production;

  /// No description provided for @shipped.
  ///
  /// In tr, this message translates to:
  /// **'Kargoda'**
  String get shipped;

  /// No description provided for @delivered.
  ///
  /// In tr, this message translates to:
  /// **'Teslim'**
  String get delivered;

  /// No description provided for @estimatedDelivery.
  ///
  /// In tr, this message translates to:
  /// **'Tahmini teslim: {date}'**
  String estimatedDelivery(String date);

  /// No description provided for @goToOrderDetails.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş detayına git'**
  String get goToOrderDetails;

  /// No description provided for @specialistRecommendation.
  ///
  /// In tr, this message translates to:
  /// **'Uzmanınızdan öneri'**
  String get specialistRecommendation;

  /// No description provided for @updatedOn.
  ///
  /// In tr, this message translates to:
  /// **'Güncelleme: {date}'**
  String updatedOn(String date);

  /// No description provided for @yourLatestAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Son değerlendirmeniz'**
  String get yourLatestAssessment;

  /// No description provided for @viewDetailedAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Detaylı değerlendirmeyi görüntüle'**
  String get viewDetailedAssessment;

  /// No description provided for @productRecommendedForYou.
  ///
  /// In tr, this message translates to:
  /// **'Size önerilen ürün'**
  String get productRecommendedForYou;

  /// No description provided for @viewProduct.
  ///
  /// In tr, this message translates to:
  /// **'Ürünü incele'**
  String get viewProduct;

  /// No description provided for @haveAQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Bir sorunuz mu var?'**
  String get haveAQuestion;

  /// No description provided for @supportTeamCanHelp.
  ///
  /// In tr, this message translates to:
  /// **'Destek ekibimiz size yardımcı olabilir.'**
  String get supportTeamCanHelp;

  /// No description provided for @getSupport.
  ///
  /// In tr, this message translates to:
  /// **'Destek al'**
  String get getSupport;

  /// No description provided for @assessmentReady.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme hazır'**
  String get assessmentReady;

  /// No description provided for @assessmentMockSummary.
  ///
  /// In tr, this message translates to:
  /// **'Ayak değerlendirmenizde kemer desteği ihtiyacı ve topuk bölgesinde yük artışı gözlemlendi.'**
  String get assessmentMockSummary;

  /// No description provided for @archSupportNeed.
  ///
  /// In tr, this message translates to:
  /// **'Kemer desteği ihtiyacı'**
  String get archSupportNeed;

  /// No description provided for @increasedHeelLoad.
  ///
  /// In tr, this message translates to:
  /// **'Topuk yükünde artış'**
  String get increasedHeelLoad;

  /// No description provided for @personalSupportRecommendation.
  ///
  /// In tr, this message translates to:
  /// **'Kişiye özel destek önerisi'**
  String get personalSupportRecommendation;

  /// No description provided for @specialistMockNote.
  ///
  /// In tr, this message translates to:
  /// **'Uzun süre ayakta kaldığınız günlerde destekli iç taban kullanmanız ve ürününüzü düzenli aralıklarla kontrol ettirmeniz önerilir.'**
  String get specialistMockNote;

  /// No description provided for @inProduction.
  ///
  /// In tr, this message translates to:
  /// **'Üretimde'**
  String get inProduction;

  /// No description provided for @customOrthopedicInsole.
  ///
  /// In tr, this message translates to:
  /// **'Kişiye Özel Ortopedik İç Taban'**
  String get customOrthopedicInsole;

  /// No description provided for @customInsole.
  ///
  /// In tr, this message translates to:
  /// **'Kişiye Özel İç Taban'**
  String get customInsole;

  /// No description provided for @customInsoleDescription.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kullanımda basınç dağılımını dengelemeye ve ayağınıza uygun desteği sağlamaya yardımcı olur.'**
  String get customInsoleDescription;

  /// No description provided for @customInsoleReason.
  ///
  /// In tr, this message translates to:
  /// **'Son değerlendirmenizde görülen kemer desteği ihtiyacına göre önerildi.'**
  String get customInsoleReason;

  /// No description provided for @enterEmail.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen e-posta girin.'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen şifrenizi girin.'**
  String get enterPassword;

  /// No description provided for @genericError.
  ///
  /// In tr, this message translates to:
  /// **'Bir hata oluştu. Lütfen tekrar deneyin.'**
  String get genericError;

  /// No description provided for @invalidCredentials.
  ///
  /// In tr, this message translates to:
  /// **'E-posta veya şifre hatalı.'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresiniz doğrulanmamış.'**
  String get emailNotConfirmed;

  /// No description provided for @tooManyAttempts.
  ///
  /// In tr, this message translates to:
  /// **'Çok fazla deneme yaptınız. Lütfen bekleyin.'**
  String get tooManyAttempts;

  /// No description provided for @enterValidEmail.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen geçerli bir e-posta adresi girin.'**
  String get enterValidEmail;

  /// No description provided for @resetLinkSent.
  ///
  /// In tr, this message translates to:
  /// **'Şifre sıfırlama bağlantısı gönderildi. Lütfen e-posta kutunuzu kontrol edin.'**
  String get resetLinkSent;

  /// No description provided for @sending.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiliyor...'**
  String get sending;

  /// No description provided for @saving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor...'**
  String get saving;

  /// No description provided for @setPasswordDescription.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız için yeni bir şifre belirleyin.'**
  String get setPasswordDescription;

  /// No description provided for @saveNewPassword.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Şifreyi Kaydet'**
  String get saveNewPassword;

  /// No description provided for @enterPasswordTwice.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen yeni şifrenizi iki kez girin.'**
  String get enterPasswordTwice;

  /// No description provided for @passwordMinEight.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 8 karakter olmalı.'**
  String get passwordMinEight;

  /// No description provided for @passwordMinSix.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olmalıdır.'**
  String get passwordMinSix;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In tr, this message translates to:
  /// **'Şifreler eşleşmiyor.'**
  String get passwordsDoNotMatch;

  /// No description provided for @registrationComplete.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt Tamamlandı!'**
  String get registrationComplete;

  /// No description provided for @enterFirstAndLastName.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen adınızı ve soyadınızı girin.'**
  String get enterFirstAndLastName;

  /// No description provided for @selectUserType.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen kullanıcı tipini seçin.'**
  String get selectUserType;

  /// No description provided for @qrFootHealthEcosystem.
  ///
  /// In tr, this message translates to:
  /// **'Ayak Sağlığı Ekosistemi'**
  String get qrFootHealthEcosystem;

  /// No description provided for @qrDigitalManufacturing.
  ///
  /// In tr, this message translates to:
  /// **'Dijital Üretim'**
  String get qrDigitalManufacturing;

  /// No description provided for @qrPerformanceSupport.
  ///
  /// In tr, this message translates to:
  /// **'Performans Desteği'**
  String get qrPerformanceSupport;

  /// No description provided for @qrWelcomeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Optiyou ekosistemine hoş geldiniz.'**
  String get qrWelcomeTitle;

  /// No description provided for @qrWelcomeDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm, uzman değerlendirmesi ve sonuç erişimini tek bir kullanıcı yolculuğunda birleştiriyoruz. QR bağlantısı üzerinden hesabınızı oluşturup kişisel sonuçlarınıza güvenli şekilde ulaşabilirsiniz.'**
  String get qrWelcomeDescription;

  /// No description provided for @qrCheckingLink.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç erişim bağlantısı kontrol ediliyor...'**
  String get qrCheckingLink;

  /// No description provided for @qrLinkReady.
  ///
  /// In tr, this message translates to:
  /// **'Bu bağlantı kişisel sonuç erişimi için hazır. Hesap oluşturma veya giriş işlemini aynı sayfa içinde tamamlayabilirsiniz.'**
  String get qrLinkReady;

  /// No description provided for @qrGoToRegistration.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı Kaydına Geç'**
  String get qrGoToRegistration;

  /// No description provided for @qrRegistrationEyebrow.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı kaydı'**
  String get qrRegistrationEyebrow;

  /// No description provided for @qrRegistrationTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlarınızı size ait güvenli hesaba bağlayın.'**
  String get qrRegistrationTitle;

  /// No description provided for @qrRegistrationDescription.
  ///
  /// In tr, this message translates to:
  /// **'QR bağlantısı ölçüm kaydınızı tanır. Hesap oluşturduğunuzda veya giriş yaptığınızda analiz raporu ve ürün önerisi uygulama hesabınızla ilişkilendirilir.'**
  String get qrRegistrationDescription;

  /// No description provided for @qrCreateAccount.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur'**
  String get qrCreateAccount;

  /// No description provided for @qrCreateAndClaim.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur ve Sonuçlarıma Bağla'**
  String get qrCreateAndClaim;

  /// No description provided for @qrCreateAndContinue.
  ///
  /// In tr, this message translates to:
  /// **'Hesap Oluştur ve Devam Et'**
  String get qrCreateAndContinue;

  /// No description provided for @qrLoginAndClaim.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap ve Sonuçlarıma Bağla'**
  String get qrLoginAndClaim;

  /// No description provided for @qrLoginAndContinue.
  ///
  /// In tr, this message translates to:
  /// **'Giriş Yap ve Uygulamaya Geç'**
  String get qrLoginAndContinue;

  /// No description provided for @qrReady.
  ///
  /// In tr, this message translates to:
  /// **'Hazırsınız.'**
  String get qrReady;

  /// No description provided for @qrClaimSuccess.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlarınız hesabınıza bağlandı. Analiz raporunuzu, kullanım önerilerinizi ve destek seçeneklerinizi uygulama içinde görüntüleyebilirsiniz.'**
  String get qrClaimSuccess;

  /// No description provided for @qrAccountReady.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınız hazır. Optiyou uygulamasına geçebilirsiniz.'**
  String get qrAccountReady;

  /// No description provided for @qrOpenApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulamaya Geç'**
  String get qrOpenApp;

  /// No description provided for @qrResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlar'**
  String get qrResults;

  /// No description provided for @qrResultsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Analiz raporu, ürün önerisi ve takip bilgileri tek yerde.'**
  String get qrResultsTitle;

  /// No description provided for @qrResultsDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt tamamlandığında ölçüm geçmişinizi, uzman değerlendirmesini ve size önerilen ürünü Optiyou hesabınızdan görüntüleyebilirsiniz.'**
  String get qrResultsDescription;

  /// No description provided for @qrAnalysisSummary.
  ///
  /// In tr, this message translates to:
  /// **'Analiz özeti'**
  String get qrAnalysisSummary;

  /// No description provided for @qrAnalysisSummaryText.
  ///
  /// In tr, this message translates to:
  /// **'Basınç, denge ve destek ihtiyacı sade başlıklarla sunulur.'**
  String get qrAnalysisSummaryText;

  /// No description provided for @qrSuitableProduct.
  ///
  /// In tr, this message translates to:
  /// **'Size uygun ürün önerisi'**
  String get qrSuitableProduct;

  /// No description provided for @qrSuitableProductText.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme sonucuna göre ürün listemizden uygun çözüm seçilir.'**
  String get qrSuitableProductText;

  /// No description provided for @qrTrackingHistory.
  ///
  /// In tr, this message translates to:
  /// **'Takip geçmişi'**
  String get qrTrackingHistory;

  /// No description provided for @qrTrackingHistoryText.
  ///
  /// In tr, this message translates to:
  /// **'Sonraki ölçümlerde değişim ve kullanım notları karşılaştırılabilir.'**
  String get qrTrackingHistoryText;

  /// No description provided for @qrOpenResults.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçları Aç'**
  String get qrOpenResults;

  /// No description provided for @qrPersonalResults.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel sonuç görünümü'**
  String get qrPersonalResults;

  /// No description provided for @qrAnalysisScore.
  ///
  /// In tr, this message translates to:
  /// **'Analiz skoru'**
  String get qrAnalysisScore;

  /// No description provided for @qrSupportNeed.
  ///
  /// In tr, this message translates to:
  /// **'Destek ihtiyacı'**
  String get qrSupportNeed;

  /// No description provided for @qrMedium.
  ///
  /// In tr, this message translates to:
  /// **'Orta'**
  String get qrMedium;

  /// No description provided for @qrPersonalInsole.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel iç taban'**
  String get qrPersonalInsole;

  /// No description provided for @analysisResultsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Analiz sonuçları yüklenirken hata oluştu: {error}'**
  String analysisResultsLoadError(String error);

  /// No description provided for @noAnalysisResults.
  ///
  /// In tr, this message translates to:
  /// **'Analiz sonucu bulunamadı.'**
  String get noAnalysisResults;

  /// No description provided for @analysisWillAppear.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm sonuçlarınız hesabınıza bağlandığında burada görüntülenecektir.'**
  String get analysisWillAppear;

  /// No description provided for @checkAgain.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar Kontrol Et'**
  String get checkAgain;

  /// No description provided for @myProfile.
  ///
  /// In tr, this message translates to:
  /// **'Profilim'**
  String get myProfile;

  /// No description provided for @customerProfile.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri Profili'**
  String get customerProfile;

  /// No description provided for @personalInformation.
  ///
  /// In tr, this message translates to:
  /// **'Kişisel Bilgiler'**
  String get personalInformation;

  /// No description provided for @fullName.
  ///
  /// In tr, this message translates to:
  /// **'Ad Soyad'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In tr, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In tr, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @shortSummary.
  ///
  /// In tr, this message translates to:
  /// **'Kısa Özet'**
  String get shortSummary;

  /// No description provided for @totalAnalyses.
  ///
  /// In tr, this message translates to:
  /// **'Toplam Analiz'**
  String get totalAnalyses;

  /// No description provided for @myInsoleImages.
  ///
  /// In tr, this message translates to:
  /// **'İç Taban Görsellerim'**
  String get myInsoleImages;

  /// No description provided for @uploadInsoleImage.
  ///
  /// In tr, this message translates to:
  /// **'İç Taban Görseli Yükle'**
  String get uploadInsoleImage;

  /// No description provided for @noInsoleImages.
  ///
  /// In tr, this message translates to:
  /// **'Henüz yüklenmiş iç taban görseli bulunmuyor.'**
  String get noInsoleImages;

  /// No description provided for @imageUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yok'**
  String get imageUnavailable;

  /// No description provided for @insoleImagesTemporaryNote.
  ///
  /// In tr, this message translates to:
  /// **'Bu alana eklediğiniz görseller yalnızca bu oturumda önizlenir; henüz hesabınıza kaydedilmez.'**
  String get insoleImagesTemporaryNote;

  /// No description provided for @assessmentResults.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme Sonuçları'**
  String get assessmentResults;

  /// No description provided for @assessmentNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme sonucu bulunamadı.'**
  String get assessmentNotFound;

  /// No description provided for @preparingAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme verileri hazırlanıyor...'**
  String get preparingAssessment;

  /// No description provided for @measurementHistoryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm Geçmişi'**
  String get measurementHistoryTitle;

  /// No description provided for @selectMeasurementSession.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülemek istediğiniz ölçüm oturumunu seçin.'**
  String get selectMeasurementSession;

  /// No description provided for @preparingPdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF hazırlanıyor...'**
  String get preparingPdf;

  /// No description provided for @savePdf.
  ///
  /// In tr, this message translates to:
  /// **'PDF Kaydet'**
  String get savePdf;

  /// No description provided for @assessmentIntro.
  ///
  /// In tr, this message translates to:
  /// **'3D anatomik ölçümler, görsel incelemeler ve plantar basınç ölçüm sonuçları.'**
  String get assessmentIntro;

  /// No description provided for @locationNotSpecified.
  ///
  /// In tr, this message translates to:
  /// **'Konum belirtilmedi'**
  String get locationNotSpecified;

  /// No description provided for @anatomicalMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Anatomik Ölçümler'**
  String get anatomicalMeasurements;

  /// No description provided for @anatomicalMeasurementsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'3D taramadan alınan anatomik ölçüm değerleri.'**
  String get anatomicalMeasurementsSubtitle;

  /// No description provided for @noParsedScanReport.
  ///
  /// In tr, this message translates to:
  /// **'Bu ölçüm için ayrıştırılmış 3D tarama raporu bulunmuyor.'**
  String get noParsedScanReport;

  /// No description provided for @left.
  ///
  /// In tr, this message translates to:
  /// **'Sol'**
  String get left;

  /// No description provided for @right.
  ///
  /// In tr, this message translates to:
  /// **'Sağ'**
  String get right;

  /// No description provided for @leftFoot.
  ///
  /// In tr, this message translates to:
  /// **'Sol Ayak'**
  String get leftFoot;

  /// No description provided for @rightFoot.
  ///
  /// In tr, this message translates to:
  /// **'Sağ Ayak'**
  String get rightFoot;

  /// No description provided for @footLength.
  ///
  /// In tr, this message translates to:
  /// **'Ayak Uzunluğu'**
  String get footLength;

  /// No description provided for @soleLength.
  ///
  /// In tr, this message translates to:
  /// **'Taban Uzunluğu'**
  String get soleLength;

  /// No description provided for @footWidth.
  ///
  /// In tr, this message translates to:
  /// **'Ayak Genişliği'**
  String get footWidth;

  /// No description provided for @forefootWidth.
  ///
  /// In tr, this message translates to:
  /// **'Parmak Önü Genişliği'**
  String get forefootWidth;

  /// No description provided for @toeWidth.
  ///
  /// In tr, this message translates to:
  /// **'Parmak Genişliği'**
  String get toeWidth;

  /// No description provided for @archLength.
  ///
  /// In tr, this message translates to:
  /// **'Ark Uzunluğu'**
  String get archLength;

  /// No description provided for @archHeight.
  ///
  /// In tr, this message translates to:
  /// **'Ark Yüksekliği'**
  String get archHeight;

  /// No description provided for @outerArchWidth.
  ///
  /// In tr, this message translates to:
  /// **'Dış Ark Genişliği'**
  String get outerArchWidth;

  /// No description provided for @heelWidth.
  ///
  /// In tr, this message translates to:
  /// **'Topuk Genişliği'**
  String get heelWidth;

  /// No description provided for @firstMetatarsalLength.
  ///
  /// In tr, this message translates to:
  /// **'1. Metatars Uzunluğu'**
  String get firstMetatarsalLength;

  /// No description provided for @fifthMetatarsalLength.
  ///
  /// In tr, this message translates to:
  /// **'5. Metatars Uzunluğu'**
  String get fifthMetatarsalLength;

  /// No description provided for @metatarsalJointHeight.
  ///
  /// In tr, this message translates to:
  /// **'Metatars Eklem Yüksekliği'**
  String get metatarsalJointHeight;

  /// No description provided for @archStructure.
  ///
  /// In tr, this message translates to:
  /// **'Ark ve Kemer Yapısı'**
  String get archStructure;

  /// No description provided for @archStructureSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayak kemeri yüksekliği, genişliği ve yüzey formu.'**
  String get archStructureSubtitle;

  /// No description provided for @archHeightMap.
  ///
  /// In tr, this message translates to:
  /// **'Ark Yükseklik Haritası'**
  String get archHeightMap;

  /// No description provided for @archIndex.
  ///
  /// In tr, this message translates to:
  /// **'Ark İndeksi'**
  String get archIndex;

  /// No description provided for @archSectionImage.
  ///
  /// In tr, this message translates to:
  /// **'Ark Kesit Görüntüsü'**
  String get archSectionImage;

  /// No description provided for @archWidthIndex.
  ///
  /// In tr, this message translates to:
  /// **'Ark Genişlik İndeksi'**
  String get archWidthIndex;

  /// No description provided for @footFormHallux.
  ///
  /// In tr, this message translates to:
  /// **'Ayak Formu ve Başparmak Hizalanması'**
  String get footFormHallux;

  /// No description provided for @footFormHalluxSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ön ayak formu ve halluks açısının iki taraflı görünümü.'**
  String get footFormHalluxSubtitle;

  /// No description provided for @footImage.
  ///
  /// In tr, this message translates to:
  /// **'Ayak Görüntüsü'**
  String get footImage;

  /// No description provided for @halluxAngleType.
  ///
  /// In tr, this message translates to:
  /// **'Halluks Açısı ve Tipi'**
  String get halluxAngleType;

  /// No description provided for @rearfootPronation.
  ///
  /// In tr, this message translates to:
  /// **'Arka Ayak ve Pronasyon'**
  String get rearfootPronation;

  /// No description provided for @rearfootPronationSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Topuk-bilek, pronasyon ve diz hizalanması.'**
  String get rearfootPronationSubtitle;

  /// No description provided for @ankleAlignment.
  ///
  /// In tr, this message translates to:
  /// **'Ayak-Bilek Hizalanması'**
  String get ankleAlignment;

  /// No description provided for @pronationAngleHeelType.
  ///
  /// In tr, this message translates to:
  /// **'Pronasyon Açısı ve Topuk Tipi'**
  String get pronationAngleHeelType;

  /// No description provided for @kneeAngleAlignment.
  ///
  /// In tr, this message translates to:
  /// **'Diz Açısı ve Hizalanması'**
  String get kneeAngleAlignment;

  /// No description provided for @findingsAndImages.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme Bulguları ve Görseller'**
  String get findingsAndImages;

  /// No description provided for @findingsAndImagesSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Sol ve sağ ayak açıklamaları, görselleri ve değerleri birlikte gösterilir.'**
  String get findingsAndImagesSubtitle;

  /// No description provided for @loadingImages.
  ///
  /// In tr, this message translates to:
  /// **'Görseller yükleniyor...'**
  String get loadingImages;

  /// No description provided for @productAssessment.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Değerlendirmesi'**
  String get productAssessment;

  /// No description provided for @productAssessmentSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme sonucuna göre önerilen ürün.'**
  String get productAssessmentSubtitle;

  /// No description provided for @productRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Size Önerilen Ürün'**
  String get productRecommended;

  /// No description provided for @productNotDetermined.
  ///
  /// In tr, this message translates to:
  /// **'Ürün belirlenmedi.'**
  String get productNotDetermined;

  /// No description provided for @imageNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Görsel bulunamadı.'**
  String get imageNotFound;

  /// No description provided for @imagePathNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yolu bulunamadı.'**
  String get imagePathNotFound;

  /// No description provided for @imageCouldNotOpen.
  ///
  /// In tr, this message translates to:
  /// **'Görsel açılamadı.'**
  String get imageCouldNotOpen;

  /// No description provided for @noData.
  ///
  /// In tr, this message translates to:
  /// **'Veri bulunmuyor'**
  String get noData;

  /// No description provided for @normal.
  ///
  /// In tr, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @mild.
  ///
  /// In tr, this message translates to:
  /// **'Hafif'**
  String get mild;

  /// No description provided for @moderate.
  ///
  /// In tr, this message translates to:
  /// **'Orta Düzey'**
  String get moderate;

  /// No description provided for @severe.
  ///
  /// In tr, this message translates to:
  /// **'İleri Düzey'**
  String get severe;

  /// No description provided for @highArch.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek Ark'**
  String get highArch;

  /// No description provided for @normalArch.
  ///
  /// In tr, this message translates to:
  /// **'Normal Ark'**
  String get normalArch;

  /// No description provided for @mildFlatFoot.
  ///
  /// In tr, this message translates to:
  /// **'Hafif Düz Taban'**
  String get mildFlatFoot;

  /// No description provided for @moderateFlatFoot.
  ///
  /// In tr, this message translates to:
  /// **'Orta Düzey Düz Taban'**
  String get moderateFlatFoot;

  /// No description provided for @severeFlatFoot.
  ///
  /// In tr, this message translates to:
  /// **'İleri Düzey Düz Taban'**
  String get severeFlatFoot;

  /// No description provided for @plantarPressureMeasurements.
  ///
  /// In tr, this message translates to:
  /// **'Plantar Basınç Ölçümleri'**
  String get plantarPressureMeasurements;

  /// No description provided for @plantarPressureSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Seçili oturum sırasında kaydedilen basınç ölçüm kayıtları.'**
  String get plantarPressureSubtitle;

  /// No description provided for @noPressureRecordings.
  ///
  /// In tr, this message translates to:
  /// **'Bu oturum için kayıtlı plantar basınç ölçümü bulunmuyor.'**
  String get noPressureRecordings;

  /// No description provided for @selectPressureRecording.
  ///
  /// In tr, this message translates to:
  /// **'Görüntülemek için bir basınç kaydı seçin.'**
  String get selectPressureRecording;

  /// No description provided for @pressureHeatmap.
  ///
  /// In tr, this message translates to:
  /// **'Basınç Isı Haritası'**
  String get pressureHeatmap;

  /// No description provided for @frameCounter.
  ///
  /// In tr, this message translates to:
  /// **'Kare {current}/{total}'**
  String frameCounter(int current, int total);

  /// No description provided for @loadDistribution.
  ///
  /// In tr, this message translates to:
  /// **'Yük Dağılımı'**
  String get loadDistribution;

  /// No description provided for @weight.
  ///
  /// In tr, this message translates to:
  /// **'Kilo'**
  String get weight;

  /// No description provided for @leftRightLoad.
  ///
  /// In tr, this message translates to:
  /// **'Sol / Sağ Yük Dağılımı'**
  String get leftRightLoad;

  /// No description provided for @forefootHeelLoad.
  ///
  /// In tr, this message translates to:
  /// **'Ön Ayak / Topuk Dağılımı'**
  String get forefootHeelLoad;

  /// No description provided for @forefoot.
  ///
  /// In tr, this message translates to:
  /// **'Ön Ayak'**
  String get forefoot;

  /// No description provided for @heel.
  ///
  /// In tr, this message translates to:
  /// **'Topuk'**
  String get heel;

  /// No description provided for @frameCount.
  ///
  /// In tr, this message translates to:
  /// **'Kare Sayısı'**
  String get frameCount;

  /// No description provided for @duration.
  ///
  /// In tr, this message translates to:
  /// **'Süre'**
  String get duration;

  /// No description provided for @maximumRawValue.
  ///
  /// In tr, this message translates to:
  /// **'Maksimum Ham Değer'**
  String get maximumRawValue;

  /// No description provided for @averageRawValue.
  ///
  /// In tr, this message translates to:
  /// **'Ortalama Ham Değer'**
  String get averageRawValue;

  /// No description provided for @physicalValueUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Fiziksel değer hesaplanamadı'**
  String get physicalValueUnavailable;

  /// No description provided for @framesRecorded.
  ///
  /// In tr, this message translates to:
  /// **'{count} kare'**
  String framesRecorded(int count);

  /// No description provided for @footLengthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Topuk ile en uzun parmak arasındaki mesafe.'**
  String get footLengthDescription;

  /// No description provided for @soleLengthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ayak tabanının anatomik temas uzunluğu.'**
  String get soleLengthDescription;

  /// No description provided for @footWidthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ön ayaktaki en geniş anatomik mesafe.'**
  String get footWidthDescription;

  /// No description provided for @forefootWidthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Parmak kökleri seviyesindeki genişlik.'**
  String get forefootWidthDescription;

  /// No description provided for @archLengthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Medial longitudinal ark uzunluğu.'**
  String get archLengthDescription;

  /// No description provided for @archHeightDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ayak kemerinin maksimum yüksekliği.'**
  String get archHeightDescription;

  /// No description provided for @outerArchWidthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ark bölgesinin dış genişlik ölçümü.'**
  String get outerArchWidthDescription;

  /// No description provided for @heelWidthDescription.
  ///
  /// In tr, this message translates to:
  /// **'Topuk bölgesinin toplam genişliği.'**
  String get heelWidthDescription;

  /// No description provided for @firstMetatarsalDescription.
  ///
  /// In tr, this message translates to:
  /// **'Birinci metatarsal anatomik uzunluğu.'**
  String get firstMetatarsalDescription;

  /// No description provided for @fifthMetatarsalDescription.
  ///
  /// In tr, this message translates to:
  /// **'Beşinci metatarsal anatomik uzunluğu.'**
  String get fifthMetatarsalDescription;

  /// No description provided for @metatarsalJointDescription.
  ///
  /// In tr, this message translates to:
  /// **'Birinci metatars eklem bölgesindeki yükseklik.'**
  String get metatarsalJointDescription;

  /// No description provided for @halluxNoData.
  ///
  /// In tr, this message translates to:
  /// **'Halluks açısına ilişkin değerlendirme verisi bulunmuyor.'**
  String get halluxNoData;

  /// No description provided for @halluxNormal.
  ///
  /// In tr, this message translates to:
  /// **'Başparmak hizalanması normal açı aralığında görünüyor.'**
  String get halluxNormal;

  /// No description provided for @halluxMild.
  ///
  /// In tr, this message translates to:
  /// **'Başparmak açısında hafif düzeyde hizalanma değişimi görülüyor.'**
  String get halluxMild;

  /// No description provided for @halluxMarked.
  ///
  /// In tr, this message translates to:
  /// **'Başparmak açısında belirgin hizalanma değişimi görülüyor.'**
  String get halluxMarked;

  /// No description provided for @pronationNoData.
  ///
  /// In tr, this message translates to:
  /// **'Pronasyon açısına ilişkin değerlendirme verisi bulunmuyor.'**
  String get pronationNoData;

  /// No description provided for @pronationNormal.
  ///
  /// In tr, this message translates to:
  /// **'Arka ayak hizalanması normal açı aralığında görünüyor.'**
  String get pronationNormal;

  /// No description provided for @pronationMild.
  ///
  /// In tr, this message translates to:
  /// **'Arka ayakta hafif pronasyon veya supinasyon eğilimi görülüyor.'**
  String get pronationMild;

  /// No description provided for @pronationMarked.
  ///
  /// In tr, this message translates to:
  /// **'Arka ayak hizalanmasında belirgin açı değişimi görülüyor.'**
  String get pronationMarked;

  /// No description provided for @sessionIdMissing.
  ///
  /// In tr, this message translates to:
  /// **'Bu değerlendirme için oturum ID bulunamadı.'**
  String get sessionIdMissing;

  /// No description provided for @assessmentImagesUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu oturum için kullanılabilir değerlendirme görseli bulunamadı.'**
  String get assessmentImagesUnavailable;

  /// No description provided for @assessmentImagesLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme görselleri yüklenemedi: {error}'**
  String assessmentImagesLoadError(String error);

  /// No description provided for @pressureRecordingsLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Basınç ölçüm kayıtları yüklenemedi: {error}'**
  String pressureRecordingsLoadError(String error);

  /// No description provided for @pressureDataOpenError.
  ///
  /// In tr, this message translates to:
  /// **'Basınç kayıt verisi açılamadı: {error}'**
  String pressureDataOpenError(String error);

  /// No description provided for @leftArchDescriptionUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Sol ark yapısına ilişkin açıklama bulunmuyor.'**
  String get leftArchDescriptionUnavailable;

  /// No description provided for @rightArchDescriptionUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Sağ ark yapısına ilişkin açıklama bulunmuyor.'**
  String get rightArchDescriptionUnavailable;

  /// No description provided for @pdfSaved.
  ///
  /// In tr, this message translates to:
  /// **'PDF raporu kaydedildi.'**
  String get pdfSaved;

  /// No description provided for @pdfCreateError.
  ///
  /// In tr, this message translates to:
  /// **'PDF raporu oluşturulamadı: {error}'**
  String pdfCreateError(String error);

  /// No description provided for @myOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim'**
  String get myOrders;

  /// No description provided for @customerOrdersIntro.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerinizin üretim ve teslimat durumunu buradan takip edebilirsiniz.'**
  String get customerOrdersIntro;

  /// No description provided for @orderManagementIntro.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş akışını ve üretim durumlarını buradan takip edebilirsiniz.'**
  String get orderManagementIntro;

  /// No description provided for @orderSearchHint.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş numarası, ürün veya durum ile ara'**
  String get orderSearchHint;

  /// No description provided for @ordersLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler yüklenirken hata oluştu: {error}'**
  String ordersLoadError(String error);

  /// No description provided for @customerAccountNotLinked.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınızla eşleşen müşteri kaydı bulunamadı.'**
  String get customerAccountNotLinked;

  /// No description provided for @noCustomerOrders.
  ///
  /// In tr, this message translates to:
  /// **'Henüz size ait bir sipariş bulunmuyor.'**
  String get noCustomerOrders;

  /// No description provided for @noSavedOrders.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı sipariş bulunamadı.'**
  String get noSavedOrders;

  /// No description provided for @productLabel.
  ///
  /// In tr, this message translates to:
  /// **'Ürün'**
  String get productLabel;

  /// No description provided for @netAmountLabel.
  ///
  /// In tr, this message translates to:
  /// **'Net Tutar'**
  String get netAmountLabel;

  /// No description provided for @orderedChip.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş: {date}'**
  String orderedChip(String date);

  /// No description provided for @shippedChip.
  ///
  /// In tr, this message translates to:
  /// **'Kargo: {date}'**
  String shippedChip(String date);

  /// No description provided for @deliveredChip.
  ///
  /// In tr, this message translates to:
  /// **'Teslim: {date}'**
  String deliveredChip(String date);

  /// No description provided for @orderDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Detayı'**
  String get orderDetailTitle;

  /// No description provided for @orderStatusUpdated.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş durumu güncellendi.'**
  String get orderStatusUpdated;

  /// No description provided for @orderStatusUpdateError.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş güncellenemedi: {error}'**
  String orderStatusUpdateError(String error);

  /// No description provided for @orderInformation.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Bilgileri'**
  String get orderInformation;

  /// No description provided for @orderNumberLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Numarası'**
  String get orderNumberLabel;

  /// No description provided for @orderDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Tarihi'**
  String get orderDateLabel;

  /// No description provided for @shipmentDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kargo Tarihi'**
  String get shipmentDateLabel;

  /// No description provided for @deliveryDateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Teslim Tarihi'**
  String get deliveryDateLabel;

  /// No description provided for @deliveryAddressTitle.
  ///
  /// In tr, this message translates to:
  /// **'Teslimat Adresi'**
  String get deliveryAddressTitle;

  /// No description provided for @deliveryAddressMissing.
  ///
  /// In tr, this message translates to:
  /// **'Bu sipariş için teslimat adresi bulunamadı.'**
  String get deliveryAddressMissing;

  /// No description provided for @updateOrderStatus.
  ///
  /// In tr, this message translates to:
  /// **'Durumu Güncelle'**
  String get updateOrderStatus;

  /// No description provided for @orderStatusLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Durumu'**
  String get orderStatusLabel;

  /// No description provided for @orderFlowTitle.
  ///
  /// In tr, this message translates to:
  /// **'Üretim ve Sipariş Akışı'**
  String get orderFlowTitle;

  /// No description provided for @completionRate.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlanma Oranı: {percent}%'**
  String completionRate(int percent);

  /// No description provided for @priceInformation.
  ///
  /// In tr, this message translates to:
  /// **'Fiyat Bilgileri'**
  String get priceInformation;

  /// No description provided for @grossAmount.
  ///
  /// In tr, this message translates to:
  /// **'Brüt Tutar'**
  String get grossAmount;

  /// No description provided for @discountAmount.
  ///
  /// In tr, this message translates to:
  /// **'İndirim'**
  String get discountAmount;

  /// No description provided for @currency.
  ///
  /// In tr, this message translates to:
  /// **'Para Birimi'**
  String get currency;

  /// No description provided for @stepCompleted.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlandı'**
  String get stepCompleted;

  /// No description provided for @stepWaiting.
  ///
  /// In tr, this message translates to:
  /// **'Bekliyor'**
  String get stepWaiting;

  /// No description provided for @pendingStatus.
  ///
  /// In tr, this message translates to:
  /// **'Beklemede'**
  String get pendingStatus;

  /// No description provided for @designingStatus.
  ///
  /// In tr, this message translates to:
  /// **'Tasarımda'**
  String get designingStatus;

  /// No description provided for @productionStatus.
  ///
  /// In tr, this message translates to:
  /// **'Üretimde'**
  String get productionStatus;

  /// No description provided for @shippedStatus.
  ///
  /// In tr, this message translates to:
  /// **'Kargoda'**
  String get shippedStatus;

  /// No description provided for @deliveredStatus.
  ///
  /// In tr, this message translates to:
  /// **'Teslim Edildi'**
  String get deliveredStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In tr, this message translates to:
  /// **'İptal Edildi'**
  String get cancelledStatus;

  /// No description provided for @insoleProduct.
  ///
  /// In tr, this message translates to:
  /// **'Tabanlık'**
  String get insoleProduct;

  /// No description provided for @sportsInsoleProduct.
  ///
  /// In tr, this message translates to:
  /// **'Spor Tabanlık'**
  String get sportsInsoleProduct;

  /// No description provided for @sandalProduct.
  ///
  /// In tr, this message translates to:
  /// **'Sandalet'**
  String get sandalProduct;

  /// No description provided for @orderReceivedDescription.
  ///
  /// In tr, this message translates to:
  /// **'Siparişiniz sisteme kaydedildi ve işleme alındı.'**
  String get orderReceivedDescription;

  /// No description provided for @designPreparation.
  ///
  /// In tr, this message translates to:
  /// **'Tasarım Hazırlığı'**
  String get designPreparation;

  /// No description provided for @designPreparationDescription.
  ///
  /// In tr, this message translates to:
  /// **'Teknik tasarım ve üretim hazırlıkları yapılıyor.'**
  String get designPreparationDescription;

  /// No description provided for @productionDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ürününüz üretim sürecinde hazırlanıyor.'**
  String get productionDescription;

  /// No description provided for @handedToCarrier.
  ///
  /// In tr, this message translates to:
  /// **'Kargoya Verildi'**
  String get handedToCarrier;

  /// No description provided for @shippedDescription.
  ///
  /// In tr, this message translates to:
  /// **'Siparişiniz sevkiyata hazırlanarak kargo firmasına teslim edildi.'**
  String get shippedDescription;

  /// No description provided for @deliveredDescription.
  ///
  /// In tr, this message translates to:
  /// **'Siparişiniz teslimat adresine ulaştı.'**
  String get deliveredDescription;

  /// No description provided for @orderCancelledDescription.
  ///
  /// In tr, this message translates to:
  /// **'Bu sipariş iptal edildi. Ayrıntılı bilgi için destek ekibiyle iletişime geçebilirsiniz.'**
  String get orderCancelledDescription;

  /// No description provided for @actingUser.
  ///
  /// In tr, this message translates to:
  /// **'İşlem Yapan Kullanıcı'**
  String get actingUser;

  /// No description provided for @internalOrderId.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş ID'**
  String get internalOrderId;

  /// No description provided for @internalSessionId.
  ///
  /// In tr, this message translates to:
  /// **'Oturum ID'**
  String get internalSessionId;

  /// No description provided for @internalPatientId.
  ///
  /// In tr, this message translates to:
  /// **'Müşteri ID'**
  String get internalPatientId;

  /// No description provided for @internalClinicId.
  ///
  /// In tr, this message translates to:
  /// **'Klinik ID'**
  String get internalClinicId;

  /// No description provided for @internalExpertId.
  ///
  /// In tr, this message translates to:
  /// **'Uzman ID'**
  String get internalExpertId;

  /// No description provided for @internalAssignedUserId.
  ///
  /// In tr, this message translates to:
  /// **'Atanan OptiYou Kullanıcı ID'**
  String get internalAssignedUserId;

  /// No description provided for @profileMenuTooltip.
  ///
  /// In tr, this message translates to:
  /// **'Profil menüsü'**
  String get profileMenuTooltip;

  /// No description provided for @storeIntro.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş ürünleri inceleyin ve son değerlendirmenizle ilişkili bilgileri görün.'**
  String get storeIntro;

  /// No description provided for @latestMeasurement.
  ///
  /// In tr, this message translates to:
  /// **'Son Değerlendirme'**
  String get latestMeasurement;

  /// No description provided for @sessionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Oturum'**
  String get sessionLabel;

  /// No description provided for @dateLabel.
  ///
  /// In tr, this message translates to:
  /// **'Tarih'**
  String get dateLabel;

  /// No description provided for @locationLabel.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get locationLabel;

  /// No description provided for @linkedMeasurementMessage.
  ///
  /// In tr, this message translates to:
  /// **'Ürün uygunluğu son değerlendirme verileriniz ve uzman görüşüyle birlikte belirlenir.'**
  String get linkedMeasurementMessage;

  /// No description provided for @noLinkedMeasurementTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bağlı değerlendirme bulunamadı'**
  String get noLinkedMeasurementTitle;

  /// No description provided for @noLinkedMeasurementDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ürünleri inceleyebilirsiniz; kişiselleştirilmiş üretim için önce bir ölçüm kaydının hesabınıza bağlanması gerekir.'**
  String get noLinkedMeasurementDescription;

  /// No description provided for @mainProducts.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş Ürünler'**
  String get mainProducts;

  /// No description provided for @mainProductsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm ve uzman değerlendirmesine göre üretilen temel ürünler.'**
  String get mainProductsSubtitle;

  /// No description provided for @accessoryProducts.
  ///
  /// In tr, this message translates to:
  /// **'Tamamlayıcı Ürünler'**
  String get accessoryProducts;

  /// No description provided for @accessoryProductsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Günlük kullanım, konfor ve bakım için yardımcı seçenekler.'**
  String get accessoryProductsSubtitle;

  /// No description provided for @productAbout.
  ///
  /// In tr, this message translates to:
  /// **'Ürün Hakkında'**
  String get productAbout;

  /// No description provided for @whoSuitable.
  ///
  /// In tr, this message translates to:
  /// **'Kimler için uygun?'**
  String get whoSuitable;

  /// No description provided for @whyRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Uygunluk Notu'**
  String get whyRecommended;

  /// No description provided for @purchase.
  ///
  /// In tr, this message translates to:
  /// **'Satın Al'**
  String get purchase;

  /// No description provided for @storeRecommendationDisclaimer.
  ///
  /// In tr, this message translates to:
  /// **'Bu açıklama genel bilgilendirme amaçlıdır. Nihai ürün seçimi, ölçüm sonuçlarınız ve uzman değerlendirmesiyle kesinleştirilir.'**
  String get storeRecommendationDisclaimer;

  /// No description provided for @paymentInvalidUrl.
  ///
  /// In tr, this message translates to:
  /// **'Geçersiz ödeme bağlantısı alındı.'**
  String get paymentInvalidUrl;

  /// No description provided for @paymentPageOpenError.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme sayfası açılamadı.'**
  String get paymentPageOpenError;

  /// No description provided for @paymentStartError.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme başlatılamadı: {error}'**
  String paymentStartError(String error);

  /// No description provided for @paymentResultTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Sonucu'**
  String get paymentResultTitle;

  /// No description provided for @paymentCheckingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme doğrulanıyor'**
  String get paymentCheckingTitle;

  /// No description provided for @paymentCheckingDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme sağlayıcısından güvenli sonuç bekleniyor. Ödeme sayfasını tamamladıktan sonra bu ekran otomatik güncellenir.'**
  String get paymentCheckingDescription;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Başarılı'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeniz doğrulandı ve siparişiniz oluşturuldu.'**
  String get paymentSuccessDescription;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme Tamamlanamadı'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme başarısız oldu veya işlem iptal edildi. Kartınızdan çekim yapıldığını düşünüyorsanız destek ekibiyle iletişime geçin.'**
  String get paymentFailedDescription;

  /// No description provided for @paymentStatusLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme durumu doğrulanamadı: {error}'**
  String paymentStatusLoadError(String error);

  /// No description provided for @orderNumberValue.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş numarası: {orderNo}'**
  String orderNumberValue(String orderNo);

  /// No description provided for @paidAmountValue.
  ///
  /// In tr, this message translates to:
  /// **'Ödenen tutar: {amount}'**
  String paidAmountValue(String amount);

  /// No description provided for @goToMyOrders.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerime Git'**
  String get goToMyOrders;

  /// No description provided for @ordersNavigationError.
  ///
  /// In tr, this message translates to:
  /// **'Siparişler sayfası açılamadı: {error}'**
  String ordersNavigationError(String error);

  /// No description provided for @addressLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Adresler yüklenemedi: {error}'**
  String addressLoadError(String error);

  /// No description provided for @addressSaveError.
  ///
  /// In tr, this message translates to:
  /// **'Adres kaydedilemedi: {error}'**
  String addressSaveError(String error);

  /// No description provided for @deliveryAddressDescription.
  ///
  /// In tr, this message translates to:
  /// **'Ödeme sayfasına geçmeden önce teslimat adresinizi seçin veya yeni bir adres girin.'**
  String get deliveryAddressDescription;

  /// No description provided for @addNewAddress.
  ///
  /// In tr, this message translates to:
  /// **'Yeni Adres Ekle'**
  String get addNewAddress;

  /// No description provided for @backToList.
  ///
  /// In tr, this message translates to:
  /// **'Listeye Dön'**
  String get backToList;

  /// No description provided for @continueToPayment.
  ///
  /// In tr, this message translates to:
  /// **'Ödemeye Geç'**
  String get continueToPayment;

  /// No description provided for @selectDeliveryAddress.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen bir teslimat adresi seçin.'**
  String get selectDeliveryAddress;

  /// No description provided for @noSavedAddress.
  ///
  /// In tr, this message translates to:
  /// **'Kayıtlı adres bulunamadı. Yeni adres ekleyerek devam edin.'**
  String get noSavedAddress;

  /// No description provided for @addressTitle.
  ///
  /// In tr, this message translates to:
  /// **'Adres Başlığı'**
  String get addressTitle;

  /// No description provided for @city.
  ///
  /// In tr, this message translates to:
  /// **'İl'**
  String get city;

  /// No description provided for @district.
  ///
  /// In tr, this message translates to:
  /// **'İlçe'**
  String get district;

  /// No description provided for @addressLine.
  ///
  /// In tr, this message translates to:
  /// **'Açık Adres'**
  String get addressLine;

  /// No description provided for @requiredField.
  ///
  /// In tr, this message translates to:
  /// **'{field} zorunludur.'**
  String requiredField(String field);

  /// No description provided for @customInsoleFullDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kişiye özel iç taban, son ölçüm verileriniz temel alınarak ayağınıza uygun destek geometrisiyle hazırlanır. Günlük kullanımda konforu ve yük dağılımını desteklemeyi amaçlar.'**
  String get customInsoleFullDescription;

  /// No description provided for @customInsoleUsage.
  ///
  /// In tr, this message translates to:
  /// **'Uzun süre ayakta kalan, günlük konforunu artırmak isteyen veya kişisel destek ihtiyacı uzman tarafından belirlenen kullanıcılar içindir.'**
  String get customInsoleUsage;

  /// No description provided for @sportsInsoleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Spor İç Tabanlığı'**
  String get sportsInsoleTitle;

  /// No description provided for @sportsInsoleShort.
  ///
  /// In tr, this message translates to:
  /// **'Aktif yaşam ve spor kullanımı için dinamik destek sunar.'**
  String get sportsInsoleShort;

  /// No description provided for @sportsInsoleFull.
  ///
  /// In tr, this message translates to:
  /// **'Spor iç tabanlığı; yürüyüş, antrenman ve hareketli kullanımda ayağı desteklemek üzere kişiselleştirilir.'**
  String get sportsInsoleFull;

  /// No description provided for @sportsInsoleUsage.
  ///
  /// In tr, this message translates to:
  /// **'Düzenli spor yapan veya gün içinde yüksek hareket yoğunluğuna sahip kullanıcılar içindir.'**
  String get sportsInsoleUsage;

  /// No description provided for @heelPadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Topuk Pedi'**
  String get heelPadTitle;

  /// No description provided for @heelPadShort.
  ///
  /// In tr, this message translates to:
  /// **'Topuk bölgesinde ek yastıklama sağlayan tamamlayıcı ürün.'**
  String get heelPadShort;

  /// No description provided for @heelPadFull.
  ///
  /// In tr, this message translates to:
  /// **'Topuk pedi, topuk bölgesindeki teması yumuşatmak ve günlük kullanım konforunu desteklemek amacıyla kullanılır.'**
  String get heelPadFull;

  /// No description provided for @heelPadUsage.
  ///
  /// In tr, this message translates to:
  /// **'Topuk bölgesinde ek yastıklama ihtiyacı olan kullanıcılar içindir.'**
  String get heelPadUsage;

  /// No description provided for @metPadTitle.
  ///
  /// In tr, this message translates to:
  /// **'Metatarsal Destek Pedi'**
  String get metPadTitle;

  /// No description provided for @metPadShort.
  ///
  /// In tr, this message translates to:
  /// **'Ön ayak bölgesine ek destek sağlayan tamamlayıcı ürün.'**
  String get metPadShort;

  /// No description provided for @metPadFull.
  ///
  /// In tr, this message translates to:
  /// **'Metatarsal destek pedi, ön ayak bölgesindeki teması ve konforu desteklemek amacıyla kullanılır.'**
  String get metPadFull;

  /// No description provided for @metPadUsage.
  ///
  /// In tr, this message translates to:
  /// **'Ön ayak bölgesinde ek destek ihtiyacı uzman tarafından belirlenen kullanıcılar içindir.'**
  String get metPadUsage;

  /// No description provided for @cleaningSprayTitle.
  ///
  /// In tr, this message translates to:
  /// **'Temizleme Spreyi'**
  String get cleaningSprayTitle;

  /// No description provided for @cleaningSprayShort.
  ///
  /// In tr, this message translates to:
  /// **'İç taban ve yardımcı ürünlerin bakımı için pratik çözüm.'**
  String get cleaningSprayShort;

  /// No description provided for @cleaningSprayFull.
  ///
  /// In tr, this message translates to:
  /// **'Temizleme spreyi, ürünlerin düzenli bakımına ve hijyenik kullanımına yardımcı olur.'**
  String get cleaningSprayFull;

  /// No description provided for @cleaningSprayUsage.
  ///
  /// In tr, this message translates to:
  /// **'Kişiselleştirilmiş ürünlerinin bakımını düzenli yapmak isteyen kullanıcılar içindir.'**
  String get cleaningSprayUsage;

  /// No description provided for @carryCaseTitle.
  ///
  /// In tr, this message translates to:
  /// **'Taşıma Kılıfı'**
  String get carryCaseTitle;

  /// No description provided for @carryCaseShort.
  ///
  /// In tr, this message translates to:
  /// **'İç tabanları korumak ve taşımak için kompakt kılıf.'**
  String get carryCaseShort;

  /// No description provided for @carryCaseFull.
  ///
  /// In tr, this message translates to:
  /// **'Taşıma kılıfı, iç tabanları çanta içinde koruyarak daha düzenli taşımaya yardımcı olur.'**
  String get carryCaseFull;

  /// No description provided for @carryCaseUsage.
  ///
  /// In tr, this message translates to:
  /// **'İç tabanlarını yanında taşıyan kullanıcılar içindir.'**
  String get carryCaseUsage;

  /// No description provided for @supportCenter.
  ///
  /// In tr, this message translates to:
  /// **'Destek Merkezi'**
  String get supportCenter;

  /// No description provided for @customerSupportIntro.
  ///
  /// In tr, this message translates to:
  /// **'Siparişleriniz, ürünleriniz ve kullanım süreci hakkında destek alabilirsiniz.'**
  String get customerSupportIntro;

  /// No description provided for @expertSupportIntro.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm süreçleri, kullanıcı kayıtları ve sipariş yönetimi hakkında destek alabilirsiniz.'**
  String get expertSupportIntro;

  /// No description provided for @teamSupportIntro.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon, kullanıcı akışı ve sistem yönetimi için destek seçeneklerini kullanabilirsiniz.'**
  String get teamSupportIntro;

  /// No description provided for @genericSupportIntro.
  ///
  /// In tr, this message translates to:
  /// **'Yardıma ihtiyacınız varsa aşağıdaki iletişim veya sorun bildirim seçeneklerini kullanabilirsiniz.'**
  String get genericSupportIntro;

  /// No description provided for @quickSupport.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı Destek'**
  String get quickSupport;

  /// No description provided for @quickSupportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Destek ekibine telefon veya e-posta ile ulaşın.'**
  String get quickSupportSubtitle;

  /// No description provided for @callSupport.
  ///
  /// In tr, this message translates to:
  /// **'Destek Sorumlusunu Ara'**
  String get callSupport;

  /// No description provided for @callSupportDescription.
  ///
  /// In tr, this message translates to:
  /// **'Aşağıdaki numaralardan destek sorumlusuna ulaşabilirsiniz.'**
  String get callSupportDescription;

  /// No description provided for @tapToCall.
  ///
  /// In tr, this message translates to:
  /// **'Aramak için seçin'**
  String get tapToCall;

  /// No description provided for @actionCouldNotOpen.
  ///
  /// In tr, this message translates to:
  /// **'Bu işlem cihazda açılamadı.'**
  String get actionCouldNotOpen;

  /// No description provided for @reportIssue.
  ///
  /// In tr, this message translates to:
  /// **'Sorun Bildir'**
  String get reportIssue;

  /// No description provided for @sendIssue.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimi Hazırla'**
  String get sendIssue;

  /// No description provided for @clinicLabel.
  ///
  /// In tr, this message translates to:
  /// **'Klinik'**
  String get clinicLabel;

  /// No description provided for @messageLabel.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get messageLabel;

  /// No description provided for @issueReportSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaşadığınız problemi ayrıntılarıyla iletin. Form, e-posta uygulamanızda hazırlanır.'**
  String get issueReportSubtitle;

  /// No description provided for @issueType.
  ///
  /// In tr, this message translates to:
  /// **'Sorun Türü'**
  String get issueType;

  /// No description provided for @technicalIssue.
  ///
  /// In tr, this message translates to:
  /// **'Teknik Sorun'**
  String get technicalIssue;

  /// No description provided for @measurementIssue.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm / Analiz Sorunu'**
  String get measurementIssue;

  /// No description provided for @orderIssue.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş Süreci'**
  String get orderIssue;

  /// No description provided for @accountIssue.
  ///
  /// In tr, this message translates to:
  /// **'Hesap / Kullanıcı Sorunu'**
  String get accountIssue;

  /// No description provided for @otherIssue.
  ///
  /// In tr, this message translates to:
  /// **'Diğer'**
  String get otherIssue;

  /// No description provided for @priority.
  ///
  /// In tr, this message translates to:
  /// **'Öncelik'**
  String get priority;

  /// No description provided for @lowPriority.
  ///
  /// In tr, this message translates to:
  /// **'Düşük'**
  String get lowPriority;

  /// No description provided for @highPriority.
  ///
  /// In tr, this message translates to:
  /// **'Yüksek'**
  String get highPriority;

  /// No description provided for @urgentPriority.
  ///
  /// In tr, this message translates to:
  /// **'Acil'**
  String get urgentPriority;

  /// No description provided for @subjectTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konu Başlığı'**
  String get subjectTitle;

  /// No description provided for @subjectTitleHint.
  ///
  /// In tr, this message translates to:
  /// **'Örn. Değerlendirme sonucu açılmıyor'**
  String get subjectTitleHint;

  /// No description provided for @issueDescription.
  ///
  /// In tr, this message translates to:
  /// **'Sorun Açıklaması'**
  String get issueDescription;

  /// No description provided for @issueDescriptionHint.
  ///
  /// In tr, this message translates to:
  /// **'Problemin hangi ekranda oluştuğunu ve varsa hata mesajını yazın.'**
  String get issueDescriptionHint;

  /// No description provided for @subjectRequired.
  ///
  /// In tr, this message translates to:
  /// **'Konu başlığı zorunludur.'**
  String get subjectRequired;

  /// No description provided for @subjectTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Konu başlığı biraz daha açıklayıcı olmalıdır.'**
  String get subjectTooShort;

  /// No description provided for @descriptionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Sorun açıklaması zorunludur.'**
  String get descriptionRequired;

  /// No description provided for @descriptionTooShort.
  ///
  /// In tr, this message translates to:
  /// **'Lütfen sorunu biraz daha ayrıntılandırın.'**
  String get descriptionTooShort;

  /// No description provided for @supportFormEmailNotice.
  ///
  /// In tr, this message translates to:
  /// **'Gönder dediğinizde e-posta uygulamanız açılır ve ileti {email} adresine hazırlanır.'**
  String supportFormEmailNotice(String email);

  /// No description provided for @emailAppOpened.
  ///
  /// In tr, this message translates to:
  /// **'Sorun bildirimi e-posta uygulamanızda hazırlandı.'**
  String get emailAppOpened;

  /// No description provided for @supportClosingNote.
  ///
  /// In tr, this message translates to:
  /// **'Destek talepleriniz en kısa sürede değerlendirilecektir.'**
  String get supportClosingNote;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In tr, this message translates to:
  /// **'Sıkça Sorulan Sorular'**
  String get frequentlyAskedQuestions;

  /// No description provided for @faqSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yaygın konuları ve yönlendirmeleri buradan inceleyin.'**
  String get faqSubtitle;

  /// No description provided for @faqResultsQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Değerlendirme sonuçlarımı nereden görebilirim?'**
  String get faqResultsQuestion;

  /// No description provided for @faqResultsAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Hesabınıza giriş yaptıktan sonra Değerlendirme Sonuçları bölümünden size ait ölçüm sonuçlarını görüntüleyebilirsiniz.'**
  String get faqResultsAnswer;

  /// No description provided for @faqOrderQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Sipariş durumumu nasıl takip ederim?'**
  String get faqOrderQuestion;

  /// No description provided for @faqOrderAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Siparişlerim bölümünden tasarım, üretim, kargo ve teslimat durumunu takip edebilirsiniz.'**
  String get faqOrderAnswer;

  /// No description provided for @faqUsageQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Ürünümü kullanırken nelere dikkat etmeliyim?'**
  String get faqUsageQuestion;

  /// No description provided for @faqUsageAnswer.
  ///
  /// In tr, this message translates to:
  /// **'İlk kullanımda ürünü kademeli kullanmanız; ağrı veya belirgin rahatsızlık hissederseniz uzmanınızla ya da destek ekibiyle iletişime geçmeniz önerilir.'**
  String get faqUsageAnswer;

  /// No description provided for @faqContactQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Destek ekibine nasıl ulaşırım?'**
  String get faqContactQuestion;

  /// No description provided for @faqContactAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfadaki telefon veya e-posta seçeneklerini kullanarak OptiYou destek ekibine ulaşabilirsiniz.'**
  String get faqContactAnswer;

  /// No description provided for @faqExpertPatientQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Yeni kullanıcı kaydı nasıl oluşturulur?'**
  String get faqExpertPatientQuestion;

  /// No description provided for @faqExpertPatientAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Uzman panelindeki Kullanıcılar bölümünden yeni kayıt oluşturabilir ve onay bağlantısını kullanıcıya gönderebilirsiniz.'**
  String get faqExpertPatientAnswer;

  /// No description provided for @faqExpertResultsQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Ölçüm sonuçları ne zaman görüntülenebilir?'**
  String get faqExpertResultsQuestion;

  /// No description provided for @faqExpertResultsAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Zorunlu klinik bilgiler, 3D tarama ve gerekli ölçüm adımları tamamlandıktan sonra sonuçlar görüntülenebilir.'**
  String get faqExpertResultsAnswer;

  /// No description provided for @faqExpertPhotoQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Referans iç taban fotoğrafı nasıl çekilmeli?'**
  String get faqExpertPhotoQuestion;

  /// No description provided for @faqExpertPhotoAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf üstten, net ve ölçek referansı görünür biçimde çekilmelidir.'**
  String get faqExpertPhotoAnswer;

  /// No description provided for @faqExpertApprovalQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Eksik adım varken ölçüm onaylanabilir mi?'**
  String get faqExpertApprovalQuestion;

  /// No description provided for @faqExpertApprovalAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Onay için zorunlu adımların tamamlanması gerekir; eksik adım varsa sistem onaya izin vermez.'**
  String get faqExpertApprovalAnswer;

  /// No description provided for @faqTeamMissingQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Operasyondaki eksik bilgiler nereden kontrol edilir?'**
  String get faqTeamMissingQuestion;

  /// No description provided for @faqTeamMissingAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Operasyon ve sipariş detay ekranlarında klinik, kullanıcı, ölçüm ve üretim adımları kontrol edilebilir.'**
  String get faqTeamMissingAnswer;

  /// No description provided for @faqTeamReportQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Klinik veya uzman kaynaklı sorunlar nasıl bildirilir?'**
  String get faqTeamReportQuestion;

  /// No description provided for @faqTeamReportAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Sorun bildirim formunda ilgili rolü, ekranı, işlem adımını ve hata ayrıntılarını belirtin.'**
  String get faqTeamReportAnswer;

  /// No description provided for @faqTeamQrQuestion.
  ///
  /// In tr, this message translates to:
  /// **'QR veya sonuç erişim bağlantısı çalışmazsa ne yapılmalı?'**
  String get faqTeamQrQuestion;

  /// No description provided for @faqTeamQrAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Oturumun onaylandığını ve davet bağlantısının geçerli olduğunu kontrol edin; sorun sürerse destek ekibine bildirin.'**
  String get faqTeamQrAnswer;

  /// No description provided for @faqTeamSystemQuestion.
  ///
  /// In tr, this message translates to:
  /// **'Sistemsel hata bildiriminde hangi bilgiler gereklidir?'**
  String get faqTeamSystemQuestion;

  /// No description provided for @faqTeamSystemAnswer.
  ///
  /// In tr, this message translates to:
  /// **'Ekran, kullanıcı rolü, işlem adımı, hata mesajı ve mümkünse ekran görüntüsü paylaşılmalıdır.'**
  String get faqTeamSystemAnswer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
