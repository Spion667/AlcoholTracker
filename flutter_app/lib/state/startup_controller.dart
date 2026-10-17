import 'package:flutter/foundation.dart';

/// Merkt sich, ob die animierte Start-Animation bereits durchgelaufen ist.
///
/// Der Router wartet auf [splashDone] **und** das geladene Profil, bevor er
/// zu Setup bzw. Home weiterleitet.
class StartupController extends ChangeNotifier {
  bool _splashDone = false;

  bool get splashDone => _splashDone;

  void markSplashDone() {
    if (_splashDone) return;
    _splashDone = true;
    notifyListeners();
  }
}
