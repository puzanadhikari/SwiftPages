import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftpages/ui/contactUs.dart';
import 'package:swiftpages/ui/choosePage.dart';
import 'package:swiftpages/ui/community/savedPosts.dart';
import 'package:swiftpages/ui/community/ui.dart';
import 'package:swiftpages/ui/restoreStreak/ui.dart';
import 'package:swiftpages/ui/spashScreen.dart';
import 'package:swiftpages/ui/topNavigatorBar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../signUpPage.dart';
import 'aboutUs.dart';
import 'chart/ui.dart';
import 'community/myPosts.dart';
import 'myBooks.dart';
import 'package:share/share.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String email = ' ';
  String userName = ' ';
  String photoURL = ' ';
  String _invitationCode = '';
  int? _colorCode=0 ;
  TextEditingController _invitationCodeController = TextEditingController();

  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _passwordFieldController = TextEditingController();
  TextEditingController newGoal = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> fetchUserInfo() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      email = preferences.getString("email")!;
      userName = preferences.getString("userName")!;
      photoURL = preferences.getString("profilePicture")!;
    });
  }
  Future<void> _fetchColorCode() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Fetch the invitation code and timestamp from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        setState(() {
          _colorCode = snapshot.data()?['avatarColor'] ?? '';
        });

      }
    }
  }
  Future<void> _signOut() async {
    SharedPreferences prefs =await SharedPreferences.getInstance();
    try {
      prefs.clear();
      setState(() {
        guestLogin = false;
      });
      await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>SplashScreen()));
    } catch (e) {
      print("Error during logout: $e");
    }
  }




  Future<void> _changeGoal(bool reduce) async {
      final FirebaseAuth _auth = FirebaseAuth.instance;
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      int storedTime = userDoc.get('currentTime') ?? 0;
      String dailyGoal = userDoc.get('dailyGoal') ?? 0;
      int valueForDailyGoal = int.parse(dailyGoal)+int.parse(newGoal.text);
      try {
       if(storedTime!=0){
         if(reduce==true){
           if(int.parse(newGoal.text)!=int.parse(dailyGoal)){
                if(int.parse(newGoal.text)<int.parse(dailyGoal)){
                  await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': (newGoal.text),'currentTime':0});

                }else{
                  Fluttertoast.showToast(msg: "Your Daily goal cannot be greater than $dailyGoal",backgroundColor: const Color(0xff283E50),);
                }
                  }else{
             Fluttertoast.showToast(msg: "Your Daily goal cannot be equals to $dailyGoal",backgroundColor: const Color(0xff283E50),);
           }
         }else{
           await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': '$valueForDailyGoal','currentTime':FieldValue.increment(int.parse(newGoal.text)*60)});
         }
       }else{
         if(reduce==true){
           if(int.parse(newGoal.text)!=int.parse(dailyGoal)){
             if(int.parse(newGoal.text)<int.parse(dailyGoal)){
               await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': (newGoal.text),'currentTime':0});
             }else{
               Fluttertoast.showToast(msg: "Your Daily goal cannot be greater than $dailyGoal",backgroundColor: const Color(0xff283E50),);
             }
           }else{
             Fluttertoast.showToast(msg: "Your Daily goal cannot be equals to $dailyGoal",backgroundColor: const Color(0xff283E50),);
           }
         }else{
           await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': '$valueForDailyGoal','currentTime':FieldValue.increment(int.parse(newGoal.text)*60)});
         }
       }
            print('Strikes increased for user with ID: ${_auth.currentUser?.uid}');
      } catch (error) {
        print('Error increasing strikes for user with ID: ${_auth.currentUser
            ?.uid} - $error');
        // Handle the error (e.g., show an error message)
      }
  }





  Future<void> _sendPasswordResetEmail() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your email.'),
        ),
      );
    } catch (e) {
      print('Error sending password reset email: $e');
      // Handle the error (e.g., show an error message)
    }
  }
  Future<void> _generateInvitationCode() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Generate a random 4-letter code
      String code = _generateRandomCode();

      // Update only the 'invitationCode' field in the user's Firestore document
      await _firestore.collection('users').doc(user.uid).update({'invitationCode': code});

      setState(() {
        _invitationCode = code;
      });
    }
  }

  Future<void> _fetchInvitationCode() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Fetch the invitation code and timestamp from Firestore
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await _firestore.collection('users').doc(user.uid).get();

      if (snapshot.exists) {
        setState(() {
          _invitationCode = snapshot.data()?['invitationCode'] ?? '';

        });
        // _showInvitationCodePopup();
        int? result = await showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            return CustomAlertInvideDialog(code:_invitationCode);


          },
        );

        if (result != null) {
          // Do something with the selected number
          print('Selected Number: $result');
        }

      }
    }
  }
  String _generateRandomCode() {
    // Generate a random 4-letter code (you may customize this logic)
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String code = '';
    for (int i = 0; i < 4; i++) {
      code += chars[DateTime.now().microsecondsSinceEpoch % chars.length];
    }
    return code;
  }

  void _showInvitationCodePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your Invitation Code',style: TextStyle(fontFamily: 'font',),),
          content: Text(_invitationCode,style: const TextStyle(fontFamily: 'font',),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close',style: TextStyle(fontFamily: 'font',),),
            ),
          ],
        );
      },
    );
  }

  void _showInvitationCodeEnterPopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Your Invitation Code',style: TextStyle(fontFamily: 'font',),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(
                    color: Color(0xff283E50),
                    fontFamily: 'font'
                ),
                controller: _invitationCodeController,
                decoration: const InputDecoration(labelText: 'Invitation Code'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _validateInvitationCode();
                },
                child: const Text('Submit',style: TextStyle(fontFamily: 'font',),),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close',style: TextStyle(fontFamily: 'font',),),
            ),
          ],
        );
      },
    );
  }
  void _validateInvitationCode() async{
    User? user = _auth.currentUser;
    String enteredCode = _invitationCodeController.text.trim();
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('users').doc(user?.uid).get();
    // Perform a query to find the user with the entered invitation code
    _firestore
        .collection('users')
        .where('invitationCode', isEqualTo: enteredCode)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // User with the entered code found
        DocumentSnapshot redeemingUserDocument = querySnapshot.docs.first;
        String? redeemingUserId = _auth.currentUser?.uid;

        // Check if the redeeming user has already redeemed the invitation
        bool hasRedeemed = snapshot.data()?['redeemed'] ?? false;
        //log(hasRedeemed.toString());
        if (hasRedeemed) {
          // User has already redeemed the invitation
          print('Already redeemed the invitation code!');
          // You may show a toast or other messages to indicate that it's already redeemed
          Fluttertoast.showToast(
            msg: 'Invitation code already redeemed!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        } else {
          // Increase strikes for the redeeming user
          _increaseStrikes(redeemingUserId!);

          // Increase strikes for the generating user
          String generatorUserId = redeemingUserDocument.id ?? '';
          _increaseStrikes(generatorUserId);

          // Delete the invitation code from the generating user's document
          _deleteInvitationCode(generatorUserId);

          // Mark the invitation as redeemed for the redeeming user
          _markInvitationAsRedeemed(redeemingUserId);

          print('Code is valid for user with ID: $redeemingUserId');
          Navigator.of(context).pop(); // Close the dialog

          // Implement your logic here based on the user associated with the code
        }
      } else {
        // Code is invalid, show an error message
        print('Invalid code!');
        // You may show an error message or take other actions
        Fluttertoast.showToast(
          msg: 'Invalid invitation code!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }).catchError((error) {
      print('Error validating code: $error');
      // Handle the error (e.g., show an error message)
      Fluttertoast.showToast(
        msg: 'Error validating invitation code!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    });
  }


  Future<void> _markInvitationAsRedeemed(String userId) async {
    User? user = _auth.currentUser;

    try {
      // Mark the 'redeemed' field as true for the user with the given ID
      await _firestore.collection('users').doc(user?.uid).update({'redeemed': true});
      print('Invitation marked as redeemed for user with ID: $userId');
    } catch (error) {
      print('Error marking invitation as redeemed for user with ID: $userId - $error');
      // Handle the error (e.g., show an error message)
    }
  }


  Future<void> _deleteInvitationCode(String userId) async {
    try {
        await _firestore.collection('users').doc(userId).update({'invitationCode': FieldValue.delete()});
      print('Invitation code deleted for user with ID: $userId');
    } catch (error) {
      print('Error deleting invitation code for user with ID: $userId - $error');
        }
  }
  Future<void> _increaseStrikes(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      // String strikeIncreseCount = userDoc.get('dailyGoal') ?? 0;
      await _firestore.collection('users').doc(userId).update({'strikes': FieldValue.increment(10)});
      // await _firestore.collection('users').doc(userId).get();
      print('Strikes increased for user with ID: $userId');
    } catch (error) {
      print('Error increasing strikes for user with ID: $userId - $error');
      // Handle the error (e.g., show an error message)
    }
  }



  @override
  void initState() {
    super.initState();
    _fetchColorCode();
    fetchUserInfo();
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
                "Profile",
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
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: (){
                  _signOut();
                },
                child: SvgPicture.asset('assets/logoutIcon.svg',
                    height: 30, ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top:100.0),
              child: Center(
                child: Container(
                  height:MediaQuery.of(context).size.height/1.2 ,
                  width: MediaQuery.of(context).size.width / 1.2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    borderRadius: BorderRadius.circular(40.0),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      '${guestLogin==true?'GUEST':userName.toUpperCase()}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontFamily: 'font',
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      "${guestLogin==true?'guest@swiftpages':email}",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF686868),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,fontFamily:'font',
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                               guestLogin==true?const Icon(Icons.person): CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(photoURL ?? ''),
                                  backgroundColor: Color(_colorCode!),
                                ),
                              ],
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            const Text(
                              "Account",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,fontFamily:'font', fontSize: 20),
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/person.png"),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: ()async{

                                      if(guestLogin==true){
                                        _showPersistentBottomSheet( context);
                                    }else{
                                        int? result = await showDialog<int>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CustomAlertDialog(

                                            );
                                          },
                                        );

                                        if (result != null) {
                                          // Do something with the selected number
                                          print('Selected Number: $result');
                                        }
                                      }



                                      // _showEditDisplayNameDialog();

                                    },
                                    child: const Text("Change Username",style: TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/key.png"),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                  onTap: ()async{
                                    if(guestLogin==true){
                                      _showPersistentBottomSheet( context);
                                    }else{
                                      int? result = await showDialog<int>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return CustomAlertPasswordDialog(
                                                email:email
                                          );
                                        },
                                      );

                                      if (result != null) {
                                        // Do something with the selected number
                                        print('Selected Number: $result');
                                      }
                                    }

                                  },
                                    child: const Text("Change Password",style: TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/close.png",height: 20,),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: ()async{
                                      // guestLogin==true?_showPersistentBottomSheet( context):  _showEditEmailDialog();

                                      if(guestLogin==true){
                                        _showPersistentBottomSheet( context);
                                      }else{
                                        int? result = await showDialog<int>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CustomAlertDailyGoalDialog();


                                          },
                                        );

                                        if (result != null) {
                                          // Do something with the selected number
                                          print('Selected Number: $result');
                                        }
                                      }

                                    },
                                    child: const Text("Change Time Goal",style: TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/close.png",height: 20,),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: ()async{
                                      // guestLogin==true?_showPersistentBottomSheet( context):  _showEditEmailDialog();

                                      if(guestLogin==true){
                                        _showPersistentBottomSheet( context);
                                      }else{
                                        int? result = await showDialog<int>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return CustomAlertYearlyGoalDialog();

                                          },
                                        );

                                        if (result != null) {
                                          // Do something with the selected number
                                          print('Selected Number: $result');
                                        }
                                      }

                                    },
                                    child: const Text("Change Book Goal",style: TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                             Divider(
                                    thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            const Text(
                              "Book Settings",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,fontFamily:'font', fontSize: 16),
                            ),
                            const SizedBox(height: 20,),
                            GestureDetector(
                              onTap: ()async{
                                if(guestLogin==true){
                                  _showPersistentBottomSheet( context);
                                }else{
                                  _generateInvitationCode();
                                  _fetchInvitationCode();

                                }
                                // guestLogin==true?_showPersistentBottomSheet( context):   _generateInvitationCode();
                                // guestLogin==true?_showPersistentBottomSheet( context):   _fetchInvitationCode();
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset("assets/envelope.png",height: 15,),
                                  const SizedBox(width: 15,),
                                  const Text("Invite a Friend",style: TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20,),
                            GestureDetector(
                              onTap: ()async{
                                // guestLogin==true?_showPersistentBottomSheet( context):    _showInvitationCodeEnterPopup();
                                if(guestLogin==true){
                                  _showPersistentBottomSheet( context);
                                }else{
                                  int? result = await showDialog<int>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return CustomAlertRedeemDialog();


                                    },
                                  );

                                  if (result != null) {
                                    // Do something with the selected number
                                    print('Selected Number: $result');
                                  }
                                }
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset("assets/envelope.png",height: 15,),
                                  const SizedBox(width: 15,),
                                  const Text("Redeem",style: TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),),
                                ],
                              ),
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            const Text(
                              "Social",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,fontFamily:'font', fontSize: 16),
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Image.asset("assets/envelope.png",height: 20,),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      guestLogin==true?_showPersistentBottomSheet( context):    Navigator.push(context, MaterialPageRoute(builder: (context)=>TopNavigation(false)));
                                    },
                                    child: const Text("Community",style: TextStyle(fontFamily: 'font',fontSize: 16,color:   Color(0xFF686868),),)),
                              ],
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),

                            const Text(
                              "Streak Setting",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,fontFamily:'font', fontSize: 16),
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Image.asset("assets/strick.png",color: const Color(0xFF686868),height: 20,),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      guestLogin==true? _showPersistentBottomSheet( context):     Navigator.push(context, MaterialPageRoute(builder: (context)=>const RestoreStreakPage()));
                                    },
                                    child: const Text("Restore Streaks",style: TextStyle(fontFamily: 'font',fontSize: 16,color:   Color(0xFF686868),),)),
                              ],
                            ),



                            Divider(
                              thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            const Text(
                              "Setting",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,fontFamily:'font', fontSize: 16),
                            ),
                            const SizedBox(height: 20,),
                           Row(
                             children: [
                               Image.asset("assets/strick.png",color: const Color(0xFF686868),height: 20,),
                               const SizedBox(width: 15,),
                               GestureDetector(
                                   onTap: (){
                                     Navigator.push(context, MaterialPageRoute(builder: (context)=>AboutUsPage()));
                                   },
                                   child: const Text("About us",style: TextStyle(fontFamily: 'font',fontSize: 16,color:   Color(0xFF686868)),)),
                             ],
                           ),
                            const SizedBox(height: 20,),
                            Row(
                              children: [
                                Image.asset("assets/strick.png",color: const Color(0xFF686868),height: 20,),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>const ContactUsPage()));
                                    },
                                    child: const Text("Contact us",style: TextStyle(fontFamily: 'font',fontSize: 16,color:   Color(0xFF686868)),)),
                              ],
                            ),
                            const SizedBox(height: 20,),
                            Row(
                              children: [
                                Image.asset("assets/strick.png",color: const Color(0xFF686868),height: 20,),
                                const SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: ()async{
                                      String playStoreLink = '';

                                      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
                                      final FirebaseAuth _auth = FirebaseAuth.instance;

                                      try {
                                        DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
                                            .collection('about_us')
                                            .doc('mjZWNYj7FARJMCZYrFt2')
                                            .get();

                                        playStoreLink = userDoc.get('playstoreLink')??'';

                                      launchUrl(Uri.parse(playStoreLink));

                                      } catch (error) {
                                        log('Error fetching data link: $error');
                                      }

                                    },
                                    child: const Text("Rate us",style: TextStyle(fontFamily: 'font',fontSize: 16,color:   Color(0xFF686868)),)),
                              ],
                            )
                          ],
                        ),
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
  void _showPersistentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: const Color(0xFFFEEAD4),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFEEAD4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            child: Container(
              color: const Color(0xFFFEEAD4),
              width: MediaQuery.of(context).size.width * 0.9, // Adjust width as needed
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset('assets/oops.svg',
                   ),
                    const Text("OOPS!!!",style: TextStyle(fontFamily: 'font',fontSize: 30,   color: Color(0xFF686868),),),
                    const SizedBox(height: 30,),
                    const Text("Looks like you haven’t signed in yet.",style: TextStyle(
                      color: Color(0xFF686868),
                      fontSize: 14,
                      fontFamily: 'font',
                      fontWeight: FontWeight.w700,
                      height: 0,
                    ),),
                    const SizedBox(height: 50,),
                    const Text("To access this exciting feature, please sign in to your account. Join our community to interact with fellow readers, share your thoughts, and discover more.",style: TextStyle(fontFamily: 'font',
                      color: Color(0xFF686868),
                      fontSize: 14,

                      fontWeight: FontWeight.w700,
                      height: 0,
                    ),),
                    const SizedBox(height: 50,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                                Navigator.pop(context);
                            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            primary: const Color(0xFFFF997A),// Background color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                            ),
                          ),
                          child: Container(
                            height: 26,
                            child: const Center(
                              child: Text(  
                                'GO BACK',
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
                            setState(() {
                              guestLogin= false;
                            });
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SignUpPage()));
                          },
                          style: ElevatedButton.styleFrom(
                            primary:  const Color(0xFF283E50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8), // Adjust the border radius as needed
                            ),
                          ),
                          child: Container(
                            height: 26,
                            child: const Center(
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

  void _showEditEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Edit Goal Time",
            style: TextStyle(fontFamily: 'font',color: Colors.blue),
          ),
          content: TextField(
            style: const TextStyle(
                color: Color(0xff283E50),
                fontFamily: 'font'
            ),
            controller: newGoal,
            decoration: const InputDecoration(
              hintText: "Enter new goal Time",
              hintStyle: TextStyle(fontFamily: 'font',color: Colors.grey),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _changeGoal( true);
                Navigator.pop(context);
              },
              child: const Text(
                "Reduce",
                style: TextStyle(fontFamily: 'font',color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                _changeGoal(false);
                Navigator.pop(context);
              },
              child: const Text(
                "Increase",
                style: TextStyle(fontFamily: 'font',color: Colors.green),
              ),
            ),
          ],
          backgroundColor: const Color(0xFFD9D9D9),
        );
      },
    );
  }

  void _showEditPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Edit User Name",
            style: TextStyle(fontFamily: 'font',color: Colors.blue), // Set title text color
          ),
          content: const Text("Are you sure want to change your password?",style: TextStyle(fontFamily: 'font',),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text(
                "No",
                style: TextStyle(fontFamily: 'font',color: Color(0xff283E50)), // Set cancel text color
              ),
            ),
            TextButton(
              onPressed: () {
                _sendPasswordResetEmail();
                  Navigator.pop(context); // Close the dialog
              },

              child: const Text(
                "Yes",
                style: TextStyle(fontFamily: 'font',color: Colors.green), // Set save text color
              ),
            ),
          ],
          backgroundColor: const Color(0xFFD9D9D9), // Set dialog background color
        );
      },
    );
  }
}
class CustomAlertDialog extends StatefulWidget {

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  int selectedNumber = 0;
    TextEditingController _textFieldController = TextEditingController();
  void updateDisplayName(String newDisplayName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.updateDisplayName(newDisplayName);
        String userId = user.uid;
        DocumentReference userRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
        await userRef.update({'username': newDisplayName});
        _signOut();
        print("Display name updated successfully: $newDisplayName");

      } else {

      }
    } catch (e) {
      print("Error updating display name: $e");
    }
  }
  Future<void> _signOut() async {
    SharedPreferences prefs =await SharedPreferences.getInstance();
    try {
      prefs.clear();
      setState(() {
        guestLogin = false;
      });
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>SplashScreen()));
    } catch (e) {
      print("Error during logout: $e");
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          const Text(
            'Change Username',
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: const BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child:TextFormField(
          
              style: const TextStyle(
                  color: Color(0xff283E50),
                  fontFamily: 'font'
              ),

              controller: _textFieldController,
              decoration: const InputDecoration(
                hintText: "Enter new User Name",
                hintStyle: TextStyle(fontFamily: 'font',color: Colors.grey), // Set hint text color
              ),
            ),
          ),
        ),   
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {

                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _textFieldController.text.isEmpty?Fluttertoast.showToast(msg: "Enter the valid name",backgroundColor: const Color(0xFFFF997A)) :updateDisplayName(_textFieldController.text);
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


}



