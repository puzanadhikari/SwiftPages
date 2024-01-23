import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:swiftpages/signUpPage.dart';

import 'firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
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
                        fontFamily: 'Abhaya Libre ExtraBold',
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

                      SizedBox(height: 170),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Email",
                            style: TextStyle(
                              fontSize:14,
                              fontWeight: FontWeight.bold,
                              color:  Color(0xFF686868),
                              fontFamily: 'Abhaya Libre',
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
                            "Password",
                            style: TextStyle(
                              fontSize:14,
                              fontWeight: FontWeight.bold,
                              color:  Color(0xFF686868),
                              fontFamily: 'Abhaya Libre',
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
                          _auth.signInWithEmailAndPassword(context,
                              emailController.text, passwordController.text);
                          emailController.clear();
                          passwordController.clear();
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
                              'LOG IN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'Abhaya Libre ExtraBold',
                                fontWeight: FontWeight.w800,
                                height: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Do not have account?",
                            style: TextStyle(
                              color: Color(0xFF686868),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => SignUpPage()),
                              );
                            },
                            child: Text(
                              " Signup",
                              style: TextStyle(
                                color: Color(0xFF686868),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                decoration: TextDecoration.underline,),

                            ),
                          ),

                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            // Center(
            //   child: SingleChildScrollView(
            //     child: Container(
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(15.0),
            //         color: Colors.blueGrey,
            //       ),
            //       width: 400,
            //       height: 400,
            //       child: Padding(
            //         padding: const EdgeInsets.all(16.0),
            //         child: Column(
            //           mainAxisAlignment: MainAxisAlignment.center,
            //           children: [
            //             Text(
            //               "LOGIN",
            //               style: TextStyle(
            //                   fontSize: 30,
            //                   fontWeight: FontWeight.bold,
            //                   color: Colors.green),
            //             ),
            //             SizedBox(height: 40),
            //             Container(
            //               decoration: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(10.0),
            //                 color: Colors.grey[200],
            //               ),
            //               child: TextField(
            //                 controller: emailController,
            //                 decoration: InputDecoration(
            //                     hintText: 'Email',
            //                     border: InputBorder.none,
            //                     prefixIcon: Icon(Icons.email_outlined)),
            //               ),
            //             ),
            //             SizedBox(height: 16.0),
            //             Container(
            //               decoration: BoxDecoration(
            //                 borderRadius: BorderRadius.circular(10.0),
            //                 color: Colors.grey[200],
            //               ),
            //               child: TextField(
            //                 controller: passwordController,
            //                 obscureText: obscurePassword,
            //                 decoration: InputDecoration(
            //                   hintText: 'Password',
            //                   border: InputBorder.none,
            //                   prefixIcon: Icon(Icons.lock),
            //                   suffixIcon: IconButton(
            //                     icon: Icon(obscurePassword
            //                         ? Icons.visibility_off
            //                         : Icons.visibility),
            //                     onPressed: () {
            //                       setState(() {
            //                         obscurePassword = !obscurePassword;
            //                       });
            //                     },
            //                   ),
            //                 ),
            //               ),
            //             ),
            //             SizedBox(height: 16.0),
            //             ElevatedButton(
            //               onPressed: () {
            //                 _auth.signInWithEmailAndPassword(context,
            //                     emailController.text, passwordController.text);
            //                 emailController.clear();
            //                 passwordController.clear();
            //               },
            //               child: Text('Login',
            //                   style: TextStyle(color: Colors.white)),
            //               style: ElevatedButton.styleFrom(primary: Colors.green),
            //             ),
            //             SizedBox(height: 20),
            //             Row(
            //               mainAxisAlignment: MainAxisAlignment.center,
            //               children: [
            //                 Text(
            //                   "Don't have an account?",
            //                   style: TextStyle(color: Colors.black, fontSize: 15),
            //                 ),
            //                 GestureDetector(
            //                   onTap: () {
            //                     Navigator.push(
            //                       context,
            //                       MaterialPageRoute(
            //                           builder: (context) => SignUpPage()),
            //                     );
            //                   },
            //                   child: Text(
            //                     "    Sign Up",
            //                     style: TextStyle(
            //                         color: Colors.green,
            //                         fontWeight: FontWeight.bold,
            //                         fontSize: 15),
            //                   ),
            //                 )
            //               ],
            //             )
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
