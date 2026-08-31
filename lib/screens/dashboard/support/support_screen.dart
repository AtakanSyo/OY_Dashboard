import 'package:flutter/material.dart';
import 'package:oy_site/l10n/app_localizations.dart';
import 'package:oy_site/models/app_user.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  final AppUser currentUser;

  const SupportScreen({super.key, required this.currentUser});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  static const _supportEmail = 'general@optiyou.com.tr';
  static const _supportPhoneNumbers = [
    '+90 534 884 23 19',
    '+90 507 290 37 13',
  ];

  final _issueFormKey = GlobalKey<FormState>();
  final _issueTitleController = TextEditingController();
  final _issueDescriptionController = TextEditingController();

  String _selectedIssueType = 'technical';
  String _selectedPriority = 'normal';
  bool _isSendingIssue = false;

  @override
  void dispose() {
    _issueTitleController.dispose();
    _issueDescriptionController.dispose();
    super.dispose();
  }

  String _welcomeText(AppLocalizations l10n) {
    if (widget.currentUser.isExpert) return l10n.expertSupportIntro;
    if (widget.currentUser.isCustomer) return l10n.customerSupportIntro;
    if (widget.currentUser.isOptiYouTeam) return l10n.teamSupportIntro;
    return l10n.genericSupportIntro;
  }

  String _roleText(AppLocalizations l10n) {
    final role = widget.currentUser.isCustomer
        ? l10n.customerRole
        : widget.currentUser.isExpert
        ? l10n.expertRole
        : widget.currentUser.isOptiYouTeam
        ? l10n.optiyouTeamRole
        : widget.currentUser.roleName;
    final clinic = widget.currentUser.clinicName?.trim() ?? '';
    return clinic.isEmpty ? role : '$role • $clinic';
  }

  String _issueTypeLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'technical':
        return l10n.technicalIssue;
      case 'measurement':
        return l10n.measurementIssue;
      case 'order':
        return l10n.orderIssue;
      case 'account':
        return l10n.accountIssue;
      default:
        return l10n.otherIssue;
    }
  }

  String _priorityLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case 'low':
        return l10n.lowPriority;
      case 'high':
        return l10n.highPriority;
      case 'urgent':
        return l10n.urgentPriority;
      default:
        return l10n.normal;
    }
  }

  Future<bool> _launchUri(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {
      // The same user-facing error is shown for unsupported handlers and errors.
    }
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).actionCouldNotOpen),
        backgroundColor: Colors.red,
      ),
    );
    return false;
  }

  Future<void> _callPhoneNumber(String phoneNumber) {
    return _launchUri(
      Uri(scheme: 'tel', path: phoneNumber.replaceAll(' ', '')),
    ).then((_) {});
  }

  Uri _emailUri({required String subject, required String body}) {
    return Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': subject, 'body': body},
    );
  }

  List<String> _userInformation(AppLocalizations l10n) {
    return [
      l10n.personalInformation,
      '${l10n.fullName}: ${widget.currentUser.displayName}',
      '${l10n.email}: ${widget.currentUser.email}',
      '${l10n.role}: ${_roleText(l10n)}',
      if ((widget.currentUser.clinicName ?? '').trim().isNotEmpty)
        '${l10n.clinicLabel}: ${widget.currentUser.clinicName}',
    ];
  }

  Future<void> _sendSupportEmail() async {
    final l10n = AppLocalizations.of(context);
    final body = [
      l10n.helloUser(widget.currentUser.displayName),
      '',
      l10n.genericSupportIntro,
      '',
      ..._userInformation(l10n),
      '',
      '${l10n.messageLabel}:',
    ].join('\n');
    await _launchUri(
      _emailUri(subject: 'OptiYou - ${l10n.supportCenter}', body: body),
    );
  }

  Future<void> _submitIssueReport() async {
    if (!_issueFormKey.currentState!.validate()) return;
    setState(() => _isSendingIssue = true);
    final l10n = AppLocalizations.of(context);
    final body = [
      l10n.reportIssue,
      '',
      '${l10n.issueType}: ${_issueTypeLabel(_selectedIssueType, l10n)}',
      '${l10n.priority}: ${_priorityLabel(_selectedPriority, l10n)}',
      '${l10n.subjectTitle}: ${_issueTitleController.text.trim()}',
      '',
      '${l10n.issueDescription}:',
      _issueDescriptionController.text.trim(),
      '',
      ..._userInformation(l10n),
    ].join('\n');

    final launched = await _launchUri(
      _emailUri(
        subject:
            'OptiYou - ${l10n.reportIssue}: '
            '${_issueTitleController.text.trim()}',
        body: body,
      ),
    );
    if (!mounted) return;
    setState(() => _isSendingIssue = false);
    if (launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.emailAppOpened),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showCallSupportDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.callSupport),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.callSupportDescription),
              const SizedBox(height: 16),
              ..._supportPhoneNumbers.map(
                (number) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.teal.withValues(alpha: 0.18),
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.phone, color: Colors.white),
                    ),
                    title: Text(
                      number,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(l10n.tapToCall),
                    onTap: () => _callPhoneNumber(number),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pagePadding = constraints.maxWidth < 650 ? 16.0 : 24.0;
          return SingleChildScrollView(
            padding: EdgeInsets.all(pagePadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.supportCenter,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildHeader(l10n),
                    const SizedBox(height: 20),
                    _buildQuickContactSection(l10n),
                    const SizedBox(height: 20),
                    _buildIssueReportSection(l10n),
                    const SizedBox(height: 20),
                    _buildFaqSection(l10n),
                    const SizedBox(height: 22),
                    Text(
                      l10n.supportClosingNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return _SupportCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.teal.withValues(alpha: 0.10),
            child: const Icon(
              Icons.support_agent,
              size: 40,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.helloUser(widget.currentUser.displayName),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _welcomeText(l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 10),
          Text(
            _roleText(l10n),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactSection(AppLocalizations l10n) {
    return _SectionCard(
      title: l10n.quickSupport,
      subtitle: l10n.quickSupportSubtitle,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final callButton = ElevatedButton.icon(
            onPressed: _showCallSupportDialog,
            icon: const Icon(Icons.phone_in_talk_outlined),
            label: Text(l10n.callSupport),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
          final emailButton = OutlinedButton.icon(
            onPressed: _sendSupportEmail,
            icon: const Icon(Icons.email_outlined),
            label: const Text(_supportEmail),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [callButton, const SizedBox(height: 10), emailButton],
            );
          }
          return Row(
            children: [
              Expanded(child: callButton),
              const SizedBox(width: 12),
              Expanded(child: emailButton),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIssueReportSection(AppLocalizations l10n) {
    final issueTypes = [
      'technical',
      'measurement',
      'order',
      'account',
      'other',
    ];
    final priorities = ['low', 'normal', 'high', 'urgent'];
    return _SectionCard(
      title: l10n.reportIssue,
      subtitle: l10n.issueReportSubtitle,
      child: Form(
        key: _issueFormKey,
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final typeField = DropdownButtonFormField<String>(
                  initialValue: _selectedIssueType,
                  decoration: InputDecoration(
                    labelText: l10n.issueType,
                    border: const OutlineInputBorder(),
                  ),
                  items: issueTypes
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_issueTypeLabel(value, l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: _isSendingIssue
                      ? null
                      : (value) => setState(
                          () => _selectedIssueType = value ?? 'technical',
                        ),
                );
                final priorityField = DropdownButtonFormField<String>(
                  initialValue: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: l10n.priority,
                    border: const OutlineInputBorder(),
                  ),
                  items: priorities
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_priorityLabel(value, l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: _isSendingIssue
                      ? null
                      : (value) => setState(
                          () => _selectedPriority = value ?? 'normal',
                        ),
                );
                if (constraints.maxWidth < 620) {
                  return Column(
                    children: [
                      typeField,
                      const SizedBox(height: 12),
                      priorityField,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: typeField),
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
              decoration: InputDecoration(
                labelText: l10n.subjectTitle,
                hintText: l10n.subjectTitleHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.subjectRequired;
                }
                if (value.trim().length < 4) return l10n.subjectTooShort;
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _issueDescriptionController,
              enabled: !_isSendingIssue,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: l10n.issueDescription,
                hintText: l10n.issueDescriptionHint,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.descriptionRequired;
                }
                if (value.trim().length < 12) {
                  return l10n.descriptionTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.supportFormEmailNotice(_supportEmail),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    : const Icon(Icons.send_outlined),
                label: Text(l10n.sendIssue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(AppLocalizations l10n) {
    return _SectionCard(
      title: l10n.frequentlyAskedQuestions,
      subtitle: l10n.faqSubtitle,
      child: Column(
        children: _faqItems(l10n)
            .map(
              (faq) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.teal,
                    title: Text(
                      faq.question,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<_FaqItem> _faqItems(AppLocalizations l10n) {
    if (widget.currentUser.isExpert) {
      return [
        _FaqItem(l10n.faqExpertPatientQuestion, l10n.faqExpertPatientAnswer),
        _FaqItem(l10n.faqExpertResultsQuestion, l10n.faqExpertResultsAnswer),
        _FaqItem(l10n.faqExpertPhotoQuestion, l10n.faqExpertPhotoAnswer),
        _FaqItem(l10n.faqExpertApprovalQuestion, l10n.faqExpertApprovalAnswer),
      ];
    }
    if (widget.currentUser.isOptiYouTeam) {
      return [
        _FaqItem(l10n.faqTeamMissingQuestion, l10n.faqTeamMissingAnswer),
        _FaqItem(l10n.faqTeamReportQuestion, l10n.faqTeamReportAnswer),
        _FaqItem(l10n.faqTeamQrQuestion, l10n.faqTeamQrAnswer),
        _FaqItem(l10n.faqTeamSystemQuestion, l10n.faqTeamSystemAnswer),
      ];
    }
    return [
      _FaqItem(l10n.faqResultsQuestion, l10n.faqResultsAnswer),
      _FaqItem(l10n.faqOrderQuestion, l10n.faqOrderAnswer),
      _FaqItem(l10n.faqUsageQuestion, l10n.faqUsageAnswer),
      _FaqItem(l10n.faqContactQuestion, l10n.faqContactAnswer),
    ];
  }
}

class _SupportCard extends StatelessWidget {
  final Widget child;

  const _SupportCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _SupportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}