class CustomAlertPasswordDialog extends StatefulWidget {
  String email;
  CustomAlertPasswordDialog({required this.email});
  @override
  _CustomAlertPasswordDialogState createState() => _CustomAlertPasswordDialogState();
}

class _CustomAlertPasswordDialogState extends State<CustomAlertPasswordDialog> {
  int selectedNumber = 0;

  Future<void> _signOut() async {
    SharedPreferences prefs =await SharedPreferences.getInstance();
    try {
      prefs.clear();
      setState(() {
        guestLogin = false;
      });
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>SplashScreen()));
    } catch (e) {
      print("Error during logout: $e");
    }
  }
  Future<void> _sendPasswordResetEmail() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: widget.email,
      );
        Fluttertoast.showToast(msg: "Password reset email sent! Check your email.",backgroundColor: const Color(0xFFFF997A));


    } catch (e) {
      print('Error sending password reset email: $e');
      // Handle the error (e.g., show an error message)
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          const Text(
            'Change Password',
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),

        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: const BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 8.0),
            child: Text("Are you sure want to change your password?",style: TextStyle(fontFamily: 'font',),)
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {
                    Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                   _sendPasswordResetEmail();
                      _signOut();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Send',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


}




class CustomAlertDailyGoalDialog extends StatefulWidget {

