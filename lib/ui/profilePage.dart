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
import 'package:swiftpages/ui/choosePage.dart';
import 'package:swiftpages/ui/community/savedPosts.dart';
import 'package:swiftpages/ui/community/ui.dart';
import 'package:swiftpages/ui/restoreStreak/ui.dart';
import 'package:swiftpages/ui/spashScreen.dart';
import 'package:swiftpages/ui/topNavigatorBar.dart';

import '../signUpPage.dart';
import 'community/myPosts.dart';
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

  void updateDisplayName(String newDisplayName) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await user.updateDisplayName(newDisplayName);
        _signOut();
        print("Display name updated successfully: $newDisplayName");

      } else {

      }
    } catch (e) {
      print("Error updating display name: $e");
         }
  }
  Future<void> _changeGoal() async {

      final FirebaseAuth _auth = FirebaseAuth.instance;
      try {
        await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'dailyGoal': (newGoal.text)});
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
        SnackBar(
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
        _showInvitationCodePopup();

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
          title: Text('Your Invitation Code'),
          content: Text(_invitationCode),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
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
          title: Text('Enter Your Invitation Code'),
          content: Column(
            children: [
              TextField(
                controller: _invitationCodeController,
                decoration: InputDecoration(labelText: 'Invitation Code'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _validateInvitationCode();
                },
                child: Text('Submit'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
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
        log(hasRedeemed.toString());
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
                  fontFamily: "Abhaya Libre ExtraBold",
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
                                      style: TextStyle(
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
                                      style: TextStyle(
                                        color: Color(0xFF686868),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                               guestLogin==true?Icon(Icons.person): CircleAvatar(
                                  radius: 40,
                                  backgroundImage: NetworkImage(photoURL ?? ''),
                                  backgroundColor: Color(0xfffeead4),
                                ),
                              ],
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            Text(
                              "Account",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                            SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/person.png"),
                                SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      guestLogin==true?_showPersistentBottomSheet( context):   _showEditDisplayNameDialog();
                                    },
                                    child: Text("Change Username",style: TextStyle(fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                            SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/key.png"),
                                SizedBox(width: 15,),
                                GestureDetector(
                                  onTap: (){
                                    guestLogin==true?_showPersistentBottomSheet( context):   _showEditPasswordDialog();
                                  },
                                    child: Text("Change Password",style: TextStyle(fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                            SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset("assets/close.png",height: 20,),
                                SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      guestLogin==true?_showPersistentBottomSheet( context):  _showEditEmailDialog();
                                    },
                                    child: Text("Change Time Goal",style: TextStyle(fontSize: 16,color:  Color(0xFF686868),),)),
                              ],
                            ),
                             Divider(
                                    thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            Text(
                              "Book Settings",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 20,),
                            GestureDetector(
                              onTap: (){
                                guestLogin==true?_showPersistentBottomSheet( context):   _generateInvitationCode();
                                guestLogin==true?_showPersistentBottomSheet( context):   _fetchInvitationCode();
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset("assets/envelope.png",height: 15,),
                                  SizedBox(width: 15,),
                                  Text("Invite a Friend",style: TextStyle(fontSize: 16,color:  Color(0xFF686868),),),
                                ],
                              ),
                            ),
                            SizedBox(height: 20,),
                            GestureDetector(
                              onTap: (){
                                guestLogin==true?_showPersistentBottomSheet( context):    _showInvitationCodeEnterPopup();
                                // _fetchInvitationCode();
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset("assets/envelope.png",height: 15,),
                                  SizedBox(width: 15,),
                                  Text("Redeem",style: TextStyle(fontSize: 16,color:  Color(0xFF686868),),),
                                ],
                              ),
                            ),
                            Divider(
                              thickness: 1,
                              color: Colors.black.withOpacity(0.25),
                            ),
                            Text(
                              "Social",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Image.asset("assets/envelope.png",height: 20,),
                                SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      guestLogin==true?_showPersistentBottomSheet( context):    Navigator.push(context, MaterialPageRoute(builder: (context)=>TopNavigation()));
                                    },
                                    child: Text("Community",style: TextStyle(fontSize: 16,color:   Color(0xFF686868),),)),
                              ],
                            ),
                            SizedBox(height: 20,),
                            Text(
                              "Streak Setting",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Image.asset("assets/strick.png",color: Color(0xFF686868),height: 20,),
                                SizedBox(width: 15,),
                                GestureDetector(
                                    onTap: (){
                                      guestLogin==true? _showPersistentBottomSheet( context):     Navigator.push(context, MaterialPageRoute(builder: (context)=>RestoreStreakPage()));
                                    },
                                    child: Text("Restore Streaks",style: TextStyle(fontSize: 16,color:   Color(0xFF686868),),)),
                              ],
                            ),

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
                    SvgPicture.asset('assets/oops.svg',
                   ),
                    Text("OOPS!!!",style: TextStyle(fontSize: 30,   color: Color(0xFF686868),),),
                    SizedBox(height: 30,),
                    Text("Looks like you haven’t signed in yet.",style: TextStyle(
                      color: Color(0xFF686868),
                      fontSize: 14,
                      fontFamily: 'Abhaya Libre',
                      fontWeight: FontWeight.w700,
                      height: 0,
                    ),),
                    SizedBox(height: 50,),
                    Text("To access this exciting feature, please sign in to your account. Join our community to interact with fellow readers, share your thoughts, and discover more.",style: TextStyle(
                      color: Color(0xFF686868),
                      fontSize: 14,
                      fontFamily: 'Abhaya Libre',
                      fontWeight: FontWeight.w700,
                      height: 0,
                    ),),
                    SizedBox(height: 50,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                                Navigator.pop(context);
                            // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainPage()));
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
                                'GO BACK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:   Color(0xFF283E50),
                                  fontSize: 14,
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
                            Navigator.pop(context);
                            setState(() {
                              guestLogin= false;
                            });
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>SignUpPage()));
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
                                  fontFamily: 'Abhaya Libre ExtraBold',
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
  void _showEditDisplayNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit User Name",
            style: TextStyle(color: Colors.blue), // Set title text color
          ),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(
              hintText: "Enter new User Name",
              hintStyle: TextStyle(color: Colors.grey), // Set hint text color
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.red), // Set cancel text color
              ),
            ),
            TextButton(
              onPressed: () {

                String newDisplayName = _textFieldController.text;

                updateDisplayName(newDisplayName);
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.green), // Set save text color
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9), // Set dialog background color
        );
      },
    );
  }
  void _showEditEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit Goal Time",
            style: TextStyle(color: Colors.blue),
          ),
          content: TextField(
            controller: newGoal,
            decoration: InputDecoration(
              hintText: "Enter new goal Time",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                _changeGoal();
                Navigator.pop(context);
              },
              child: Text(
                "Save",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9),
        );
      },
    );
  }

  void _showEditPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit User Name",
            style: TextStyle(color: Colors.blue), // Set title text color
          ),
          content: Text("Are you sure want to change your password?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "No",
                style: TextStyle(color: Colors.red), // Set cancel text color
              ),
            ),
            TextButton(
              onPressed: () {
                _sendPasswordResetEmail();
                  Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Yes",
                style: TextStyle(color: Colors.green), // Set save text color
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9), // Set dialog background color
        );
      },
    );
  }
}
