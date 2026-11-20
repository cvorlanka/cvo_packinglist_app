import 'package:flutter/material.dart';
import 'package:packinglist_app/components/msauth_controller/msal_controller.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    attemptLogin();
  }

  Future<void> attemptLogin() async {
    var token = await MSALController.authenticate();
    if (token != null) {
      Navigator.of(context).pushNamed('/home');
    } else {
      Navigator.pushNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}
