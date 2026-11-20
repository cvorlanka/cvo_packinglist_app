import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:flutter/material.dart';

class AadOAuthController {
  static String? token;
  static GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey();

  static final Config config = Config(
    tenant: "c4fc4586-479f-44ec-b4a8-2d38d22fe08f",
    clientId: "f318b400-8a3c-4f8b-a6d4-42cbba3a0362",
    scope: "openid profile offline_access",
    navigatorKey: mainNavigatorKey,
    loader: Center(child: CircularProgressIndicator()),
    webUseRedirect: true,
  );

  static Future<String?> tryLogin() async {
    final AadOAuth oauth = AadOAuth(config);

    await oauth.login();
    token = await oauth.getAccessToken();
    if (token != null) {
      print('Token: $token');
      return token;
    } else {
      return null;
    }
  }

  // static Future<String?> getToken() async {
  //   token = await oauth.getAccessToken();
  //   return token;
  // }

  static Future<void> logOut() async {
    final AadOAuth oauth = AadOAuth(config);
    await oauth.logout();
    print('logged out');
  }
}
