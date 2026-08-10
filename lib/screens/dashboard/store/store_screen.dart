import 'package:flutter/material.dart';
import 'package:oy_site/models/store_product_model.dart';
import 'package:oy_site/screens/dashboard/store/store_product_detail_screen.dart';
import 'package:oy_site/models/store_measurement_summary_model.dart';

class StoreScreen extends StatelessWidget {
  final String currentUserEmail;

  const StoreScreen({
    super.key,
    required this.currentUserEmail,
  });

  @override
  Widget build(BuildContext context) {
    final measurement = StoreMeasurementSummary(
      sessionCode: 'SES-2026-0408',
      analysisDate: DateTime(2026, 4, 8),
      locationLabel: 'OptiYou İzmir',
      shortMessage:
          'Bu sayfadaki ürünler son ölçüm verilerinize göre hazırlanacaktır.',
    );

    final products = <StoreProduct>[
      const StoreProduct(
        id: 'custom-insole',
        title: 'Kişisel İç Tabanlık',
        shortDescription:
            'Günlük kullanım için kişiye özel destek ve konfor sağlar.',
        fullDescription:
            'Kişisel İç Tabanlık, son ölçüm verilerinize göre ayağınıza özel olarak tasarlanır. Günlük kullanımda basınç dağılımını iyileştirmeye, konforu artırmaya ve ayak yapınıza uygun destek sunmaya yardımcı olur.',
        usageTitle: 'Kimler için uygun?',
        usageDescription:
            'Uzun süre ayakta kalan, günlük konforunu artırmak isteyen ve kişisel destek ihtiyacı bulunan kullanıcılar için uygundur.',
        whyRecommended:
            'Son ölçümünüzde kemer desteği ihtiyacı ve yük dağılımında dengesizlik görüldüğü için bu ürün önerilmektedir.',
        priceLabel: '4.000 TL',
        icon: Icons.accessibility_new,
        imagePath: 'assets/images/products/custom_insole.png',
        isAddOn: false,
        canBePurchasedAlone: true,
      ),
      const StoreProduct(
        id: 'sport-insole',
        title: 'Spor İç Tabanlığı',
        shortDescription:
            'Hareketli yaşam ve spor kullanımı için dinamik destek sunar.',
        fullDescription:
            'Spor İç Tabanlığı, yürüyüş, antrenman ve aktif kullanım için destekleyici yapı sunar. Ayağın yük dağılımını daha dengeli hale getirmeye yardımcı olurken hareket sırasında konforun korunmasını hedefler.',
        usageTitle: 'Kimler için uygun?',
        usageDescription:
            'Daha aktif yaşam tarzına sahip, spor yapan veya gün içinde daha yüksek hareket yoğunluğuna sahip kullanıcılar için uygundur.',
        whyRecommended:
            'Son ölçümünüzde hareket sırasında destek ihtiyacı öngörüldüğü için spor kullanımı için bu ürün önerilmektedir.',
        priceLabel: '4.500 TL',
        icon: Icons.directions_run,
        imagePath: 'assets/images/products/sport_insole.png',
        isAddOn: false,
        canBePurchasedAlone: true,
      ),

      // Yan ürünler
      const StoreProduct(
        id: 'heel-pad',
        title: 'Topuk Pedi',
        shortDescription:
            'Topuk bölgesindeki yükü azaltmaya yardımcı tamamlayıcı ürün.',
        fullDescription:
            'Topuk Pedi, topuk bölgesinde konforu artırmak ve yük dağılımını desteklemek amacıyla kullanılan yardımcı bir üründür.',
        usageTitle: 'Kimler için uygun?',
        usageDescription:
            'Topuk bölgesinde hassasiyet yaşayan veya ek yastılama ihtiyacı olan kullanıcılar için uygundur.',
        whyRecommended:
            'Ana ürün kullanımını desteklemek ve topuk rahatlığını artırmak için sepete eklenebilir.',
        priceLabel: '350 TL',
        icon: Icons.radio_button_checked,
        imagePath: 'assets/images/addons/heel_pad.png',
        isAddOn: true,
        canBePurchasedAlone: true,
      ),
      const StoreProduct(
        id: 'met-pad',
        title: 'Metatarsal Destek Pedi',
        shortDescription:
            'Ön ayak bölgesine ek rahatlık ve destek sağlayan yan ürün.',
        fullDescription:
            'Metatarsal Destek Pedi, özellikle ön ayak bölgesinde basınç hissedilen durumlarda konfor desteği sağlar.',
        usageTitle: 'Kimler için uygun?',
        usageDescription:
            'Ön ayak bölgesinde yük artışı hisseden veya ek destek isteyen kullanıcılar için uygundur.',
        whyRecommended:
            'Özellikle spor ve günlük kullanımda tamamlayıcı destek amacıyla önerilir.',
        priceLabel: '420 TL',
        icon: Icons.blur_circular,
        imagePath: 'assets/images/addons/met_pad.png',
        isAddOn: true,
        canBePurchasedAlone: true,
      ),
      const StoreProduct(
        id: 'cleaning-spray',
        title: 'Temizleme Spreyi',
        shortDescription:
            'İç tabanlık ve yardımcı ürünlerin bakımı için pratik çözüm.',
        fullDescription:
            'Temizleme Spreyi, ürünlerinizi daha hijyenik ve uzun ömürlü kullanmanıza yardımcı olur.',
        usageTitle: 'Kimler için uygun?',
        usageDescription:
            'Ürün bakımını düzenli yapmak isteyen tüm kullanıcılar için uygundur.',
        whyRecommended:
            'Ürünün kullanım ömrünü korumaya yardımcı tamamlayıcı bir bakım ürünüdür.',
        priceLabel: '250 TL',
        icon: Icons.cleaning_services_outlined,
        imagePath: 'assets/images/addons/cleaning_spray.png',
        isAddOn: true,
        canBePurchasedAlone: true,
      ),
      const StoreProduct(
        id: 'carry-case',
        title: 'Taşıma Kılıfı',
        shortDescription:
            'İç tabanlık ürünlerinizi korumak ve taşımak için kompakt kılıf.',
        fullDescription:
            'Taşıma Kılıfı, ürünlerinizi çanta içinde koruyarak daha düzenli ve güvenli taşımanıza yardımcı olur.',
        usageTitle: 'Kimler için uygun?',
        usageDescription:
            'İç tabanlıklarını yanında taşıyan ve ürünlerini korumak isteyen kullanıcılar için uygundur.',
        whyRecommended:
            'Ana ürün kullanımını tamamlayan pratik bir yardımcı üründür.',
        priceLabel: '300 TL',
        icon: Icons.inventory_2_outlined,
        imagePath: 'assets/images/addons/carry_case.png',
        isAddOn: true,
        canBePurchasedAlone: true,
      ),
    ];

    final mainProducts = products.where((p) => !p.isAddOn).toList();
    final addOnProducts = products.where((p) => p.isAddOn).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mağaza'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildMeasurementCard(
                  measurement: measurement,
                  compact: true,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(
                  title: 'Ana Ürünler',
                  subtitle:
                      'Aşağıdaki ürünler son ölçüm verilerinize göre hazırlanır.',
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: mainProducts.map((product) {
                    return StoreProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoreProductDetailScreen(
                              product: product,
                              measurement: measurement,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  title: 'Yan Ürünler',
                  subtitle:
                      'Siparişinize ekleyebileceğiniz tamamlayıcı ürünler.',
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: addOnProducts.map((product) {
                    return AddOnProductCard(
                      product: product,
                      onAddToCart: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.title} sepete eklendi.'),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

Widget buildMeasurementCard({
  required StoreMeasurementSummary measurement,
  required bool compact,
}) {
  return Container(
    width: compact ? 420 : double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8,
        ),
      ],
      border: Border.all(
        color: Colors.teal.withOpacity(0.12),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.teal.withOpacity(0.12),
              child: const Icon(
                Icons.fact_check_outlined,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Son Ölçüm',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        buildMeasurementKeyValueRow('Session', measurement.sessionCode),
        buildMeasurementKeyValueRow('Tarih', measurement.formattedDate),
        buildMeasurementKeyValueRow('Yer', measurement.locationLabel),
        const SizedBox(height: 10),
        Text(
          measurement.shortMessage,
          style: TextStyle(
            color: Colors.grey[700],
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}

Widget buildMeasurementKeyValueRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

class StoreProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onTap;

  const StoreProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 330,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.grey.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          product.imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Text(
                              'Görsel yok',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(
                          product.icon,
                          size: 14,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              product.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.shortDescription,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              product.priceLabel,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.black38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddOnProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onAddToCart;

  const AddOnProductCard({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 120,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: Image.asset(
                product.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text('Görsel yok'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            product.shortDescription,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            product.priceLabel,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToCart,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Sepete Ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
