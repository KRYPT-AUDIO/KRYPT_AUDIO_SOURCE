import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musify/services/data_manager.dart';

class KryptProfileCustomizationService extends ChangeNotifier {
  KryptProfileCustomizationService._() {
    _load();
  }

  static final instance = KryptProfileCustomizationService._();

  String _displayName = '';
  String _bio = '';
  String? _avatar;
  String _accent = 'electric-violet';

  String get displayName => _displayName;
  String get bio => _bio;
  String? get avatar => _avatar;
  String get accent => _accent;

  Future<void> _load() async {
    final user = await getData('user', 'kryptProfile');
    if (user is Map) {
      _displayName = user['displayName']?.toString() ?? '';
      _bio = user['bio']?.toString() ?? '';
      _avatar = user['avatar']?.toString();
      _accent = user['accent']?.toString() ?? 'electric-violet';
      notifyListeners();
    }
  }

  Future<void> save({
    required String displayName,
    required String bio,
    required String? avatar,
    required String accent,
  }) async {
    _displayName = displayName.trim();
    _bio = bio.trim();
    _avatar = avatar;
    _accent = accent;
    notifyListeners();
    unawaited(
      addOrUpdateData<Map<String, dynamic>>('user', 'kryptProfile', {
        'displayName': _displayName,
        'bio': _bio,
        'avatar': _avatar,
        'accent': _accent,
      }),
    );
  }
}
