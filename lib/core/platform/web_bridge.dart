// Small set of browser-only capabilities the PWA needs (sound/vibration when
// the rest timer ends, tinting the browser/status bar to the active theme).
// On Android/iOS every call is a no-op — the native build already gets a
// system notification + haptic for the rest timer, and its status bar is
// driven by the app theme itself.
export 'web_bridge_stub.dart' if (dart.library.js_interop) 'web_bridge_web.dart';
