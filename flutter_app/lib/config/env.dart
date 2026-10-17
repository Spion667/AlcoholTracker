/// Build-Time-Konfiguration (per `--dart-define` bzw. `--dart-define-from-file`).
///
/// Entspricht den `VITE_*`-Variablen der Web-App. Es wird ausschliesslich der
/// **Publishable Key** (`sb_publishable_...`) verwendet, niemals der Secret Key.
class Env {
  const Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  /// Optional: URL der gehosteten Web-App (z. B. `https://alcoholtracker.vercel.app`).
  /// Wird nur benoetigt, um beim Teilen einen klickbaren Party-Link mitzusenden.
  static const webBaseUrl = String.fromEnvironment('WEB_BASE_URL');

  /// Startet die App mit einem In-Memory-Backend (kein Netzwerk, Beispieldaten).
  static const demoMode = bool.fromEnvironment('DEMO_MODE');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  /// Teilbarer Link auf eine Party der Web-App, falls `WEB_BASE_URL` gesetzt ist.
  static Uri? partyLink(String partyId, {bool wrapped = false}) {
    if (webBaseUrl.isEmpty) return null;
    final base = webBaseUrl.endsWith('/')
        ? webBaseUrl.substring(0, webBaseUrl.length - 1)
        : webBaseUrl;
    return Uri.tryParse('$base/p/$partyId${wrapped ? '/wrapped' : ''}');
  }
}
