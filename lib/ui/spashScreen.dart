import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:swiftpages/signUpPage.dart';
import 'package:swiftpages/ui/homePage.dart';
import 'package:swiftpages/ui/mainPage.dart';
import 'choosePage.dart';


class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {


  Future<void> checkLoginTime() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;

      try {
        DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (snapshot.exists) {
          // Cast snapshot.data() to a Map<String, dynamic>
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

          // Check if the document contains the 'lastLoginTimestamp' field
          if (data.containsKey('lastLoginTimestamp')) {
            // Extract the timestamp from the document
            Timestamp timestamp = data['lastLoginTimestamp'];

            // Convert the timestamp to a DateTime object
            DateTime lastLoginTime = timestamp.toDate();
            DateTime currentTime = DateTime.now();

            // Calculate the time difference
            Duration difference = currentTime.difference(lastLoginTime);

            // Log 'yes' if within 5 minutes, otherwise log 'no'
            if (difference.inMinutes <= 5) {
              log('yes');
            } else {
              log('no');
            }
          } else {
            print('The document does not contain the lastLoginTimestamp field.');
          }
        } else {
          print('User document not found.');
        }
      } catch (e) {
        print('Error fetching user document: $e');
      }
    }
  }

  Future<void> checkAuthentication() async {
    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage()) // Replace with your homepage
      );
    }else{
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>ChoosePage()));
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      checkLoginTime();
      checkAuthentication();
    });
  }
  @override
  void dispose() {
    super.dispose();
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

