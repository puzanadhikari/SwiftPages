import 'dart:convert';
import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class RestoreStreakPage extends StatefulWidget {
  const RestoreStreakPage({Key? key}) : super(key: key);

  @override
  _RestoreStreakPageState createState() => _RestoreStreakPageState();
}

class _RestoreStreakPageState extends State<RestoreStreakPage> {
String avatarUrls='';
String package='';
  final storage = FirebaseStorage.instance;
  Reference get firebaseStorage => FirebaseStorage.instance.ref();
Future<void> sendUserDataEmail() async {
  User? user = FirebaseAuth.instance.currentUser;
  try {
    String email = 'swift.pages58@gmail.com';
    String subject = 'Restore Streak';

    String body = 'Payment for Restore streak done for, ${user?.displayName},with user id: ${user?.uid}';
    String encodedBody = Uri.encodeComponent(body);

    // Construct the mailto URL
    String mailtoUrl = 'mailto:$email?subject=$subject&body=$encodedBody';
    await launch(mailtoUrl);
    // Launch the URL

  } catch (e) {
    print('Error sending email: $e');
  }
}


Future<void> loadQr() async {
    try {
      Reference qrImageRef = FirebaseStorage.instance.ref().child('assets/qr.png');
      Reference packageImageRef = FirebaseStorage.instance.ref().child('assets/package.png');
       avatarUrls = await qrImageRef.getDownloadURL();
       package = await packageImageRef.getDownloadURL();
       setState(() {

       });
      //log('Download URL: $avatarUrls');
    } catch (e) {
      //log('Error fetching QR image: $e');
    }
  }


  @override
  void initState() {
    super.initState();
    loadQr();
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
                "Restore Streak",
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
            Center(
              child: Container(
                height:MediaQuery.of(context).size.height/1.5 ,
                width: MediaQuery.of(context).size.width / 1.2,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(46.0),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatarUrls==''?Center(child: LoadingAnimationWidget.staggeredDotsWave(color:Color(0xFF283E50),size: 100)):Center(child: Image.network(avatarUrls)),
                          SizedBox(height: 20,),
                Center(child: Text("Pay and Click Done",style: TextStyle(fontSize: 16,color:   Colors.black,),)),
                          SizedBox(height: 20,),
                          // package==''?Center(child: CircularProgressIndicator()):Center(child: Image.network(package)),
                          Padding(
                            padding: const EdgeInsets.only(top:50.0),
                            child: ElevatedButton(
                              onPressed: () {
                                sendUserDataEmail();
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
                                    'Done',
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
                          ),

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
