import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui;

void injectGoogleMapsScript(String apiKey) {
  final String scriptId = "google-maps-script";
  if (web.document.getElementById(scriptId) == null) {
    final web.HTMLScriptElement script = web.HTMLScriptElement()
      ..id = scriptId
      ..src = "https://maps.googleapis.com/maps/api/js?key=$apiKey"
      ..async = true
      ..defer = true;
    web.document.head?.appendChild(script);
  }
}

void registerGoogleMapsView(String apiKey) {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
    'google-maps-embed',
    (int viewId) => web.HTMLIFrameElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..src =
          "https://www.google.com/maps/embed/v1/search?key=$apiKey&q=evacuation+centers+in+Iloilo+City&zoom=14"
      ..style.border = 'none',
  );
}
