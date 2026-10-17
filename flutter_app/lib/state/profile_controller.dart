import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile.dart';
import '../services/api.dart';

const profileIdKey = 'alcohol_tracker_profile_id_v2';
const seenWrappedKey = 'alcohol_tracker_seen_wrapped_v2';

/// Lokales Profil des Nutzers (ohne Passwort, nur Geraete-Identitaet).
class ProfileController extends ChangeNotifier {
  ProfileController(this._api);

  final Api _api;

  SharedPreferences? _prefs;
  Profile? _profile;
  bool _loading = true;
  String? _error;
  bool _hasStoredId = false;

  Profile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  /// `true`, wenn ein gespeichertes Profil existiert, aber nicht geladen werden
  /// konnte (z. B. offline). Dann darf KEIN neues Profil angelegt werden.
  bool get needsRetry => _profile == null && _hasStoredId && _error != null;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final prefs = await _store;
      final storedId = prefs.getString(profileIdKey);
      _hasStoredId = storedId != null;
      if (storedId != null) {
        final loaded = await _api.getProfile(storedId);
        if (loaded != null) {
          _profile = loaded;
        } else {
          await prefs.remove(profileIdKey);
          _hasStoredId = false;
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden des Profils: $e');
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<Profile> saveProfile({
    required String name,
    required String emoji,
    required String color,
  }) async {
    final created = await _api.createProfile(
      name: name,
      emoji: emoji,
      color: color,
    );
    await (await _store).setString(profileIdKey, created.id);
    _hasStoredId = true;
    _profile = created;
    _error = null;
    notifyListeners();
    return created;
  }

  Future<Profile?> updateProfile({
    required String name,
    required String emoji,
    required String color,
  }) async {
    final current = _profile;
    if (current == null) return null;
    final updated = await _api.updateProfile(current.id, {
      'name': name,
      'emoji': emoji,
      'color': color,
    });
    _profile = updated;
    notifyListeners();
    return updated;
  }

  Future<bool> hasSeenWrapped(String partyId) async {
    final seen = (await _store).getStringList(seenWrappedKey) ?? const [];
    return seen.contains(partyId);
  }

  Future<void> markWrappedSeen(String partyId) async {
    final prefs = await _store;
    final seen = [...(prefs.getStringList(seenWrappedKey) ?? const <String>[])];
    if (!seen.contains(partyId)) {
      seen.add(partyId);
      await prefs.setStringList(seenWrappedKey, seen);
    }
  }
}
