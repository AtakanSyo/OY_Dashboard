#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  RegisterKioskWindowChannel();

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  ExitKioskFullscreen();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::RegisterKioskWindowChannel() {
  kiosk_window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "oy_site/kiosk_window",
          &flutter::StandardMethodCodec::GetInstance());

  kiosk_window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "enterFullscreen") {
          EnterKioskFullscreen();
          result->Success();
          return;
        }

        if (call.method_name() == "exitFullscreen") {
          ExitKioskFullscreen();
          result->Success();
          return;
        }

        result->NotImplemented();
      });
}

void FlutterWindow::EnterKioskFullscreen() {
  if (kiosk_fullscreen_) {
    return;
  }

  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }

  previous_window_placement_.length = sizeof(WINDOWPLACEMENT);
  if (!GetWindowPlacement(hwnd, &previous_window_placement_)) {
    return;
  }

  previous_window_style_ = GetWindowLongPtr(hwnd, GWL_STYLE);
  previous_extended_window_style_ = GetWindowLongPtr(hwnd, GWL_EXSTYLE);

  HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  MONITORINFO monitor_info = {};
  monitor_info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfo(monitor, &monitor_info)) {
    return;
  }

  LONG_PTR fullscreen_style =
      (previous_window_style_ &
       ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZEBOX |
         WS_SYSMENU)) |
      WS_POPUP;
  LONG_PTR fullscreen_extended_style =
      previous_extended_window_style_ &
      ~(WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE |
        WS_EX_STATICEDGE);

  SetWindowLongPtr(hwnd, GWL_STYLE, fullscreen_style);
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, fullscreen_extended_style);

  const RECT monitor_rect = monitor_info.rcMonitor;
  SetWindowPos(hwnd, HWND_TOPMOST, monitor_rect.left, monitor_rect.top,
               monitor_rect.right - monitor_rect.left,
               monitor_rect.bottom - monitor_rect.top,
               SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  kiosk_fullscreen_ = true;
}

void FlutterWindow::ExitKioskFullscreen() {
  if (!kiosk_fullscreen_) {
    return;
  }

  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    kiosk_fullscreen_ = false;
    return;
  }

  SetWindowLongPtr(hwnd, GWL_STYLE, previous_window_style_);
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, previous_extended_window_style_);
  SetWindowPlacement(hwnd, &previous_window_placement_);
  SetWindowPos(hwnd, HWND_NOTOPMOST, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOOWNERZORDER |
                   SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  kiosk_fullscreen_ = false;
}
