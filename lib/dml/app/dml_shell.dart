import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';
import 'package:oy_site/dml/screens/about/dml_about_screen.dart';
import 'package:oy_site/dml/screens/catalog/dml_catalog_screen.dart';
import 'package:oy_site/dml/screens/cases/dml_case_studies_screen.dart';
import 'package:oy_site/dml/screens/explore/dml_explore_screen.dart';
import 'package:oy_site/dml/screens/guides/dml_guides_screen.dart';
import 'package:oy_site/dml/screens/home/dml_home_screen.dart';
import 'package:oy_site/dml/screens/pricing/dml_pricing_screen.dart';
import 'package:oy_site/dml/screens/request/dml_request_wizard_screen.dart';
import 'package:oy_site/dml/screens/workflow/dml_workflow_screen.dart';

enum DmlSection {
  home,
  catalog,
  request,
  myRequests,
  explore,
  cases,
  workflow,
  pricing,
  guides,
  about,
}

class DmlShell extends StatefulWidget {
  const DmlShell({super.key});

  @override
  State<DmlShell> createState() => _DmlShellState();
}

class _DmlShellState extends State<DmlShell> {
  DmlSection _selected = DmlSection.home;

  void _select(DmlSection section) {
    setState(() => _selected = section);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DmlTheme.data,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 980;
          return Scaffold(
            appBar: desktop ? null : _buildMobileAppBar(),
            drawer: desktop
                ? null
                : Drawer(child: _buildNavigation(isDrawer: true)),
            body: Row(
              children: [
                if (desktop) SizedBox(width: 260, child: _buildNavigation()),
                Expanded(
                  child: Column(
                    children: [
                      if (desktop) _buildTopBar(),
                      Expanded(child: _buildSelectedPage()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: DmlColors.ink,
      foregroundColor: Colors.white,
      title: const Text('DML'),
      actions: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          tooltip: 'Ana sayfaya dön',
          icon: const Icon(Icons.exit_to_app),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: DmlColors.mist)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titleFor(_selected),
              style: const TextStyle(
                color: DmlColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_return, size: 18),
            label: const Text('Ana sayfaya dön'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation({bool isDrawer = false}) {
    return ColoredBox(
      color: DmlColors.ink,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
              child: Image.asset(
                'assets/images/dml/dml_logo.png',
                height: 94,
                fit: BoxFit.contain,
              ),
            ),
            const Divider(color: Color(0xFF35484C), height: 1),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _navItem(
                    DmlSection.home,
                    Icons.home_outlined,
                    'Ana Sayfa',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.catalog,
                    Icons.grid_view_outlined,
                    'Anatomik Modeller',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.request,
                    Icons.add_box_outlined,
                    'Talep Oluştur',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.myRequests,
                    Icons.assignment_outlined,
                    'Taleplerim',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.explore,
                    Icons.explore_outlined,
                    'Keşfet',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.cases,
                    Icons.auto_stories_outlined,
                    'Vaka Çalışmaları',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.workflow,
                    Icons.route_outlined,
                    'Nasıl Çalışır?',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.pricing,
                    Icons.payments_outlined,
                    'Hizmet ve Fiyatlar',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.guides,
                    Icons.menu_book_outlined,
                    'Rehber ve Yardım',
                    isDrawer: isDrawer,
                  ),
                  _navItem(
                    DmlSection.about,
                    Icons.account_balance_outlined,
                    'DML Hakkında',
                    isDrawer: isDrawer,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.keyboard_return),
                  label: const Text('Ana sayfaya dön'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFD2DCDD),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    DmlSection section,
    IconData icon,
    String title, {
    required bool isDrawer,
  }) {
    final selected = section == _selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected ? const Color(0xFF34474B) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          selected: selected,
          leading: Icon(
            icon,
            color: selected ? Colors.white : DmlColors.accent,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFFD2DCDD),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          onTap: () {
            _select(section);
            if (isDrawer) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildSelectedPage() {
    switch (_selected) {
      case DmlSection.home:
        return DmlHomeScreen(
          onCatalogTap: () => _select(DmlSection.catalog),
          onCustomRequestTap: () => _select(DmlSection.request),
          onCasesTap: () => _select(DmlSection.cases),
          onHelpTap: () => _select(DmlSection.guides),
        );
      case DmlSection.catalog:
        return DmlCatalogScreen(
          onRequestTap: () => _select(DmlSection.request),
        );
      case DmlSection.request:
        return const DmlRequestWizardScreen();
      case DmlSection.myRequests:
        return const _DmlEmptyState(
          icon: Icons.assignment_outlined,
          title: 'Henüz bir talebiniz bulunmuyor',
          description:
              'Gönderdiğiniz model ve üretim taleplerinin tüm aşamalarını burada takip edebileceksiniz.',
        );
      case DmlSection.explore:
        return DmlExploreScreen(
          onRequestTap: () => _select(DmlSection.request),
        );
      case DmlSection.cases:
        return DmlCaseStudiesScreen(
          onRequestTap: () => _select(DmlSection.request),
        );
      case DmlSection.workflow:
        return DmlWorkflowScreen(
          onRequestTap: () => _select(DmlSection.request),
        );
      case DmlSection.pricing:
        return DmlPricingScreen(
          onRequestTap: () => _select(DmlSection.request),
        );
      case DmlSection.guides:
        return DmlGuidesScreen(onRequestTap: () => _select(DmlSection.request));
      case DmlSection.about:
        return const DmlAboutScreen();
    }
  }

  String _titleFor(DmlSection section) {
    switch (section) {
      case DmlSection.home:
        return 'Dijital Üretim Laboratuvarı';
      case DmlSection.catalog:
        return 'Anatomik Model Kataloğu';
      case DmlSection.request:
        return 'Yeni Talep Oluştur';
      case DmlSection.myRequests:
        return 'Taleplerim';
      case DmlSection.explore:
        return 'DML’yi Keşfet';
      case DmlSection.cases:
        return 'Vaka Çalışmaları';
      case DmlSection.workflow:
        return 'Nasıl Çalışır?';
      case DmlSection.pricing:
        return 'Hizmet ve Fiyatlandırma';
      case DmlSection.guides:
        return 'Rehber ve Yardım';
      case DmlSection.about:
        return 'DML Hakkında ve Ziyaret';
    }
  }
}

// ignore: unused_element
class _DmlCatalogPreview extends StatelessWidget {
  final VoidCallback onRequestTap;

  const _DmlCatalogPreview({required this.onRequestTap});

  @override
  Widget build(BuildContext context) {
    const models = [
      ('Kafatası modeli', 'Kafa ve boyun', Icons.face_outlined),
      ('Diz eklemi modeli', 'Alt ekstremite', Icons.accessibility_new_outlined),
      ('Omurga eğitim seti', 'Omurga', Icons.view_in_ar_outlined),
      ('Kalp anatomisi', 'Organ modelleri', Icons.favorite_border),
    ];
    return _DmlPageFrame(
      title: 'Hazır anatomik modeller',
      description:
          'Eğitim, araştırma ve demonstrasyon amaçlı model seçeneklerini inceleyin.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900
              ? 4
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: models
                .map(
                  (model) => Container(
                    width: width,
                    padding: const EdgeInsets.all(20),
                    decoration: _previewCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: DmlColors.mist,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            model.$3,
                            size: 62,
                            color: DmlColors.slate,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          model.$2.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: DmlColors.slate,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          model.$1,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: onRequestTap,
                          child: const Text('Bilgi ve talep'),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// TODO: Remove after the new request wizard is approved visually.
// ignore: unused_element
class _DmlRequestPreview extends StatelessWidget {
  const _DmlRequestPreview();

  @override
  Widget build(BuildContext context) {
    const options = [
      (
        'Medikal görüntüden model',
        'CT veya MR verilerinizden kişiye özel anatomik model.',
        Icons.medical_information_outlined,
      ),
      (
        'Hazır anatomik model',
        'Katalogdaki bir model için üretim veya özelleştirme talebi.',
        Icons.view_in_ar_outlined,
      ),
      (
        'Araştırma ve prototip',
        'Akademik çalışma, aparat veya yeni ürün fikri için destek.',
        Icons.science_outlined,
      ),
      (
        'Hangi hizmet olduğunu bilmiyorum',
        'İhtiyacınızı anlatın, DML ekibi doğru akışa yönlendirsin.',
        Icons.route_outlined,
      ),
    ];
    return _DmlPageFrame(
      title: 'Ne üretmek istiyorsunuz?',
      description:
          'Teknik yöntem seçmenize gerek yok. Size en yakın ihtiyacı seçerek başlayın.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760 ? 2 : 1;
          final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: options
                .map(
                  (option) => Container(
                    width: width,
                    padding: const EdgeInsets.all(24),
                    decoration: _previewCardDecoration(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: DmlColors.ink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(option.$3, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.$1,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                option.$2,
                                style: const TextStyle(
                                  color: DmlColors.slate,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Bu akış yakında aktif olacak',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _DmlExplorePreview extends StatelessWidget {
  const _DmlExplorePreview();

  @override
  Widget build(BuildContext context) {
    return const _DmlPageFrame(
      title: 'Laboratuvarı keşfedin',
      description:
          'Üretim altyapısı, örnek çalışmalar, hizmetler ve laboratuvar hakkında içerikler.',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          _ExploreTile(
            Icons.precision_manufacturing_outlined,
            'Üretim altyapımız',
            '3D baskı, CNC işleme ve son işlem olanakları.',
          ),
          _ExploreTile(
            Icons.auto_stories_outlined,
            'Vaka çalışmaları',
            'Geçmiş projelerin problem, süreç ve sonuçları.',
          ),
          _ExploreTile(
            Icons.account_balance_outlined,
            'DML hakkında',
            'Laboratuvarın amacı, ekibi ve iş birliği modeli.',
          ),
          _ExploreTile(
            Icons.payments_outlined,
            'Hizmet ve fiyatlandırma',
            'Standart hizmetler ve teklif gerektiren çalışmalar.',
          ),
        ],
      ),
    );
  }
}

// TODO: Remove after the guide center is approved visually.
// ignore: unused_element
class _DmlHelpPreview extends StatelessWidget {
  const _DmlHelpPreview();

  @override
  Widget build(BuildContext context) {
    const guides = [
      (
        'DICOM nedir?',
        'Medikal görüntü dosyalarını ve paylaşım öncesi dikkat edilmesi gerekenleri öğrenin.',
      ),
      (
        'CT’den 3D modele',
        'Görüntü yüklemeden fiziksel model teslimine kadar temel adımları görün.',
      ),
      (
        'Hangi üretim yöntemi?',
        'FDM, SLA ve CNC arasındaki farkları kullanım amacı üzerinden keşfedin.',
      ),
      (
        'İyi bir talep nasıl hazırlanır?',
        'Talebinizin hızlı değerlendirilebilmesi için kısa kontrol listesini inceleyin.',
      ),
    ];
    return _DmlPageFrame(
      title: 'Başlamak için bilmeniz gerekenler',
      description:
          'Teknik terimleri sade anlatımlarla öğrenin veya doğrudan DML ekibinden yönlendirme isteyin.',
      child: Column(
        children: guides
            .map(
              (guide) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: _previewCardDecoration(),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_outlined, color: DmlColors.ink),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guide.$1,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            guide.$2,
                            style: const TextStyle(color: DmlColors.slate),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: DmlColors.slate),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DmlEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DmlEmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: const BoxDecoration(
                  color: DmlColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: DmlColors.ink),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: DmlColors.slate, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DmlPageFrame extends StatelessWidget {
  final String title;
  final String description;
  final Widget child;

  const _DmlPageFrame({
    required this.title,
    required this.description,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: DmlColors.ink,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 15,
                  color: DmlColors.slate,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ExploreTile(this.icon, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(22),
      decoration: _previewCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: DmlColors.ink),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            style: const TextStyle(color: DmlColors.slate, height: 1.4),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _previewCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: DmlColors.mist),
  );
}
