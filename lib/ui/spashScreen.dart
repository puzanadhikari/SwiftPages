import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swiftpages/signUpPage.dart';

import 'choosePage.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  @override
  void initState() {
    super.initState();
    // Call the _navigateToNextScreen function after 1 second
    Timer(
      Duration(seconds: 1),
          () =>Navigator.push(context, MaterialPageRoute(builder: (context)=>ChoosePage())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Color(0xFF283E50),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/logo.png", height: 200.0, width: 200.0),
              SizedBox(height: 20.0),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xffFEEAD4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

