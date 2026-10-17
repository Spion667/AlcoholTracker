import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/body_profile.dart';

const bodyProfileStorageKey = 'alcohol_tracker_body_profile_v1';

/// Lokales Koerperprofil fuer den Promille-Radar.
///
/// Privacy by Design: wird ausschliesslich in `SharedPreferences` auf dem Geraet
/// gespeichert und nie an ein Backend uebertragen.
class BodyProfileController extends ChangeNotifier {
  BodyProfileController({this._prefs});

  SharedPreferences? _prefs;
  BodyProfile? _profile;

  BodyProfile? get profile => _profile;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    try {
      final raw = (await _store).getString(bodyProfileStorageKey);
      if (raw == null) {
        _profile = null;
      } else {
        _profile = BodyProfile.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Körperprofils: $e');
      _profile = null;
    }
    notifyListeners();
  }

  Future<BodyProfile> save({
    required String gender,
    required num age,
    required num heightCm,
    required num weightKg,
    required bool shareInParty,
  }) async {
    final profile = BodyProfile.sanitized(
      gender: gender,
      age: age,
      heightCm: heightCm,
      weightKg: weightKg,
      shareInParty: shareInParty,
    );
    await (await _store).setString(
      bodyProfileStorageKey,
      jsonEncode(profile.toJson()),
    );
    _profile = profile;
    notifyListeners();
    return profile;
  }

  Future<void> clear() async {
    await (await _store).remove(bodyProfileStorageKey);
    _profile = null;
    notifyListeners();
  }
}
