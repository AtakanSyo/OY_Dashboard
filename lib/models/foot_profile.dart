class FootProfile {
  final String email;
  final DateTime date;

  /// Sol ayak
  final double leftLength;
  final double leftWidth;
  final double leftArchHeight;
  final String leftArchType;
  final String leftPronType;
  final String leftToeType;
  final String leftHalluxType;   // 🔥 GÜNCELLEME

  /// Sağ ayak
  final double rightLength;
  final double rightWidth;
  final double rightArchHeight;
  final String rightArchType;
  final String rightPronType;
  final String rightToeType;
  final String rightHalluxType;  // 🔥 GÜNCELLEME

  const FootProfile({
    required this.email,
    required this.date,
    required this.leftLength,
    required this.leftWidth,
    required this.leftArchHeight,
    required this.leftArchType,
    required this.leftPronType,
    required this.leftToeType,
    required this.leftHalluxType,
    required this.rightLength,
    required this.rightWidth,
    required this.rightArchHeight,
    required this.rightArchType,
    required this.rightPronType,
    required this.rightToeType,
    required this.rightHalluxType,
  });

  // ---------------------------------------------------------
  // 🔥 Sol ve sağ satırları tek profile çeviren factory
  // ---------------------------------------------------------
  factory FootProfile.fromPair(
    Map<String, dynamic> left,
    Map<String, dynamic> right,
  ) {
    return FootProfile(
      email: (left['user_email'] ?? "").toString(),

      /// Tarihi ilk aşamada now olarak koyuyoruz, sonra copyWithDate ile düzeltiyoruz
      date: DateTime.now(),

      // -------- SOL AYAK --------
      leftLength: _d(left['feetLength']),
      leftWidth: _d(left['feetWidth']),
      leftArchHeight: _d(left['footArchHgt']),
      leftArchType: (left['archType'] ?? "").toString(),
      leftPronType: (left['pronType'] ?? "").toString(),
      leftToeType: (left['toeType'] ?? "").toString(),
      leftHalluxType: (left['halluxType'] ?? "").toString(),   // 🔥 GÜNCEL ALAN

      // -------- SAĞ AYAK --------
      rightLength: _d(right['feetLength']),
      rightWidth: _d(right['feetWidth']),
      rightArchHeight: _d(right['footArchHgt']),
      rightArchType: (right['archType'] ?? "").toString(),
      rightPronType: (right['pronType'] ?? "").toString(),
      rightToeType: (right['toeType'] ?? "").toString(),
      rightHalluxType: (right['halluxType'] ?? "").toString(), // 🔥 GÜNCEL ALAN
    );
  }

  // ---------------------------------------------------------
  // 🔧 Double parse yardımcısı
  // ---------------------------------------------------------
  static double _d(dynamic v) =>
      double.tryParse(v?.toString() ?? "") ?? 0;

  // ---------------------------------------------------------
  // 📌 Tarihi CSV’den gelen gerçek ScanTime ile güncellemek için
  // ---------------------------------------------------------
  FootProfile copyWithDate(DateTime newDate) {
    return FootProfile(
      email: email,
      date: newDate,

      // Sol ayak
      leftLength: leftLength,
      leftWidth: leftWidth,
      leftArchHeight: leftArchHeight,
      leftArchType: leftArchType,
      leftPronType: leftPronType,
      leftToeType: leftToeType,
      leftHalluxType: leftHalluxType,

      // Sağ ayak
      rightLength: rightLength,
      rightWidth: rightWidth,
      rightArchHeight: rightArchHeight,
      rightArchType: rightArchType,
      rightPronType: rightPronType,
      rightToeType: rightToeType,
      rightHalluxType: rightHalluxType,
    );
  }

  // ---------------------------------------------------------
  // 📌 Derived özellikler
  // ---------------------------------------------------------

  bool get hasFlatFoot =>
      leftArchType.toLowerCase().contains("flat") ||
      rightArchType.toLowerCase().contains("flat");

  bool get hasHighArch =>
      leftArchType.toLowerCase().contains("high") ||
      rightArchType.toLowerCase().contains("high");

  bool get hasHalluxIssue =>
      leftHalluxType.toLowerCase() != "normal" ||
      rightHalluxType.toLowerCase() != "normal";

  double get averageArchHeight =>
      (leftArchHeight + rightArchHeight) / 2;

  String get dateString =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}
