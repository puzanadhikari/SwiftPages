import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:swiftpages/loginPage.dart';
import 'package:swiftpages/ui/homePage.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> SignUpWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Fluttertoast.showToast(
          msg: 'Signup successfully',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LoginPage()));

      // If the registration is successful, return the user.
      return userCredential.user;
    } catch (e) {
      // If there's an error during registration, handle it here.
      log("Error during registration: $e");
      Fluttertoast.showToast(
          msg: 'Signup Failed',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(
      BuildContext context, String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      log(credential.toString());
      Fluttertoast.showToast(
          msg: 'Login successfully',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage()));
      return credential.user;
    } catch (e) {
      log("Some error occured");
      Fluttertoast.showToast(
          msg: 'Login Failed',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    return null;
  }
}
