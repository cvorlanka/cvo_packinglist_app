// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:packinglist_app/components/msauth_controller/msal_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userName = TextEditingController();
  String? token;

  @override
  void initState() {
    super.initState();
    signIn();
  }

  // Sign in with MS Auth
  Future<void> signIn() async {
    token = await MSALController.authenticate();
    if (token != null) {
      Navigator.of(context).pushNamed('/home');
      // final response = await http.get(
      //   Uri.parse('https://graph.microsoft.com/v1.0/me'),
      //   headers: {'Authorization': 'Bearer $token'},
      // );
      // if (response.statusCode == 200) {
      //   // print('User Info: ${response.body}');
      //   userDetails.add(jsonDecode(response.body));
      //   user = '${userDetails[0]['givenName']} ${userDetails[0]['surname']}';
      //   print(
      //       'User Name: ${userDetails[0]['givenName']} ${userDetails[0]['surname']}');
      // } else {
      //   throw Exception(
      //       'Failed to load user info. Status Code: ${response.statusCode}, Body: ${response.body}');
      // }
    } else {
      print('Failed to authenticate and obtain token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox();
  }
}

// Alert function
showAlertDialog(BuildContext context, String msg) {
  AlertDialog alert = AlertDialog(
    title: const Text(
      'Error',
      style: TextStyle(
        color: Colors.black,
        fontSize: 25,
      ),
    ),
    content: Text(
      msg,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 15,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text(
          'OK',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 15,
          ),
        ),
      ),
    ],
  );

  showDialog(
    context: context,
    builder: (context) => alert,
  );
}
