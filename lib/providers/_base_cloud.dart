// lib/providers/_base_cloud.dart
import 'package:flutter/foundation.dart';

mixin CloudErrorMixin on ChangeNotifier {
  String? _lastError;
  String? get lastError => _lastError;

  void setError(Object e) {
    final msg = e.toString();
    if (_lastError == msg) return; // gereksiz notify engelle
    _lastError = msg;
    debugPrint('[CloudError] $msg');
    notifyListeners();
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }
}
