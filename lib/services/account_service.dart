import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

class KryptAccountService extends ChangeNotifier {
  KryptAccountService._();
  static final instance = KryptAccountService._();

  final GoogleSignIn _google = GoogleSignIn(scopes: const ['email', 'profile']);
  GoogleSignInAccount? _account;
  bool _busy = false;
  String? _error;

  GoogleSignInAccount? get account => _account;
  bool get isBusy => _busy;
  bool get isSignedIn => _account != null;
  String? get error => _error;

  Future<void> restore() async {
    try {
      _account = await _google.signInSilently();
    } catch (_) {
      _account = null;
    }
    notifyListeners();
  }

  Future<bool> signIn() async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _account = await _google.signIn();
      if (_account != null) {
        await Hive.box('user').put('googleAccountEmail', _account!.email);
        await Hive.box('user').put('googleAccountName', _account!.displayName);
        await Hive.box('user').put('googleAccountPhoto', _account!.photoUrl);
      }
      return _account != null;
    } catch (error) {
      _error = error.toString();
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _google.signOut();
    _account = null;
    await Hive.box('user').delete('googleAccountEmail');
    await Hive.box('user').delete('googleAccountName');
    await Hive.box('user').delete('googleAccountPhoto');
    notifyListeners();
  }
}
