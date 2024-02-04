import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg instead of flutter_svg/svg.dart
import 'package:fluttertoast/fluttertoast.dart';
import 'package:swiftpages/contactUs.dart';
import 'package:swiftpages/ui/myBooks.dart';
import 'package:url_launcher/url_launcher.dart';


class AboutUsPage extends StatefulWidget {


  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {

   String instagramName = '';
   String instagramLogo = '';
   String linkedinName='';
   String linkedinLogo='';
   String emailUrl='';
   String emailLogo='';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String data = '';
  Future<void> fetchData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('about_us').doc('mjZWNYj7FARJMCZYrFt2').get();

      if (userDoc.exists) {
      setState(() {
        data = userDoc.get('description');
        instagramName = userDoc.get('instagram');
        linkedinName = userDoc.get('linkedin');
        emailUrl = userDoc.get('email');
        emailLogo = userDoc.get('emailLogo');
        instagramLogo = userDoc.get('instagramLogo');
        linkedinLogo = userDoc.get('linkedinLogo');

        log(data);
      });

      }
    } catch (error) {
      log('Error fetching data: $error');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xffFEEAD4),
        body: Container(
            height: MediaQuery.of(context).size.height,
            child:Stack(
              children: [
                SvgPicture.asset('assets/background.svg',
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.grey.withOpacity(0.2),
                ),
                Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 30,
                      child: GestureDetector(
                        onTap: (){
                          Navigator.pop(context);
                        },
                        child: Icon(Icons.arrow_back,),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      left: MediaQuery.of(context).size.width/4.5,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor:  Color(0xFF283E50),
                        child: Image.asset("assets/logo.png"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 270.0,right: 50,left: 50),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("ABOUT US",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 30),),

                          Row(
                            children: [
                              GestureDetector(
                                  onTap:()=> _launchURL(linkedinName),
                                  child:  linkedinLogo==''?Text(''):Image.network(linkedinLogo)),
                              SizedBox(width: 10,),
                              GestureDetector(
                                  onTap: ()=> _launchURL(instagramName),
                                  child: instagramLogo==''?Text(''):Image.network(instagramLogo)),
                              SizedBox(width: 10,),
                              GestureDetector(
                                  onTap: ()=> sendUserDataEmail(),
                                  child: emailLogo==''?Text(''):Image.network(emailLogo,height: 30,))
                            ],
                          ),

                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top:320.0,left: 20,right: 20),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Color(0xffFF997A),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(data,style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 16),),
                          ),

                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 50.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          children: [

                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding:  EdgeInsets.only(top:MediaQuery.of(context).size.height/1.2),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>ContactUsPage()));
                          },
                          child: Text("Contact Us",style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontSize: 18),),
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),


                  ],
                )
              ],
            )
        ),
      ),
    );
  }

   Future<void> _launchURL(String url) async {
     if (await canLaunch(url)) {
       await launch(url);
     } else {
       throw 'Could not launch $url';
     }
   }
   Future<void> sendUserDataEmail() async {
     User? user = FirebaseAuth.instance.currentUser;
     try {
       String email = emailUrl;
       String subject = 'Contact Swift Pages';

       String body = '';
       String encodedBody = Uri.encodeComponent(body);

       // Construct the mailto URL
       String mailtoUrl = 'mailto:$email?subject=$subject&body=$encodedBody';
       await launch(mailtoUrl);
       // Launch the URL

     } catch (e) {
       print('Error sending email: $e');
     }
   }
}
