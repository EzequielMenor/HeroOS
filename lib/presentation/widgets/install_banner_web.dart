import 'package:web/web.dart' as web;

bool getStandaloneMode() =>
    web.window.matchMedia('(display-mode: standalone)').matches;

String getUserAgent() => web.window.navigator.userAgent.toLowerCase();
