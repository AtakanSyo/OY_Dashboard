class WelcomeQrLinkData {
  final String inviteToken;
  final String source;

  const WelcomeQrLinkData({required this.inviteToken, required this.source});
}

class WelcomeQrLinkParser {
  const WelcomeQrLinkParser._();

  static WelcomeQrLinkData? parse(String value) {
    final input = value.trim();
    if (input.isEmpty) return null;

    if (_looksLikeInviteToken(input)) {
      return WelcomeQrLinkData(inviteToken: input, source: 'in_app');
    }

    final uri = Uri.tryParse(input);
    if (uri == null) return null;

    final directToken = _firstNonEmpty([
      uri.queryParameters['invite'],
      uri.queryParameters['t'],
      uri.queryParameters['token'],
    ]);

    if (directToken != null && _looksLikeInviteToken(directToken)) {
      return WelcomeQrLinkData(
        inviteToken: directToken,
        source: _normalizedSource(uri.queryParameters['source']),
      );
    }

    final fragment = uri.fragment.trim();
    if (fragment.isEmpty) return null;

    final normalizedFragment = fragment.startsWith('/')
        ? fragment
        : '/$fragment';
    final fragmentUri = Uri.tryParse(normalizedFragment);
    if (fragmentUri == null) return null;

    final fragmentToken = _firstNonEmpty([
      fragmentUri.queryParameters['invite'],
      fragmentUri.queryParameters['t'],
      fragmentUri.queryParameters['token'],
    ]);

    if (fragmentToken == null || !_looksLikeInviteToken(fragmentToken)) {
      return null;
    }

    return WelcomeQrLinkData(
      inviteToken: fragmentToken,
      source: _normalizedSource(fragmentUri.queryParameters['source']),
    );
  }

  static bool _looksLikeInviteToken(String value) {
    return value.startsWith('inv_') && value.length > 8 && !value.contains(' ');
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  static String _normalizedSource(String? value) {
    final source = value?.trim();
    return source == null || source.isEmpty ? 'in_app' : source;
  }
}
