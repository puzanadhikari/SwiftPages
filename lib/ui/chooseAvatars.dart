import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../firebase_auth.dart';
import 'package:flutter_flip_clock/flutter_flip_clock.dart';
import 'package:from_to_time_picker/from_to_time_picker.dart';
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
        body: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                Positioned(
                  top: -10,
                  left: 0,
                  right: 0,
                  child: Container(
                    height:MediaQuery.of(context).size.height/3,// Adjust the height as needed
                   child: SvgPicture.asset(
                       "assets/ellipse12.svg",
                       fit: BoxFit.fill
                   ),
                    ),
                  ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Text(
                          "Choose Your Avatar!!",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,fontFamily:'font',
                            color: Color(0xFF283E50),
                          ),
                        ),
                      ),
                      SizedBox(height: 20,),
                      avatarUrls.isEmpty
                          ? Container(
                        height: MediaQuery.of(context).size.height/2,
                            child: Center(
                              child: LoadingAnimationWidget.discreteCircle(
                                color: Color(0xFF283E50),
                                size: 60,
                                secondRingColor: Color(0xFFFF997A),
                                thirdRingColor:Color(0xFF686868),
                              ),
                            ),
                          ) : Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: GridView.builder(
                            physics:NeverScrollableScrollPhysics() ,
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
                                    width: 30.0,
                                    height: 30.0,
                                    useOldImageOnUrlChange: false,
                                    placeholder: (context, url) => CircularProgressIndicator(color:Colors.transparent),
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
                        padding: const EdgeInsets.only(bottom: 80.0),
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
                            width: MediaQuery.of(context).size.width /4,
                            height: 45,
                            child: Center(
                              child: Text(
                                'SAVE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: selectedAvatar != null ? Color(0xfffeead4) : Color(0xFF283E50),
                                  fontSize: 23,
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
        ),
      ),
    );
  }
  void _showPersistentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Color(0xFF283E50),
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Choose Your reading\nGoals",textAlign:TextAlign.center,style: TextStyle(fontSize: 30, color: Color(0xFFFEEAD4),fontFamily:'font',),),
                  Text("You can later change it in the settings!!!",textAlign:TextAlign.center,style: TextStyle(fontSize: 15, color: Color(0xFFD9D9D9),fontFamily:'font',),),
                  SizedBox(height: 30,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily Goal",
                        style: TextStyle(
                          fontSize:14,
                          fontWeight: FontWeight.bold,fontFamily:'font',
                          color:  Color(0xFFD9D9D9),
                        ),
                      ),
                      SizedBox(height: 5,),
                      GestureDetector(
                        onTap: (){
                          showDialog(
                            context: context,
                            builder: (_) => FromToTimePicker(
                              onTab: (from, to) {
                                print('from $from to $to');
                              },
                              dialogBackgroundColor: Color(0xFF121212),
                              fromHeadlineColor: Colors.white,
                              toHeadlineColor: Colors.white,
                              upIconColor: Colors.white,
                              downIconColor: Colors.white,
                              timeBoxColor: Color(0xFF1E1E1E),
                              timeHintColor: Colors.grey,
                              timeTextColor: Colors.white,
                              dividerColor: Color(0xFF121212),
                              doneTextColor: Colors.white,
                              dismissTextColor: Colors.white,
                              defaultDayNightColor: Color(0xFF1E1E1E),
                              defaultDayNightTextColor: Colors.white,
                              colonColor: Colors.white,
                              showHeaderBullet: true,
                              headerText: 'Time available from 01:00 AM to 11:00 PM',
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.0),
                            color: Color(0xFFD9D9D9),
                          ),
                          child: Text("Select the time")
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Reading Goals",
                        style: TextStyle(
                          fontSize:14,
                          fontWeight: FontWeight.bold,fontFamily:'font',
                          color:  Color(0xFFD9D9D9),

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
        );
      },
    );
  }
}