  @override
  _CustomAlertDailyGoalDialogState createState() => _CustomAlertDailyGoalDialogState();
}

class _CustomAlertDailyGoalDialogState extends State<CustomAlertDailyGoalDialog> {
  int selectedNumber = 0;
  TextEditingController newGoal = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> _changeGoal(bool reduce) async {

    final FirebaseAuth _auth = FirebaseAuth.instance;
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .get();
    int storedTime = userDoc.get('currentTime') ?? 0;
    String dailyGoal = userDoc.get('dailyGoal') ?? 0;
    int valueForDailyGoal = int.parse(dailyGoal)+int.parse(newGoal.text);
    try {
      if(storedTime!=0){
        if(reduce==true){
          if(int.parse(newGoal.text)!=int.parse(dailyGoal)){
            if(int.parse(newGoal.text)<int.parse(dailyGoal)){
              await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': (newGoal.text),'currentTime':0});

            }else{
              Fluttertoast.showToast(msg: "Your Daily goal cannot be greater than $dailyGoal",backgroundColor: const Color(0xff283E50),);
            }
          }else{
            Fluttertoast.showToast(msg: "Your Daily goal cannot be equals to $dailyGoal",backgroundColor: const Color(0xff283E50),);
          }
        }else{
          await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': '$valueForDailyGoal','currentTime':FieldValue.increment(int.parse(newGoal.text)*60)});
        }
      }else{
        if(reduce==true){
          if(int.parse(newGoal.text)!=int.parse(dailyGoal)){
            if(int.parse(newGoal.text)<int.parse(dailyGoal)){
              await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': (newGoal.text),'currentTime':0});
            }else{
              Fluttertoast.showToast(msg: "Your Daily goal cannot be greater than $dailyGoal");
            }
          }else{
            Fluttertoast.showToast(msg: "Your Daily goal cannot be equals to $dailyGoal");
          }
        }else{
          await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': '$valueForDailyGoal','currentTime':FieldValue.increment(int.parse(newGoal.text)*60)});
        }
      }
      print('Strikes increased for user with ID: ${_auth.currentUser?.uid}');
    } catch (error) {
      print('Error increasing strikes for user with ID: ${_auth.currentUser
          ?.uid} - $error');
      // Handle the error (e.g., show an error message)
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          const Text(
            'Change Time Goal',
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
          ),
          const Text(
            'Note: If you reduce the time you will loose your daily goal progress.',
            style: TextStyle(color: Colors.red,fontFamily: 'font',fontSize: 10),
          ),

        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: const BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Expanded(
          child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child:   TextField(
                style: const TextStyle(
                    color: Color(0xff283E50),
                    fontFamily: 'font'
                ),
                controller: newGoal,
                decoration: const InputDecoration(
                  hintText: "Enter new goal Time",
                  hintStyle: TextStyle(fontFamily: 'font',color: Colors.grey),
                ),
              ),
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {
                      _changeGoal( true);
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: "Time updated successfully!",backgroundColor:const Color(0xFF283E50), );
                    },
                    child: const Text(
                      'Replace',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _changeGoal(false);
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: "Time updated successfully!",backgroundColor:const Color(0xFF283E50), );
                    },
                    child: const Text(
                      'Increase',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


}



class CustomAlertYearlyGoalDialog extends StatefulWidget {

  @override
  _CustomAlertYearlyGoalDialogState createState() => _CustomAlertYearlyGoalDialogState();
}

class _CustomAlertYearlyGoalDialogState extends State<CustomAlertYearlyGoalDialog> {
  int selectedNumber = 0;
  TextEditingController newGoal = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> _changeGoal() async {

    final FirebaseAuth _auth = FirebaseAuth.instance;
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(_auth.currentUser?.uid)
        .get();

    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'yearlyGoal': (int.parse(newGoal.text))});
    Fluttertoast.showToast(msg: "Your Yearly goal cannot be greater than ${newGoal.text}",backgroundColor: const Color(0xff283E50),);

  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          const Text(
            'Change Book Goal',
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: const BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child:   TextField(
              style: const TextStyle(
                  color: Color(0xff283E50),
                  fontFamily: 'font'
              ),
              controller: newGoal,
              decoration: const InputDecoration(
                hintText: "Enter new book Goal",
                hintStyle: TextStyle(fontFamily: 'font',color: Colors.grey),
              ),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {

                      Navigator.pop(context);

                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _changeGoal();
                      Navigator.pop(context);
                      Fluttertoast.showToast(msg: "Goal updated successfully!",backgroundColor:const Color(0xFF283E50), );
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


}






class CustomAlertInvideDialog extends StatefulWidget {
  String code;
  CustomAlertInvideDialog({required this.code});
  @override
  _CustomAlertInvideDialogState createState() => _CustomAlertInvideDialogState();
}

class _CustomAlertInvideDialogState extends State<CustomAlertInvideDialog> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          const Text(
            'Invite a friend',
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),

        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: const BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child:   Text("Your invitation code is : ${widget.code}",style: const TextStyle(fontFamily: 'font',fontSize: 16,color:  Color(0xFF686868),),),
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {

                      Navigator.pop(context);

                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _shareInviteCode();
                      Navigator.pop(context);

                    },
                    child: const Text(
                      'Share',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  void _shareInviteCode() async{
    String appName = 'Swift Pages';
    String appDescription = 'Share your invitation code and invite friends to join $appName!';
    String playStoreLink = ''; // Replace with your app's Play Store link

    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('about_us')
          .doc('mjZWNYj7FARJMCZYrFt2')
          .get();

          playStoreLink = userDoc.get('playstoreLink')??'';



    } catch (error) {
      log('Error fetching data link: $error');
    }

    String message = '''
  Hey there! 👋

  I'm inviting you to join $appName! 📚📖

  Here's my invitation code: ${widget.code}

  $appDescription

  Download $appName on the Play Store: $playStoreLink

  Let's read together and enjoy our favorite books! 📚🌟
  ''';

    Share.share(message);
  }

}



class CustomAlertRedeemDialog extends StatefulWidget {

  @override
  _CustomAlertRedeemDialogState createState() => _CustomAlertRedeemDialogState();
}

class _CustomAlertRedeemDialogState extends State<CustomAlertRedeemDialog> {
  TextEditingController _invitationCodeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          const Text(
            'Redeem your offer',
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
          ),
          const Divider(
            color: Colors.grey,
            thickness: 1,
          ),

        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: const BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: TextField(
              controller: _invitationCodeController,
              style: const TextStyle(
                color: Color(0xff283E50),
                fontFamily: 'font'
              ),
              decoration: const InputDecoration(
                hintText: "Enter the invitation code",

                hintStyle: TextStyle(fontFamily: 'font',color: Colors.grey), // Set hint text color
              ),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {

                      Navigator.pop(context);

                    },
                    child: const Text(
                      'Close',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _validateInvitationCode();
                      Navigator.pop(context);

                    },
                    child: const Text(
                      'Redeem',
                      style: TextStyle(
                          color: Colors.white,fontFamily: 'font'
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  void _validateInvitationCode() async{

    User? user = _auth.currentUser;
    String enteredCode = _invitationCodeController.text.trim();
    DocumentSnapshot<Map<String, dynamic>> snapshot =
    await _firestore.collection('users').doc(user?.uid).get();
    // Perform a query to find the user with the entered invitation code
    _firestore
        .collection('users')
        .where('invitationCode', isEqualTo: enteredCode)
        .get()
        .then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        // User with the entered code found
        DocumentSnapshot redeemingUserDocument = querySnapshot.docs.first;
        String? redeemingUserId = _auth.currentUser?.uid;

        // Check if the redeeming user has already redeemed the invitation
        bool hasRedeemed = snapshot.data()?['redeemed'] ?? false;
        //log(hasRedeemed.toString());
        if (hasRedeemed) {
          // User has already redeemed the invitation
          print('Already redeemed the invitation code!');
          // You may show a toast or other messages to indicate that it's already redeemed
          Fluttertoast.showToast(
            msg: 'Invitation code already redeemed!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color(0xFFFF997A),
            textColor:  const Color(0xff283E50),
          );
        } else {
          // Increase strikes for the redeeming user
          _increaseStrikes(redeemingUserId!);
          Fluttertoast.showToast(
            msg: 'Code Redeemed Successfully!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: const Color(0xFFFF997A),
            textColor:  const Color(0xff283E50),
          );
          // Increase strikes for the generating user
          String generatorUserId = redeemingUserDocument.id ?? '';
          _increaseStrikes(generatorUserId);

          // Delete the invitation code from the generating user's document
          _deleteInvitationCode(generatorUserId);

          // Mark the invitation as redeemed for the redeeming user
          _markInvitationAsRedeemed(redeemingUserId);

          print('Code is valid for user with ID: $redeemingUserId');
          Navigator.of(context).pop(); // Close the dialog

          // Implement your logic here based on the user associated with the code
        }
      } else {
        // Code is invalid, show an error message
        // Fluttertoast.showToast(msg: 'Invalid code!',backgroundColor: Color(0xff283E50));
        print('Invalid code!');
        // You may show an error message or take other actions
        Fluttertoast.showToast(
          msg: 'Invalid invitation code!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: const Color(0xFFFF997A),
          textColor:  const Color(0xff283E50),
        );
      }
    }).catchError((error) {
      print('Error validating code: $error');
      // Handle the error (e.g., show an error message)
      // Fluttertoast.showToast(
      //   msg: 'Error validating invitation code!',
      //   toastLength: Toast.LENGTH_SHORT,
      //   gravity: ToastGravity.BOTTOM,
      //   timeInSecForIosWeb: 1,
      //   backgroundColor: Color(0xFFFF997A),
      //   textColor:  Color(0xff283E50),
      // );
    });
  }


  Future<void> _markInvitationAsRedeemed(String userId) async {
    User? user = _auth.currentUser;

    try {
      // Mark the 'redeemed' field as true for the user with the given ID
      await _firestore.collection('users').doc(user?.uid).update({'redeemed': true});
      print('Invitation marked as redeemed for user with ID: $userId');
    } catch (error) {
      print('Error marking invitation as redeemed for user with ID: $userId - $error');
      // Handle the error (e.g., show an error message)
    }
  }


  Future<void> _deleteInvitationCode(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({'invitationCode': FieldValue.delete()});
      print('Invitation code deleted for user with ID: $userId');
    } catch (error) {
      print('Error deleting invitation code for user with ID: $userId - $error');
    }
  }
  Future<void> _increaseStrikes(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      // String strikeIncreseCount = userDoc.get('dailyGoal') ?? 0;
      await _firestore.collection('users').doc(userId).update({'strikes': FieldValue.increment(10)});
      // await _firestore.collection('users').doc(userId).get();
      print('Strikes increased for user with ID: $userId');
    } catch (error) {
      print('Error increasing strikes for user with ID: $userId - $error');
      // Handle the error (e.g., show an error message)
    }
  }

}