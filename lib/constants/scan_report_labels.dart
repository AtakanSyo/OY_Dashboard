class ScanReportLabels {
  static const Map<String, String> map = {
    // Genel
    'Rapor Bilgileri': 'Rapor Bilgileri',
    'Kullanıcı Bilgileri': 'Kullanıcı Bilgileri',

    // Length
    'Foot length': 'Ayak Uzunluğu',
    'Sole length': 'Taban Uzunluğu',
    'Arch length': 'Kemer Uzunluğu',
    'First meta length': '1. Metatars Uzunluğu',
    'Fifth meta length': '5. Metatars Uzunluğu',
    'Hallux bumps length': 'Halluks Çıkıntı Uzunluğu',
    'Foot flank length': 'Ayak Yan Uzunluğu',
    'Heel center length': 'Topuk Merkez Uzunluğu',
    'Heel margin length': 'Topuk Kenar Uzunluğu',

    // Width
    'Foot width': 'Ayak Genişliği',
    'Slant width': 'Eğimli Genişlik',
    'Toe width': 'Parmak Genişliği',
    'Arch outside width': 'Kemer Dış Genişliği',
    'Foot flank width': 'Ayak Yan Genişliği',
    'Heel center width': 'Topuk Merkez Genişliği',
    'Total heel width': 'Toplam Topuk Genişliği',

    // Height
    'Arch height': 'Kemer Yüksekliği',
    'First meta joint height': '1. Metatars Eklem Yüksekliği',
    'Heel protrusion height': 'Topuk Çıkıntı Yüksekliği',

    // Angle
    'Hallux angle': 'Halluks Açısı',
    'Pronator angle': 'Pronasyon Açısı',
    'Knee angle': 'Diz Açısı',

    // Analysis
    'Arch type': 'Kemer Tipi',
    'Arch index': 'Kemer İndeksi',
    'Arch width index': 'Kemer Genişlik İndeksi',

    'Hallux type': 'Halluks Tipi',
    'Heel type': 'Topuk Tipi',
    'Knee type': 'Diz Tipi',

    // Shoe
    'Shoe size': 'Ayakkabı Numarası',
    'Insole recommendation': 'İç Taban Önerisi',

    // Misc
    'Recommendation': 'Genel Öneri',
  };

  static String tr(String key) {
    return map[key] ?? key;
  }
}