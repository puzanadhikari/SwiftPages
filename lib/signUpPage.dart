import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftpages/loginPage.dart';
import 'package:swiftpages/ui/chooseAvatars.dart';
import 'package:swiftpages/ui/mainPage.dart';
import 'firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _authGoogle = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();
  List<String> usernames = [];
  @override
  void initState() {
    super.initState();
    usernames = [];
    fetchUsernames().then((value) {
      setState(() {
        usernames = value;
      });
    });
  }

  Future<List<String>> fetchUsernames() async {
    List<String> usernames = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('users').get();
      querySnapshot.docs.forEach((doc) {
        String username = doc['username'];
        usernames.add(username);
        log(usernames.toString());
      });
    } catch (e) {
      print('Error fetching usernames: $e');
    }

    return usernames;
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      setState(() {
        height = 70;
      });}
    if (usernames.contains(value)) {
      return 'Username already exists. Please enter a different username.';
    }

    return null;
  }
  bool obscurePassword = true;
  Future<void> _handleGoogleSignIn() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      GoogleAuthProvider _googleAuthProvider = GoogleAuthProvider();
      UserCredential userCredential =
      await _authGoogle.signInWithProvider(_googleAuthProvider);

      if (userCredential.user != null) {
        String? email = userCredential.user!.email;
        String? displayName = userCredential.user!.displayName;
        preferences.setString("email", email ?? "");
        preferences.setString("userName", displayName ?? "");
        String? photoURL = userCredential.user!.photoURL;
        preferences.setString("profilePicture",photoURL ?? "");

        // Navigate to the main page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }
    } catch (e) {
      print('Error during Google Sign-In: $e');
      // Handle the error as needed
    }
  }
  bool isEmailValid(String email) {
    // Simple email validation regex
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  double height=50;
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFEEAD4),
        body: SingleChildScrollView(
          child: Container(
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SvgPicture.asset(
                    "assets/RectangleSignUp.svg",
                    fit: BoxFit.fill
                  ),
                ),
                Positioned(
                  top: -30,
                  left: -20,
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    height: 180,
                    // color: Color(0xff283E50),
                  ),
                ),
                Positioned(
                  left: 100,
                  top: 150,
                  child: SizedBox(

                    // height: 38,
                    child: Column(
                      children: [
                        Text(
                          'WELCOME',
                          style: TextStyle(
                            color: Color(0xFF283E50),
                            fontSize: 32,
                            fontFamily: 'font',
                            fontWeight: FontWeight.w800,
                            height: 0,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Get ready for a journey where every page \n        turns into a swift adventure!!!!!',
                          style: TextStyle(
                            color: Color(0xFF686868),
                            fontSize: 12,
                            fontFamily: 'font',
                            height: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top:80.0,left: 40,right: 40),
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Remove the Image.asset from here

                        SizedBox(height: 160),
                        Padding(
                          padding: const EdgeInsets.only(top:45.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Email",
                                style: TextStyle(
                                  fontSize:18,
                                  fontWeight: FontWeight.bold,fontFamily:'font',
                                  color:  Color(0xFF686868),

                                ),
                              ),
                              SizedBox(height: 5,),
                              Container(
                                height: height,
                                child: TextFormField(
                                  style: TextStyle(fontFamily: 'font', color: Colors.grey[700], fontSize: 13),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      setState(() {
                                        height = 70;
                                      });
                                      return 'Please Enter Your Email';
                                    }
                                    if (!isEmailValid(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  controller: emailController,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: TextStyle(fontSize: 12, fontFamily: "font", color: Color(0xff686868).withOpacity(0.5)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Color(0xFFD9D9D9),
                                    errorStyle: TextStyle(color: Colors.grey[700], fontSize: 8, fontFamily: "font"),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Username",
                              style: TextStyle(
                                fontSize:18,
                                fontWeight: FontWeight.bold,fontFamily:'font',
                                color:  Color(0xFF686868),

                              ),
                            ),
                            SizedBox(height: 5,),
                            Container(
                              height: height,
                              child: TextFormField(

                                style: TextStyle(fontFamily: 'font',color:Colors.grey[700],fontSize: 13 ),
                                validator: validateUsername,

                                onChanged: validateUsername,
                                controller: userNameController,
                                decoration: InputDecoration(

                                    hintText: ' Enter Your UserName',
                                    hintStyle: TextStyle(
                                        fontSize: 12,
                                        fontFamily: "font",
                                        color: Color(0xff686868).withOpacity(0.5)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor:  Color(0xFFD9D9D9),
                                    errorStyle: TextStyle(color: Colors.grey[700],fontSize: 8,fontFamily: "font",)
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password",
                              style: TextStyle(
                                fontSize:18,
                                fontWeight: FontWeight.bold,fontFamily:'font',
                                color:  Color(0xFF686868),

                              ),
                            ),
                            SizedBox(height: 5,),
                            Container(
                              height: height,
                              child: TextFormField(
                                style: TextStyle(fontFamily: 'font',color:Colors.grey[700],fontSize: 13 ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    setState(() {
                                      height = 70;
                                    });
                                    return 'Please Enter Your Password';
                                  }
                                  return null;
                                },
                                controller: passwordController,
                                obscureText: obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Enter Your Password',
                                  hintStyle: TextStyle(
                                      fontSize: 12,
                                      fontFamily: "font",
                                      color: Color(0xff686868).withOpacity(0.5)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor:  Color(0xFFD9D9D9),
                                  errorStyle: TextStyle(color: Colors.grey[700],fontSize: 8,fontFamily: "font",),

                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Color(0xff686868).withOpacity(0.5),
                                        size: 18),
                                    onPressed: () {
                                      setState(() {
                                        obscurePassword = !obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: ()async {
                            if(_loginFormKey.currentState?.validate() ?? false)
                          { Navigator.push(context, MaterialPageRoute(builder: (context)=>ChooseAvatars(
                              emailController,userNameController,passwordController
                          )));
                          }
                          },
                          style: ElevatedButton.styleFrom(
                            primary:Color(0xFF283E50),// Background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                            ),
                          ),
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            child: Center(
                              child: Text(
                                'SIGN UP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontFamily: 'font',
                                  fontWeight: FontWeight.w800,
                                  height: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // SizedBox(height: 16.0),
                        // ElevatedButton(
                        //   onPressed: () {
                        //     _handleGoogleSignIn();
                        //      },
                        //   style: ElevatedButton.styleFrom(
                        //     primary: Color(0xFFFF997A),// Background color
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                        //     ),
                        //   ),
                        //   child: Container(
                        //     width: MediaQuery.of(context).size.width/1.5,
                        //     height: 26,
                        //     child: Center(
                        //       child: Text(
                        //         'Sign Up with Google',
                        //         textAlign: TextAlign.center,
                        //         style: TextStyle(
                        //           color: Color(0xFF283E50),
                        //           fontSize: 20,
                        //           fontFamily: 'font',
                        //           fontWeight: FontWeight.w800,
                        //           height: 0,
                        //         ),
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(
                                fontFamily: "font",
                                color: Color(0xFF686868),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginPage()),
                                );
                              },
                              child: Text(
                                " Login",
                                style: TextStyle(
                                  color: Color(0xFF686868),
                                  fontWeight: FontWeight.bold,fontFamily:'font',
                                  fontSize: 15,
                                  decoration: TextDecoration.underline,),

                              ),
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
