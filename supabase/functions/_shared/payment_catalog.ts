export interface PaymentProduct {
  id: string;
  nameTr: string;
  nameEn: string;
  productType: string;
  price: number;
  currency: "TRY";
  category: string;
}

const products: Record<string, PaymentProduct> = {
  "custom-insole": {
    id: "custom-insole",
    nameTr: "Kişiye Özel İç Taban",
    nameEn: "Custom Insole",
    productType: "insole",
    price: 4000,
    currency: "TRY",
    category: "Kişiselleştirilmiş Ürünler",
  },
  "sport-insole": {
    id: "sport-insole",
    nameTr: "Spor İç Tabanlığı",
    nameEn: "Sports Insole",
    productType: "sports_insole",
    price: 4500,
    currency: "TRY",
    category: "Kişiselleştirilmiş Ürünler",
  },
  "heel-pad": {
    id: "heel-pad",
    nameTr: "Topuk Pedi",
    nameEn: "Heel Pad",
    productType: "heel_pad",
    price: 350,
    currency: "TRY",
    category: "Tamamlayıcı Ürünler",
  },
  "met-pad": {
    id: "met-pad",
    nameTr: "Metatarsal Destek Pedi",
    nameEn: "Metatarsal Support Pad",
    productType: "met_pad",
    price: 420,
    currency: "TRY",
    category: "Tamamlayıcı Ürünler",
  },
  "cleaning-spray": {
    id: "cleaning-spray",
    nameTr: "Temizleme Spreyi",
    nameEn: "Cleaning Spray",
    productType: "cleaning_spray",
    price: 250,
    currency: "TRY",
    category: "Tamamlayıcı Ürünler",
  },
  "carry-case": {
    id: "carry-case",
    nameTr: "Taşıma Çantası",
    nameEn: "Carry Case",
    productType: "carry_case",
    price: 300,
    currency: "TRY",
    category: "Tamamlayıcı Ürünler",
  },
};

export function getPaymentProduct(productId: string): PaymentProduct | null {
  return products[productId] ?? null;
}

export function localizedProductName(
  product: PaymentProduct,
  locale: string,
): string {
  return locale === "en" ? product.nameEn : product.nameTr;
}
