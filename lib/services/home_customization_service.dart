import 'package:flutter/foundation.dart';
import 'package:musify/services/data_manager.dart';

class KryptHomeCustomizationService extends ChangeNotifier {
  KryptHomeCustomizationService._() {
    _ready = _load();
  }

  static final instance = KryptHomeCustomizationService._();
  late final Future<void> _ready;

  bool showSmartDj = true;
  bool showSuggested = true;
  bool showLiked = true;
  bool showRecap = true;
  bool showRecommendations = true;
  bool showPluginBadges = true;

  Future<void> get ready => _ready;

  Future<void> _load() async {
    final data = await getData('settings', 'homeCustomization');
    if (data is Map) {
      showSmartDj = data['showSmartDj'] != false;
      showSuggested = data['showSuggested'] != false;
      showLiked = data['showLiked'] != false;
      showRecap = data['showRecap'] != false;
      showRecommendations = data['showRecommendations'] != false;
      showPluginBadges = data['showPluginBadges'] != false;
      notifyListeners();
    }
  }

  Future<void> setValue(String key, bool value) async {
    await _ready;
    final previousValue = _valueFor(key);
    if (previousValue == null) throw ArgumentError.value(key, 'key');

    _assignValue(key, value);
    notifyListeners();
    try {
      await _persist();
    } catch (_) {
      _assignValue(key, previousValue);
      notifyListeners();
      rethrow;
    }
  }

  bool? _valueFor(String key) => switch (key) {
    'showSmartDj' => showSmartDj,
    'showSuggested' => showSuggested,
    'showLiked' => showLiked,
    'showRecap' => showRecap,
    'showRecommendations' => showRecommendations,
    'showPluginBadges' => showPluginBadges,
    _ => null,
  };

  void _assignValue(String key, bool value) {
    switch (key) {
      case 'showSmartDj':
        showSmartDj = value;
      case 'showSuggested':
        showSuggested = value;
      case 'showLiked':
        showLiked = value;
      case 'showRecap':
        showRecap = value;
      case 'showRecommendations':
        showRecommendations = value;
      case 'showPluginBadges':
        showPluginBadges = value;
      default:
        throw ArgumentError.value(key, 'key');
    }
  }

  Future<void> _persist() =>
      addOrUpdateData<Map<String, dynamic>>('settings', 'homeCustomization', {
        'showSmartDj': showSmartDj,
        'showSuggested': showSuggested,
        'showLiked': showLiked,
        'showRecap': showRecap,
        'showRecommendations': showRecommendations,
        'showPluginBadges': showPluginBadges,
      });
}
