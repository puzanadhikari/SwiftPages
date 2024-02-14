import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController msg = TextEditingController();
  Future addFormData() async {
    try {

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Sample user data (customize based on your requirements)
        Map<String, dynamic> contactFormData = {
          "email": email.text,
         "username":name.text,
          "message":msg.text
        };
        CollectionReference contactFormRef =
        FirebaseFirestore.instance.collection('contact_form').doc(uid).collection('forms');


        await contactFormRef.add(contactFormData);
        email.clear();
        name.clear();
        msg.clear();
        log('Form data stored successfully!');
        Fluttertoast.showToast(
            msg: ' Form Successfully Submitted',
            backgroundColor: Color(0xff283E50),
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.TOP_RIGHT,
            textColor: Colors.white,
            fontSize: 16.0);
      }} catch (e) {
      log('Error storing form data data: $e'); // Add this line to print the error
    }
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEEAD4),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                'assets/Ellipse.png', // Replace with the correct image path
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width / 2.5,
              child: const Text(
                "Contact Us",
                style: TextStyle(
                  fontFamily: "font",
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfffeead4),
                  height: 29 / 20,
                ),
              ),
            ),
            Positioned(
              top: -20,
              left: -10,
              child: Image.asset(
                "assets/logo.png",
                height: 120,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Center(
                child: Container(
                  height: MediaQuery.of(context).size.height / 1.25,
                  width: MediaQuery.of(context).size.width / 1.1,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(46.0),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Text(
                              "Hello!!",
                              style: TextStyle(
                                color: Color(0xFF283E50),
                                fontSize: 30,
                                fontWeight: FontWeight.bold,fontFamily:'font',

                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                              "If you have any feedbacks,suggestions or any type of bug report please don't hesitate to contact us. We want what's best for the app and our users!!",
                              style: TextStyle(
                                color: Color(0xFF686868),
                                fontWeight: FontWeight.bold,fontFamily:'font',
                                fontSize: 14,

                              ),
                              textAlign: TextAlign.center),
                          SizedBox(height: 40),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  30.0), // Adjust the radius as needed
                            ),
                            color: Color(0xFFFF997A),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30.0, vertical: 8.0),
                              child: TextFormField(
                                controller: name,
                                style: TextStyle(fontSize: 12,fontFamily: 'font',color: Color(0xFF283E50)),
                                decoration: InputDecoration(
                                  hintText: 'Full Name',
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.bold,fontFamily:'font',
                                      fontSize: 15),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  30.0), // Adjust the radius as needed
                            ),
                            color: Color(0xFFFF997A),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30.0, vertical: 8.0),
                              child: TextFormField(
                                style: TextStyle(fontSize: 12,fontFamily: 'font',color: Color(0xFF283E50)),
                                controller: email,
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  hintStyle: TextStyle(
                                      fontWeight: FontWeight.bold,fontFamily:'font',
                                      fontSize: 15),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
                            height: 280,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    30.0), // Adjust the radius as needed
                              ),
                              color: Color(0xFFFF997A),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30.0, vertical: 8.0),
                                child: TextFormField(
                                  style: TextStyle(fontSize: 12,fontFamily: 'font',color: Color(0xFF283E50)),
                                  controller: msg,
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    hintText: 'Message',
                                    hintStyle: TextStyle(
                                        fontWeight: FontWeight.bold,fontFamily:'font',
                                        fontSize: 15),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 25),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                addFormData();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 12.0),
                                child: Text(
                                  "Submit",
                                  style: TextStyle(
                                      color: Color(0xffFEEAD4),
                                      fontWeight: FontWeight.bold,fontFamily:'font',
                                      fontSize: 18),
                                ),
                              ),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Color(0xFF283E50)),
                                shape: MaterialStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
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
