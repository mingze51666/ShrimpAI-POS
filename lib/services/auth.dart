import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart';
import 'package:shrimpai_pos/helpers/logger.dart';

class Auth {
  static Auth instance = Auth();

  final GoogleSignIn _service;

  Auth([GoogleSignIn? service])
    : _service = service ?? GoogleSignIn(scopes: []);

  /// 登录状态流（基于 GoogleSignIn，2026-08-01 替代 FirebaseAuth）
  Stream<GoogleSignInAccount?> authStateChanges() => _service.onCurrentUserChanged;

  Future<Client?> getAuthenticatedClient({
    List<String> scopes = const [],
    @visibleForTesting GoogleSignInAuthentication? debugAuthentication,
  }) async {
    await _service.signInSilently();

    final newScopes = scopes.toSet().difference(_service.scopes.toSet());
    if (newScopes.isNotEmpty) {
      Log.ger('login_scope', {'scopes': newScopes.join(',')});
      if (await _service.requestScopes(newScopes.toList())) {
        Log.out('scopes success', 'login_scope');
        _service.scopes.addAll(newScopes);
      }
    }

    return _service.authenticatedClient(
      // ignore: invalid_use_of_visible_for_testing_member
      debugAuthentication: debugAuthentication,
    );
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  Future<bool> signIn() async {
    Log.ger('login', {'loginMethod': 'google'});
    // Trigger the authentication flow
    final GoogleSignInAccount? user = await _service.signIn();
    return user != null;
  }
}
