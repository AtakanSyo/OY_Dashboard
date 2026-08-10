import 'package:flutter/material.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  final AppUser currentUser;

  const SupportScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const String _supportEmail = 'general@optiyou.com.tr';

  static const List<String> _supportPhoneNumbers = [
    '+90 534 884 23 19',
    '+90 507 290 37 13',
  ];

  final _issueFormKey = GlobalKey<FormState>();

  final TextEditingController _issueTitleController = TextEditingController();
  final TextEditingController _issueDescriptionController =
      TextEditingController();

  String _selectedIssueType = 'technical';
  String _selectedPriority = 'normal';
  bool _isSendingIssue = false;

  @override
  void dispose() {
    _issueTitleController.dispose();
    _issueDescriptionController.dispose();
    super.dispose();
  }

  String _getWelcomeText() {
    if (widget.currentUser.isExpert) {
      return 'Uzman paneli, ölçüm süreçleri ve sipariş yönetimi hakkında destek alabilirsiniz.';
    }

    if (widget.currentUser.isCustomer) {
      return 'Siparişleriniz, ürünleriniz ve kullanım süreci hakkında destek alabilirsiniz.';
    }

    if (widget.currentUser.isOptiYouTeam) {
      return 'Operasyon, kullanıcı akışı ve sistem yönetimi için destek seçeneklerini kullanabilirsiniz.';
    }

    return 'Yardıma mı ihtiyacınız var? Aşağıdaki seçeneklerden birini seçebilirsiniz.';
  }

  String _issueTypeLabel(String value) {
    switch (value) {
      case 'technical':
        return 'Teknik Sorun';
      case 'measurement':
        return 'Ölçüm / Analiz Sorunu';
      case 'order':
        return 'Sipariş Süreci';
      case 'account':
        return 'Hesap / Kullanıcı Sorunu';
      case 'other':
        return 'Diğer';
      default:
        return value;
    }
  }

  String _priorityLabel(String value) {
    switch (value) {
      case 'low':
        return 'Düşük';
      case 'normal':
        return 'Normal';
      case 'high':
        return 'Yüksek';
      case 'urgent':
        return 'Acil';
      default:
        return value;
    }
  }

  Future<void> _launchUri(Uri uri) async {
    final canLaunch = await canLaunchUrl(uri);

    if (!canLaunch) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu işlem cihazda açılamadı.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _callPhoneNumber(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(' ', '');
    final uri = Uri(
      scheme: 'tel',
      path: cleaned,
    );

    await _launchUri(uri);
  }

  Future<void> _sendSupportEmail() async {
    final subject = Uri.encodeComponent('Optiyou Destek Talebi');
    final body = Uri.encodeComponent(
      [
        'Merhaba Optiyou destek ekibi,',
        '',
        'Destek almak istiyorum.',
        '',
        'Kullanıcı Bilgileri',
        'Ad Soyad: ${widget.currentUser.displayName}',
        'E-posta: ${widget.currentUser.email}',
        'Rol: ${widget.currentUser.roleName}',
        if (widget.currentUser.clinicName != null &&
            widget.currentUser.clinicName!.trim().isNotEmpty)
          'Klinik: ${widget.currentUser.clinicName}',
        '',
        'Mesaj:',
      ].join('\n'),
    );

    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=$subject&body=$body',
    );

    await _launchUri(uri);
  }

  Future<void> _submitIssueReport() async {
    if (!_issueFormKey.currentState!.validate()) return;

    setState(() {
      _isSendingIssue = true;
    });

    final subject = Uri.encodeComponent(
      'Optiyou Sorun Bildirimi - ${_issueTitleController.text.trim()}',
    );

    final body = Uri.encodeComponent(
      [
        'Sorun Bildirimi',
        '',
        'Sorun Türü: ${_issueTypeLabel(_selectedIssueType)}',
        'Öncelik: ${_priorityLabel(_selectedPriority)}',
        'Başlık: ${_issueTitleController.text.trim()}',
        '',
        'Açıklama:',
        _issueDescriptionController.text.trim(),
        '',
        'Kullanıcı Bilgileri',
        'Ad Soyad: ${widget.currentUser.displayName}',
        'E-posta: ${widget.currentUser.email}',
        'Rol: ${widget.currentUser.roleName}',
        if (widget.currentUser.clinicName != null &&
            widget.currentUser.clinicName!.trim().isNotEmpty)
          'Klinik: ${widget.currentUser.clinicName}',
      ].join('\n'),
    );

    final uri = Uri.parse(
      'mailto:$_supportEmail?subject=$subject&body=$body',
    );

    await _launchUri(uri);

    if (!mounted) return;

    setState(() {
      _isSendingIssue = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sorun bildirimi için e-posta uygulaması açıldı.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCallSupportDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Destek Sorumlusunu Ara'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aşağıdaki numaralardan destek sorumlusuna ulaşabilirsiniz.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 16),
              ..._supportPhoneNumbers.map(
                (phoneNumber) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.teal.withOpacity(0.18),
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(
                        Icons.phone,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      phoneNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Aramak için tıklayın'),
                    onTap: () => _callPhoneNumber(phoneNumber),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleText =
        '${widget.currentUser.roleName}${widget.currentUser.clinicName != null && widget.currentUser.clinicName!.trim().isNotEmpty ? ' • ${widget.currentUser.clinicName}' : ''}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destek Merkezi'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(roleText),
                const SizedBox(height: 24),
                _buildQuickContactSection(),
                const SizedBox(height: 20),
                _buildIssueReportSection(),
                const SizedBox(height: 20),
                _buildFaqSection(),
                const SizedBox(height: 24),
                Text(
                  'Destek talepleriniz en kısa sürede değerlendirilecektir.',
                  style: TextStyle(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String roleText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent,
              size: 42,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Merhaba, ${widget.currentUser.displayName}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _getWelcomeText(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            roleText,
            style: TextStyle(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactSection() {
    return _buildSectionCard(
      title: 'Hızlı Destek',
      subtitle: 'Destek ekibine telefon veya e-posta ile ulaşabilirsiniz.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 680;

          final callButton = ElevatedButton.icon(
            onPressed: _showCallSupportDialog,
            icon: const Icon(
              Icons.phone_in_talk_outlined,
              color: Colors.white,
            ),
            label: const Text(
              'Destek Sorumlusunu Ara',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          final mailButton = OutlinedButton.icon(
            onPressed: _sendSupportEmail,
            icon: const Icon(Icons.email_outlined),
            label: const Text(_supportEmail),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                callButton,
                const SizedBox(height: 10),
                mailButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: callButton),
              const SizedBox(width: 12),
              Expanded(child: mailButton),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIssueReportSection() {
    return _buildSectionCard(
      title: 'Sorun Bildir',
      subtitle:
          'Yaşadığınız problemi detaylı şekilde iletin. Form e-posta olarak hazırlanır.',
      child: Form(
        key: _issueFormKey,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 680;

                final issueTypeField = DropdownButtonFormField<String>(
                  initialValue: _selectedIssueType,
                  decoration: const InputDecoration(
                    labelText: 'Sorun Türü',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'technical',
                      child: Text('Teknik Sorun'),
                    ),
                    DropdownMenuItem(
                      value: 'measurement',
                      child: Text('Ölçüm / Analiz Sorunu'),
                    ),
                    DropdownMenuItem(
                      value: 'order',
                      child: Text('Sipariş Süreci'),
                    ),
                    DropdownMenuItem(
                      value: 'account',
                      child: Text('Hesap / Kullanıcı Sorunu'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Diğer'),
                    ),
                  ],
                  onChanged: _isSendingIssue
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedIssueType = value;
                          });
                        },
                );

                final priorityField = DropdownButtonFormField<String>(
                  initialValue: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Öncelik',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'low',
                      child: Text('Düşük'),
                    ),
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text('Normal'),
                    ),
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('Yüksek'),
                    ),
                    DropdownMenuItem(
                      value: 'urgent',
                      child: Text('Acil'),
                    ),
                  ],
                  onChanged: _isSendingIssue
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedPriority = value;
                          });
                        },
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      issueTypeField,
                      const SizedBox(height: 12),
                      priorityField,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: issueTypeField),
                    const SizedBox(width: 12),
                    Expanded(child: priorityField),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _issueTitleController,
              enabled: !_isSendingIssue,
              decoration: const InputDecoration(
                labelText: 'Konu Başlığı',
                hintText: 'Örn. Ölçüm sonucu açılmıyor',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Konu başlığı zorunludur';
                }

                if (value.trim().length < 4) {
                  return 'Konu başlığı biraz daha açıklayıcı olmalıdır';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _issueDescriptionController,
              enabled: !_isSendingIssue,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Sorun Açıklaması',
                hintText:
                    'Yaşadığınız problemi, hangi ekranda oluştuğunu ve varsa hata mesajını yazın.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Sorun açıklaması zorunludur';
                }

                if (value.trim().length < 12) {
                  return 'Lütfen sorunu biraz daha detaylandırın';
                }

                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Form gönderildiğinde e-posta uygulamanız açılır ve içerik $_supportEmail adresine hazırlanır.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isSendingIssue ? null : _submitIssueReport,
                icon: _isSendingIssue
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_outlined,
                        color: Colors.white,
                      ),
                label: const Text(
                  'Sorun Bildir',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection() {
    final faqs = _getFaqItems();

    return _buildSectionCard(
      title: 'Sıkça Sorulan Sorular',
      subtitle: 'En çok karşılaşılan konuları buradan inceleyebilirsiniz.',
      child: Column(
        children: [
          ...faqs.map(
            (faq) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFaqTile(faq),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(_FaqItem faq) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: Colors.teal,
        collapsedIconColor: Colors.black45,
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              faq.answer,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 6,
            offset: Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent_outlined,
                  color: Colors.teal,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  List<_FaqItem> _getFaqItems() {
    if (widget.currentUser.isExpert) {
      return const [
        _FaqItem(
          question: 'Yeni kullanıcı kaydı nasıl oluşturulur?',
          answer:
              'Uzman panelinde kullanıcılar bölümünden yeni kullanıcı kaydı oluşturabilirsiniz. Kayıt sırasında e-posta girilirse KVKK ve sözleşme onay bağlantısı kullanıcıya gönderilir.',
        ),
        _FaqItem(
          question: 'Ölçüm sonuçları ne zaman görüntülenebilir?',
          answer:
              'Klinik / antropometrik bilgiler, 3D scan ve plantar basınç adımları tamamlandıktan sonra analiz sonuçları görüntülenebilir.',
        ),
        _FaqItem(
          question: 'Referans iç taban fotoğrafı nasıl çekilmeli?',
          answer:
              'İç taban fotoğrafı üstten, net ve ölçek referansı görünür şekilde çekilmelidir. A4 kağıt veya 1 TL gibi ölçü referansları kullanılabilir.',
        ),
        _FaqItem(
          question: 'Tasarım formu tamamlanmadan ölçüm onaylanabilir mi?',
          answer:
              'Ölçüm onayı için önceki tüm zorunlu adımların tamamlanması gerekir. Eksik adım varsa sistem onaylamaya izin vermez.',
        ),
      ];
    }

    if (widget.currentUser.isCustomer) {
      return const [
        _FaqItem(
          question: 'Ölçüm sonuçlarımı nereden görebilirim?',
          answer:
              'Hesabınıza giriş yaptıktan sonra analiz sonuçları bölümünden size ait ölçüm sonuçlarını görüntüleyebilirsiniz.',
        ),
        _FaqItem(
          question: 'Sipariş durumumu nasıl takip ederim?',
          answer:
              'Siparişler bölümünden üretim, paketleme ve teslimat durumunu takip edebilirsiniz.',
        ),
        _FaqItem(
          question: 'Ürünümü kullanırken nelere dikkat etmeliyim?',
          answer:
              'İlk kullanımda ürünü kademeli şekilde kullanmanız ve rahatsızlık hissederseniz destek ekibiyle iletişime geçmeniz önerilir.',
        ),
        _FaqItem(
          question: 'Destek ekibine nasıl ulaşırım?',
          answer:
              'Bu sayfadaki telefon veya e-posta seçeneklerini kullanarak Optiyou destek ekibine ulaşabilirsiniz.',
        ),
      ];
    }

    if (widget.currentUser.isOptiYouTeam) {
      return const [
        _FaqItem(
          question: 'Operasyon sürecindeki eksik bilgiler nereden kontrol edilir?',
          answer:
              'Operasyon ve sipariş detay ekranlarında klinik, kullanıcı, ölçüm ve üretim adımlarına ait bilgiler kontrol edilebilir.',
        ),
        _FaqItem(
          question: 'Klinik veya uzman kaynaklı sorunlar nasıl bildirilir?',
          answer:
              'Sorun bildir formu üzerinden ilgili rol, ekran ve hata detaylarını yazarak destek kaydı oluşturabilirsiniz.',
        ),
        _FaqItem(
          question: 'QR veya sonuç erişim bağlantısı çalışmazsa ne yapılmalı?',
          answer:
              'Önce oturumun onaylandığını ve kullanıcı invite bağlantısının geçerli olduğunu kontrol edin. Sorun devam ederse destek ekibine bildirin.',
        ),
        _FaqItem(
          question: 'Sistemsel hata bildiriminde hangi bilgiler gerekli?',
          answer:
              'Hatanın oluştuğu ekran, kullanıcı rolü, işlem adımı, hata mesajı ve mümkünse ekran görüntüsü paylaşılmalıdır.',
        ),
      ];
    }

    return const [
      _FaqItem(
        question: 'Destek ekibine nasıl ulaşırım?',
        answer:
            'Telefon veya e-posta seçeneklerini kullanarak Optiyou destek ekibine ulaşabilirsiniz.',
      ),
      _FaqItem(
        question: 'Sorun bildirimi nasıl yapılır?',
        answer:
            'Sorun bildir formunu doldurarak destek ekibine detaylı açıklama gönderebilirsiniz.',
      ),
    ];
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });
}