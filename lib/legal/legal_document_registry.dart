import 'legal_document.dart';

import 'documents/aydinlatma_metni.dart';
import 'documents/uyelik_sozlesmesi.dart';
import 'documents/mesafeli_satis_sozlesmesi.dart';
import 'documents/on_bilgilendirme_formu.dart';
import 'documents/iade_iptal_degisim.dart';
import 'documents/gizlilik_guvenlik.dart';
import 'documents/kullanim_kosullari.dart';
import 'documents/cerez_tercihleri.dart';
import 'documents/ticari_elektronik_ileti.dart';
import 'documents/tuketici_korunmasi_kanunu.dart';
import 'documents/guvenli_alisveris.dart';

class LegalDocumentCodes {
  static const String aydinlatmaMetni = 'aydinlatma_metni';

  static const String uyelikSozlesmesi =
      'uyelik_sozlesmesi';

  static const String mesafeliSatisSozlesmesi =
      'mesafeli_satis_sozlesmesi';

  static const String onBilgilendirmeFormu =
      'on_bilgilendirme_formu';

  static const String iadeIptalDegisim =
      'iade_iptal_degisim';

  static const String gizlilikGuvenlik =
      'gizlilik_ve_guvenlik';

  static const String kullanimKosullari =
      'kullanim_kosullari';

  static const String cerezTercihleri =
      'cerez_tercihleri';

  static const String ticariElektronikIleti =
      'ticari_elektronik_ileti';

  static const String tuketiciKorunmasiKanunu =
      'tuketici_korunmasi_kanunu';

  static const String guvenliAlisveris =
      'guvenli_alisveris';
}

class LegalDocumentRegistry {
  static const List<LegalDocument> all = [
    LegalDocument(
      code: LegalDocumentCodes.aydinlatmaMetni,
      title: 'Aydınlatma Metni',
      version: '1.0.0',
      content: aydinlatmaMetniContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.uyelikSozlesmesi,
      title: 'Üyelik Sözleşmesi',
      version: '1.0.0',
      content: uyelikSozlesmesiContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.mesafeliSatisSozlesmesi,
      title: 'Mesafeli Satış Sözleşmesi',
      version: '1.0.0',
      content: mesafeliSatisSozlesmesiContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.onBilgilendirmeFormu,
      title: 'Ön Bilgilendirme Formu',
      version: '1.0.0',
      content: onBilgilendirmeFormuContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.iadeIptalDegisim,
      title: 'İade, İptal ve Değişim',
      version: '1.0.0',
      content: iadeIptalDegisimContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.gizlilikGuvenlik,
      title: 'Gizlilik ve Güvenlik',
      version: '1.0.0',
      content: gizlilikGuvenlikContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.kullanimKosullari,
      title: 'Kullanım Koşulları',
      version: '1.0.0',
      content: kullanimKosullariContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.cerezTercihleri,
      title: 'Çerez Tercihleri',
      version: '1.0.0',
      content: cerezTercihleriContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.ticariElektronikIleti,
      title: 'Ticari Elektronik İleti',
      version: '1.0.0',
      content: ticariElektronikIletiContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.tuketiciKorunmasiKanunu,
      title: 'Tüketici Korunması Kanunu',
      version: '1.0.0',
      content: tuketiciKorunmasiKanunuContent,
    ),

    LegalDocument(
      code: LegalDocumentCodes.guvenliAlisveris,
      title: 'Güvenli Alışveriş',
      version: '1.0.0',
      content: guvenliAlisverisContent,
    ),
  ];

  static LegalDocument? findByCode(String code) {
    for (final document in all) {
      if (document.code == code) {
        return document;
      }
    }

    return null;
  }
}