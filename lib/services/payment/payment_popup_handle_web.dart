import 'dart:html' as html;

class PaymentPopupHandle {
  final html.WindowBase _window;

  PaymentPopupHandle(this._window);

  void navigate(String url) {
    _window.location.href = url;
  }

  void close() {
    _window.close();
  }
}

PaymentPopupHandle? openPaymentPopup() {
  final window = html.window.open('about:blank', '_blank');
  if (window == null) return null;
  return PaymentPopupHandle(window);
}
