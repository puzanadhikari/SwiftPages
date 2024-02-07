import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _authGoogle = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();


  bool obscurePassword = true;
  Future<void> _handleGoogleSignIn() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    try {
      GoogleAuthProvider _googleAuthProvider = GoogleAuthProvider();
      UserCredential userCredential =
      await _authGoogle.signInWithProvider(_googleAuthProvider);

      // After successful sign-in, retrieve the user's information
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFEEAD4),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                "assets/RectangleSignUp.png",
                fit: BoxFit.contain, // Ensure the image covers the entire width
              ),
            ),
            Positioned(
              top: -30,
              left: -20,
              child: Image.asset(
                "assets/logo.png",
                height: 180,
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
                    Text(
                      'Get ready for a journey where every page \n        turns into a swift adventure!!!!!',
                      style: TextStyle(
                        color: Color(0xFF283E50),
                        fontSize: 12,

                        height: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Remove the Image.asset from here

                      SizedBox(height: 160),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Email",
                            style: TextStyle(
                              fontSize:14,
                              fontWeight: FontWeight.bold,fontFamily:'font',
                              color:  Color(0xFF686868),

                            ),
                          ),
                          SizedBox(height: 5,),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color:Color(0xFFD9D9D9),
                            ),
                            child: TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.email_outlined),
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
                            "Username",
                            style: TextStyle(
                              fontSize:14,
                              fontWeight: FontWeight.bold,fontFamily:'font',
                              color:  Color(0xFF686868),

                            ),
                          ),
                          SizedBox(height: 5,),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2.0),
                              color: Color(0xFFD9D9D9),
                            ),
                            child: TextField(
                              controller: userNameController,
                              decoration: InputDecoration(
                                hintText: 'Username',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.person),
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
                              fontSize:14,
                              fontWeight: FontWeight.bold,fontFamily:'font',
                              color:  Color(0xFF686868),

                            ),
                          ),
                          SizedBox(height: 5,),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2.0),
                              color: Color(0xFFD9D9D9),
                            ),
                            child: TextField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility),
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
                         Navigator.push(context, MaterialPageRoute(builder: (context)=>ChooseAvatars(
                          emailController,userNameController,passwordController
                        )));
                        },
                        style: ElevatedButton.styleFrom(
                          primary:Color(0xFF283E50),// Background color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                          ),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width/1.5,
                          height: 26,
                          child: Center(
                            child: Text(
                              'SIGN UP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'font',
                                fontWeight: FontWeight.w800,
                                height: 0,
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
            ),
          ],
        ),
      ),
    );
  }

}
