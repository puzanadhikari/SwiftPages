import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:swiftpages/loginPage.dart';
import 'package:swiftpages/signUpPage.dart';
import 'package:swiftpages/ui/mainPage.dart';

bool guestLogin = false;
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
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SvgPicture.asset(
                    'assets/logo.svg',
                    // height: 200,
                    // color: Color(0xff283E50),
                  ),
                  SizedBox(height: 20.0),
                  SizedBox(
                    height: 25,
                    child: Text(
                      'Let the reading adventure begin!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFEEAD4),
                        fontSize: 18,
                        fontFamily: 'font',
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
                            fontFamily: 'font',
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
                            fontFamily: 'font',
                            fontWeight: FontWeight.w800,
                            height: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showPersistentBottomSheet(context);
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
                            fontFamily: 'font',
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
          ),
        ],
      ),
    );
  }
  void _showPersistentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Color(0xFFFEEAD4),
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFEEAD4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            child: Container(
              color: Color(0xFFFEEAD4),
              width: MediaQuery.of(context).size.width * 0.9, // Adjust width as needed
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Taking a test drive?",style: TextStyle(fontSize: 30,   color: Color(0xFF283E50),fontFamily: 'font'),),
                    SizedBox(height: 30,),
                    Center(
                      child: Text("Discover more with a more personalized experience!! Unlock exclusive features and join our community for a richer experience!",style: TextStyle(
                        color: Color(0xFF686868),
                        fontSize: 14,
                        fontFamily: 'font',
                        fontWeight: FontWeight.w700,
                        height: 0,

                      ),),
                    ),
                    SizedBox(height: 50,),
                    Text("Are you sure you wanna log in as a guest instead of signing up?",style: TextStyle(
                      color: Color(0xFF686868),
                      fontSize: 14,
                      fontFamily: 'font',
                      fontWeight: FontWeight.w700,
                      height: 0,
                    ),),
                    SizedBox(height: 50,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              guestLogin = true;
                            });
                           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFFFF997A),// Background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                            ),
                          ),
                          child: Container(
                            height: 26,
                            child: Center(
                              child: Text(
                                'CONTINUE AS A GUEST',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:   Color(0xFF283E50),
                                  fontSize: 14,
                                  fontFamily: 'font',
                                  fontWeight: FontWeight.w800,
                                  height: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            primary:  Color(0xFF283E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                            ),
                          ),
                          child: Container(

                            height: 26,
                            child: Center(
                              child: Text(
                                'SIGN UP',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFF997A),
                                  fontSize: 16,
                                  fontFamily: 'font',
                                  fontWeight: FontWeight.w800,
                                  height: 0,
                                ),
                              ),
                            ),
                          ),
                        ),

                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



}

