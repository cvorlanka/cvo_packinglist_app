import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aad_oauth/aad_oauth.dart';
import 'package:aad_oauth/model/config.dart';
import 'package:flutter/material.dart';

class MSALController {
  static String? token;
  static GlobalKey<NavigatorState> mainNavigatorKey = GlobalKey();

  static AadOAuth get aOAuth {
    Config config = Config(
      tenant: "c4fc4586-479f-44ec-b4a8-2d38d22fe08f",
      clientId: "f318b400-8a3c-4f8b-a6d4-42cbba3a0362",
      scope: "openid profile offline_access User.Read",
      navigatorKey: mainNavigatorKey,
      loader: Center(child: CircularProgressIndicator()),
      webUseRedirect: true,
    );

    return AadOAuth(config);
  }

  static Future<String?> authenticate() async {
    await aOAuth.login(refreshIfAvailable: true);

    token = await getToken();
    return token;
  }

  static Future<String?> getToken() async {
    token = await aOAuth.getAccessToken();
    return token;
  }

  static Future<void> logOut() async {
    await aOAuth.logout(showWebPopup: true);
  }

  static Future<String?> getUserName() async {
    String user;
    final response = await http.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      // print('User Info: ${response.body}');
      List<dynamic> userDetails = [jsonDecode(response.body)];
      user = '${userDetails[0]['givenName']} ${userDetails[0]['surname']}';
      print('USER: $user');
      return user;
    } else {
      throw Exception(
          'Failed to load user info. Status Code: ${response.statusCode}, Body: ${response.body}');
    }
  }
}
