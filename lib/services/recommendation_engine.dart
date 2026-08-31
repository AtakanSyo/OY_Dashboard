import '../models/foot_profile.dart';

class RecommendedPackage {
  final String mainProductId;
  final List<String> addonProductIds;
  final String reason;

  RecommendedPackage({
    required this.mainProductId,
    required this.addonProductIds,
    required this.reason,
  });
}

class RecommendationEngine {
  static RecommendedPackage generate(FootProfile p) {

    /// ---------------------------------------------------------
    /// 🔥 1. AŞIRI DÜZ TABAN (Flat / Mild Flat / Severe Flat)
    /// ---------------------------------------------------------
    if (p.leftArchType.toLowerCase().contains("flat") ||
        p.rightArchType.toLowerCase().contains("flat")) 
    {
      return RecommendedPackage(
        mainProductId: "PRD001", // Ortopedik insole
        addonProductIds: ["PRD003"],
        reason:
            "Düşük ayak kavisiniz tespit edildi. Destekleyici ortopedik tabanlık öneriyoruz.",
      );
    }

    /// ---------------------------------------------------------
    /// 🔥 2. YÜKSEK KAVİS (High Arch)
    /// ---------------------------------------------------------
    if (p.leftArchType.toLowerCase().contains("high") ||
        p.rightArchType.toLowerCase().contains("high")) 
    {
      return RecommendedPackage(
        mainProductId: "PRD003", // Heel cushion
        addonProductIds: ["PRD001"],
        reason:
            "Ayak kavisiniz yüksek görünüyor. Basıncı dengeleyen destek ürünleri önerilir.",
      );
    }

    /// ---------------------------------------------------------
    /// 🔥 3. PRONASYON (Over-pronated / Valgus)
    /// ---------------------------------------------------------
    if (p.leftPronType.toLowerCase().contains("valgus") ||
        p.rightPronType.toLowerCase().contains("valgus") ||
        p.leftPronType.toLowerCase().contains("pron") ||
        p.rightPronType.toLowerCase().contains("pron")) 
    {
      return RecommendedPackage(
        mainProductId: "PRD001", // Stabilizing insole
        addonProductIds: ["PRD003"],
        reason:
            "Ayakta içe basma (pronasyon/valgus) tespit edildi. Stabilite sağlayan tabanlık öneriyoruz.",
      );
    }

    /// ---------------------------------------------------------
    /// 🔥 4. HALLUX PROBLEMLERİ (Hallux Valgus / Mod / Inward ...)
    /// ---------------------------------------------------------
    if (p.leftHalluxType.toLowerCase() != "normal hallux" ||
        p.rightHalluxType.toLowerCase() != "normal hallux") 
    {
      return RecommendedPackage(
        mainProductId: "PRD002", // Hallux Corrector
        addonProductIds: ["PRD001"],
        reason:
            "Başparmak açısında deformasyon tespit edildi. Düzeltici gece ateli önerilir.",
      );
    }

    /// ---------------------------------------------------------
    /// 🔥 5. ÇOCUK PROFİLİ (<220mm)
    /// ---------------------------------------------------------
    if (p.leftLength < 220 || p.rightLength < 220) {
      return RecommendedPackage(
        mainProductId: "PRD004",
        addonProductIds: ["PRD003"],
        reason:
            "Çocuk ayak profili tespit edildi. Gelişimi destekleyen tabanlık önerilir.",
      );
    }

    /// ---------------------------------------------------------
    /// 🔥 6. GENEL ÖNERİ
    /// ---------------------------------------------------------
    return RecommendedPackage(
      mainProductId: "PRD001",
      addonProductIds: ["PRD003"],
      reason:
          "Ayak yapınız genel olarak dengeli. Konforu artırmak için destekleyici ürün öneriyoruz.",
    );
  }
}
