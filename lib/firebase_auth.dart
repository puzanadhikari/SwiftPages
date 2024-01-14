import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftpages/loginPage.dart';
import 'package:swiftpages/ui/homePage.dart';
import 'package:swiftpages/ui/mainPage.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  void sendVerificationEmail(BuildContext context) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent!'),
          ),
        );
      } else {
        print('User not signed in.');
      }
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  Future<User?> SignUpWithEmailAndPassword(
      BuildContext context, String email, String password, String username,String avatars) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(username);
      await userCredential.user?.updatePhotoURL(avatars);
      Fluttertoast.showToast(
          msg: 'Signup successfully',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
      sendVerificationEmail(context);
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
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      preferences.setString("email", credential.user?.email ?? "");
      preferences.setString("userName", credential.user?.displayName ?? "");
      preferences.setString("profilePicture", credential.user?.photoURL ?? "");

      // Check if the user's email is verified
      if (credential.user != null && credential.user!.emailVerified) {
        Fluttertoast.showToast(
            msg: 'Login successfully',
            backgroundColor: Colors.green,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP_RIGHT,
            textColor: Colors.white,
            fontSize: 16.0);

        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MainPage()));
        return credential.user;
      } else {
        // If email is not verified, show a message and sign out the user
        print('Email not verified. Please check your email for verification.');
        FirebaseAuth.instance.signOut();

        // Show an error message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email not verified. Please check your email for verification.'),
          ),
        );
      }
    } catch (e) {
      print("Error during login: $e");
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
