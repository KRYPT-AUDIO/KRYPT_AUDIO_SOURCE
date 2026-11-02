import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musify/services/data_manager.dart';

class KryptHomeCustomizationService extends ChangeNotifier {
  KryptHomeCustomizationService._() {
    _load();
  }

  static final instance = KryptHomeCustomizationService._();

  bool showSmartDj = true;
  bool showSuggested = true;
  bool showLiked = true;
  bool showRecap = true;
  bool showRecommendations = true;
  bool showPluginBadges = true;

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
    }
    notifyListeners();
    unawaited(
      addOrUpdateData<Map<String, dynamic>>('settings', 'homeCustomization', {
        'showSmartDj': showSmartDj,
        'showSuggested': showSuggested,
        'showLiked': showLiked,
        'showRecap': showRecap,
        'showRecommendations': showRecommendations,
        'showPluginBadges': showPluginBadges,
      }),
    );
  }
}
