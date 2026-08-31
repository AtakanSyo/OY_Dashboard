import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oy_site/screens/public/welcome_qr_screen.dart';
import 'package:oy_site/services/navigation/welcome_qr_link_parser.dart';

class WelcomeQrLinkLauncher extends StatefulWidget {
  final String initialLink;
  final dynamic pressureRepository;

  const WelcomeQrLinkLauncher({
    super.key,
    required this.initialLink,
    this.pressureRepository,
  });

  @override
  State<WelcomeQrLinkLauncher> createState() => _WelcomeQrLinkLauncherState();
}

class _WelcomeQrLinkLauncherState extends State<WelcomeQrLinkLauncher> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLink);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clipboardData?.text?.trim();

    if (!mounted) return;

    if (text == null || text.isEmpty) {
      setState(() => _errorText = 'Panoda bir QR davet bağlantısı bulunamadı.');
      return;
    }

    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.collapsed(offset: text.length);
      _errorText = null;
    });
  }

  void _openInApp() {
    final link = WelcomeQrLinkParser.parse(_controller.text);

    if (link == null) {
      setState(() {
        _errorText =
            'Geçerli bir Optiyou QR davet bağlantısı veya davet tokenı girin.';
      });
      return;
    }

    final navigator = Navigator.of(context);
    final pressureRepository = widget.pressureRepository;
    navigator.pop();

    Future<void>.delayed(Duration.zero, () {
      navigator.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/welcome'),
          builder: (_) => WelcomeQrScreen(
            pressureRepository: pressureRepository,
            initialInviteToken: link.inviteToken,
            initialSource: link.source,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.open_in_new_outlined, size: 20, color: Colors.teal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'QR davetini uygulamada test et',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bağlantıyı yapıştırın veya yukarıdaki QR bağlantısını doğrudan açın.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'QR davet bağlantısı',
              errorText: _errorText,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: 'Panodan yapıştır',
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_outlined),
              ),
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: (_) => _openInApp(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openInApp,
              icon: const Icon(Icons.rocket_launch_outlined, size: 18),
              label: const Text('Uygulamada Aç'),
            ),
          ),
        ],
      ),
    );
  }
}
