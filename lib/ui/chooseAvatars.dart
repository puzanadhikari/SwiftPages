import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../firebase_auth.dart';

class ChooseAvatars extends StatefulWidget {
  TextEditingController? _email;
  TextEditingController? _username;
  TextEditingController? _password;

  ChooseAvatars(this._email,this._username,this._password);
  @override
  State<ChooseAvatars> createState() => _ChooseAvatarsState();
}

class _ChooseAvatarsState extends State<ChooseAvatars> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  late List<String> avatarUrls;
  Color _avatarColor = Colors.white;
  TextEditingController _dailyGoal = TextEditingController();
  TextEditingController _yearlyGoal = TextEditingController();
  String? selectedAvatar;
  final storage = FirebaseStorage.instance;
  Reference get firebaseStorage => FirebaseStorage.instance.ref();

  Future<void> loadAvatars() async {
    List<String> urls = [];

    try {
      ListResult result = await firebaseStorage.child("avatars/").listAll();

      for (Reference ref in result.items) {
        final imageUrl = await ref.getDownloadURL();
        urls.add(imageUrl);
      }
    } catch (e) {
      //log('Error fetching avatar URLs: $e');
    }

    setState(() {
      avatarUrls = urls;
    });
  }

  @override
  void initState() {
    super.initState();
    avatarUrls = [];
    selectedAvatar = null;
    loadAvatars();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:  Color(0xFFFF997A),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height:MediaQuery.of(context).size.height/3,// Adjust the height as needed
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/EllipseAvatars.png'), // Replace with your image asset
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 70.0),
                    child: Text(
                      "Choose Your Avatar!!",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,fontFamily:'font',
                        color: Color(0xFF283E50),
                      ),
                    ),
                  ),
                  SizedBox(height: 20,),
                  avatarUrls.isEmpty
                      ? LoadingAnimationWidget.discreteCircle(
                        color: Color(0xFF283E50),
                        size: 60,
                        secondRingColor: Color(0xFFFF997A),
                        thirdRingColor:Color(0xFF686868),
                      ) : Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20.0,
                          mainAxisSpacing: 20.0,
                        ),
                        itemCount: avatarUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                            setState(() {
                                selectedAvatar = avatarUrls[index];
                                _avatarColor = selectedAvatar == avatarUrls[index] ? index % 2 == 0 ? Color(0xfffeead4): Color(0xFF283E50) : Colors.transparent;
                                //log(_avatarColor.toString());
                              });
                            },
                            child: Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index % 2 == 0 ? Color(0xfffeead4) : Color(0xFF283E50),
                                border: Border.all(
                                  color: selectedAvatar == avatarUrls[index] ? index % 2 == 0 ? Color(0xFF283E50) : Color(0xfffeead4) : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: CachedNetworkImage(
                                imageUrl: avatarUrls[index],
                                fit: BoxFit.scaleDown,
                                width: 40.0,
                                height: 40.0,
                                useOldImageOnUrlChange: false,
                                placeholder: (context, url) => CircularProgressIndicator(color:Color(0xFF283E50)),
                                errorWidget: (context, url, error) => Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedAvatar != null) {
                          _showPersistentBottomSheet(context);
                          //log('Selected Avatar Path: $selectedAvatar');
                        } else {
                          // Show a message if no avatar is selected
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please select an avatar.'),
                            ),
                          );
                        }



                      },
                      style: ElevatedButton.styleFrom(
                        primary: selectedAvatar != null ? Color(0xFF283E50) : Color(0xfffeead4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width /3,
                        height: 60,
                        child: Center(
                          child: Text(
                            'SAVE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedAvatar != null ? Color(0xfffeead4) : Color(0xFF283E50),
                              fontSize: 25,
                              fontFamily: 'font',
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
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Padding(
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

                      Text("Set Your Daily Goal!!!",style: TextStyle(fontSize: 30,   color: Color(0xFF686868),),),
                      SizedBox(height: 30,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Daily Goal in minutes",
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
                              controller: _dailyGoal,
                              decoration: InputDecoration(
                                hintText: 'time in minutes',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.lock_clock),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Yearly Goal for number of books",
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
                              controller: _yearlyGoal,
                              decoration: InputDecoration(
                                hintText: 'Number of books for this year',
                                border: InputBorder.none,
                                prefixIcon: Icon(Icons.lock_clock),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 50,),
                      ElevatedButton(
                        onPressed: () async{
                          Navigator.pop(context);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          _dailyGoal.text.isNotEmpty&&_yearlyGoal.text.isNotEmpty?
                          await _auth.SignUpWithEmailAndPassword(
                              context, widget._email!.text, widget._password!.text,widget._username!.text,selectedAvatar!,_dailyGoal.text,_avatarColor,int.parse(_yearlyGoal.text)):
                          Fluttertoast.showToast(msg: "Please enter both the values",backgroundColor: Color(0xff283E50),);
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
                              'SIGN UP',
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
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
