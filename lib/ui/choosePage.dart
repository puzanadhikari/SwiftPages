import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:swiftpages/loginPage.dart';
import 'package:swiftpages/signUpPage.dart';

class ChoosePage extends StatefulWidget {
  @override
  State<ChoosePage> createState() => _ChoosePageState();
}

class _ChoosePageState extends State<ChoosePage> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Color(0xFF283E50),
          ),
          Padding(
            padding: const EdgeInsets.only(top:50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset("assets/logo.png"),
                SizedBox(height: 20.0),
                SizedBox(
                  height: 25,
                  child: Text(
                    'Let the reading adventure begin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFEEAD4),
                      fontSize: 18,
                      fontFamily: 'Abhaya Libre',
                      fontWeight: FontWeight.w700,
                      height: 0,
                    ),
                  ),
                ),
                SizedBox(height: 40,),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFFFEEAD4),// Background color
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
                          color: Color(0xFF283E50),
                          fontSize: 20,
                          fontFamily: 'Abhaya Libre ExtraBold',
                          fontWeight: FontWeight.w800,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFFFF997A),// Background color
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
                          color: Color(0xFF283E50),
                          fontSize: 20,
                          fontFamily: 'Abhaya Libre ExtraBold',
                          fontWeight: FontWeight.w800,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                   log("pressed");
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFFFEEAD4),// Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                    ),
                  ),
                  child: Container(
                    width: MediaQuery.of(context).size.width/1.5,
                    height: 26,
                    child: Center(
                      child: Text(
                        'LOG IN AS A GUEST',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF283E50),
                          fontSize: 20,
                          fontFamily: 'Abhaya Libre ExtraBold',
                          fontWeight: FontWeight.w800,
                          height: 0,
                        ),
                      ),
                    ),
                  ),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }
}

