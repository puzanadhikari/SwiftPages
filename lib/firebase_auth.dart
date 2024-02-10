import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftpages/loginPage.dart';
import 'package:swiftpages/ui/homePage.dart';
import 'package:swiftpages/ui/mainPage.dart';
import 'package:swiftpages/ui/spashScreen.dart';

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
      BuildContext context, String email, String password, String username,String avatars,String dailyGoal,Color _avatarColor,int yearlyGoal) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(username);
      await userCredential.user?.updatePhotoURL(avatars);
     await addUserData(email,username,password,avatars,dailyGoal,_avatarColor,yearlyGoal);
      Fluttertoast.showToast(
          msg: 'Signup successfully',
          backgroundColor: Color(0xff283E50),
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
      //log("Error during registration: $e");
      Fluttertoast.showToast(
          msg: 'Signup Failed',
          backgroundColor: Color(0xff283E50),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
      return null;
    }
  }
  Future addUserData(String email,String username,String password,String avatar,String dailyGoal,Color _avatarColor,int yearlyGoal) async {
    try {

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Sample user data (customize based on your requirements)
        Map<String, dynamic> userData = {
          "email": email,
          "username": username,
          "password": password,
          "avatar": avatar,
          'dailyGoal': dailyGoal,
          'currentTime': 0,
          'avatarColor': _avatarColor.value,
          'lastStrikeTimestamp': null,
          'yearlyGoal':yearlyGoal,
          'totalTimeMin':0,
          'totalTimeSec':0,
          'increaseStrike':false,
          'lastStrike':0,
        };

        DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(uid);
        await userRef.set(userData);

        //log('User data stored successfully!');
      }} catch (e) {
      //log('Error storing user data: $e'); // Add this line to print the error
    }
  }
  // Future addUserDetail(String email,String username,String password,String avatar)async{
  // var firebaseUser = await FirebaseAuth.instance.currentUser;
  //
  //    FirebaseFirestore.instance.collection('users').add({
  //     "email":email,
  //     "username":username,
  //     "password":password,
  //     "avatar":avatar,
  //      "uid":firebaseUser?.uid,
  //   });
  // }

  Future<User?> signInWithEmailAndPassword(
      BuildContext context, String email, String password ) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      preferences.setString("email", credential.user?.email ?? "");
      preferences.setString("userName", credential.user?.displayName ?? "");
      preferences.setString("profilePicture", credential.user?.photoURL ?? "");
      if (credential.user != null) {
        String uid = credential.user!.uid;
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          preferences.setString(
            "dailyGoal",
            userDoc.get('dailyGoal') ?? "", // Replace 'dailyGoal' with the actual field name
          );
          preferences.setInt(
            "currentTime",
            userDoc.get('currentTime') ?? "", // Replace 'dailyGoal' with the actual field name
          );
        }
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'lastLoginTimestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (credential.user != null && credential.user!.emailVerified) {
        Fluttertoast.showToast(
            msg: 'Logged in Successful',
            backgroundColor: Color(0xff283E50),
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
      log("Error during login: $e");
      Fluttertoast.showToast(
          msg: 'Login Failed',
          backgroundColor: Color(0xff283E50),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP_RIGHT,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    return null;
  }

}
