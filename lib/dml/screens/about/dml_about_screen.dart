import 'package:flutter/material.dart';
import 'package:oy_site/dml/app/dml_theme.dart';

class DmlAboutScreen extends StatefulWidget {
  const DmlAboutScreen({super.key});

  @override
  State<DmlAboutScreen> createState() => _DmlAboutScreenState();
}

class _DmlAboutScreenState extends State<DmlAboutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _purpose = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _purpose.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          size: 42,
          color: DmlColors.ink,
        ),
        title: const Text('Ziyaret talebi hazırlandı'),
        content: const Text(
          'Bu prototip sürümünde bilgiler sunucuya gönderilmedi. Entegrasyon aşamasında talep DML ekibinin değerlendirme akışına bağlanacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 700 ? 16.0 : 28.0;
        final compact = constraints.maxWidth < 820;
        final about = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DML hakkında',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: DmlColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'İZTÜ Dijital Üretim Laboratuvarı; medikal görüntü, dijital tasarım ve üretim olanaklarını üniversitenin uzmanları, araştırmacıları ve öğrencileri için erişilebilir bir çalışma ortamında buluşturur.',
              style: TextStyle(
                color: DmlColors.slate,
                height: 1.55,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            const _InfoTile(
              Icons.hub_outlined,
              'Disiplinler arası çalışma',
              'Klinik bilgi ile tasarım ve üretim uzmanlığını ortak bir süreçte bir araya getirir.',
            ),
            const _InfoTile(
              Icons.school_outlined,
              'Eğitim ve araştırma',
              'Öğrenme modellerinden deney aparatlarına kadar uygulamalı akademik çalışmaları destekler.',
            ),
            const _InfoTile(
              Icons.lightbulb_outline,
              'Fikirden prototipe',
              'Teknik üretim bilgisi gerektirmeden ihtiyacınızı anlatabileceğiniz yönlendirilmiş bir başlangıç sunar.',
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DmlColors.ink,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İletişim',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'İletişim adresi ve çalışma saatleri kurum onayı sonrasında bu alana eklenecektir.',
                    style: TextStyle(color: DmlColors.accent, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        );
        final form = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DmlColors.mist),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laboratuvar ziyareti isteyin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Altyapıyı görmek, bir ders veya proje için tanışma ziyareti planlamak üzere kısa bilgi bırakın.',
                  style: TextStyle(color: DmlColors.slate, height: 1.4),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Ad soyad'),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Bu alan gereklidir'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Kurumsal e-posta',
                  ),
                  validator: (value) => !(value?.contains('@') ?? false)
                      ? 'Geçerli bir e-posta girin'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purpose,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Ziyaret amacı ve yaklaşık katılımcı sayısı',
                  ),
                  validator: (value) => (value?.trim().isEmpty ?? true)
                      ? 'Bu alan gereklidir'
                      : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Ziyaret talebi oluştur'),
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Prototip: Bu form henüz veri kaydetmez veya göndermez.',
                  style: TextStyle(fontSize: 11, color: DmlColors.slate),
                ),
              ],
            ),
          ),
        );
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padding, 24, padding, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: compact
                  ? Column(children: [about, const SizedBox(height: 22), form])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: about),
                        const SizedBox(width: 30),
                        Expanded(child: form),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _InfoTile(this.icon, this.title, this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DmlColors.mist,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: DmlColors.ink),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(color: DmlColors.slate, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
