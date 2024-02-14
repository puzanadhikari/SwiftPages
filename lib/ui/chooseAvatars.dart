import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController hour = TextEditingController();
  final TextEditingController minute = TextEditingController();
  String? selectedAvatar;
  final storage = FirebaseStorage.instance;
  Reference get firebaseStorage => FirebaseStorage.instance.ref();
  String clock='';
  int selectedNumber = 0;
  Future<void> loadAvatars() async {
    List<String> urls = [];

    try {
      ListResult result = await firebaseStorage.child("avatars/").listAll();
      clock =await firebaseStorage.child("assets/Group 60.svg").getDownloadURL();

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double height=50;

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
                              log(clock);
                              _showPersistentBottomSheet(context);
                            } else {
                              Fluttertoast.showToast(msg:'Please select an avatar.',backgroundColor: Color(0xFF283E50));
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
  Future<int> getSelectedNumber() async {
    // Simulating an asynchronous operation, replace this with your actual logic
    await Future.delayed(Duration(seconds: 1));
    return selectedNumber;
  }
  void _showPersistentBottomSheet(BuildContext context) {
    int hourValue = 0;
    int minuteValue = 0;
    showModalBottomSheet(
      backgroundColor: Color(0xFF283E50),
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
                padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,),
              child: SizedBox(
                height: MediaQuery.of(context).size.height/1.8 ,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Choose Your reading\nGoals!!",textAlign:TextAlign.center,style: TextStyle(fontSize: 30, color: Color(0xFFFF997A),fontFamily:'font',),),
                        Text("You can later change it in the settings!!!",textAlign:TextAlign.center,style: TextStyle(fontSize: 15, color: Color(0xFFD9D9D9),fontFamily:'font',),),
                        SizedBox(height: 30,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Daily Goal",
                              style: TextStyle(
                                fontSize:18,
                                fontWeight: FontWeight.bold,fontFamily:'font',
                                color:  Color(0xFFFF997A),
                              ),
                            ),
                            SizedBox(height: 20,),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: height,
                                  width: 50,
                                  child: TextFormField(
                                    style: TextStyle(fontFamily: 'font',color:Colors.grey[700],fontSize: 13 ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        setState(() {
                                          height=70;
                                          hourValue = int.tryParse(value!) ?? 0;
                                        });
                                        return 'Please Enter Your hour';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // Parse the hour value
                                        hourValue = int.tryParse(value) ?? 0;
                                      });
                                    },
                                    controller: hour,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(

                                        hintText: '00',
                                        hintStyle: TextStyle(
                                            fontSize: 12,
                                            fontFamily: "font",
                                            color: Color(0xff686868).withOpacity(0.5)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor:  Color(0xFFD9D9D9),
                                        errorStyle: TextStyle(color: Colors.grey[700],fontSize: 8,fontFamily: "font",)
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5,),
                                Text(':',style: TextStyle(color: Color(0xFFD9D9D9),),),
                                SizedBox(width: 5,),
                                Container(
                                  height: height,
                                  width: 50,
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(fontFamily: 'font',color:Colors.grey[700],fontSize: 13 ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        setState(() {
                                          height=70;
                                          minuteValue = int.tryParse(value!) ?? 0;
                                          log(minuteValue.toString());
                                        });
                                        return 'Please Enter Your minute';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      setState(() {
                                        // Parse the minute value
                                        minuteValue = int.tryParse(value) ?? 0;
                                      });
                                    },
                                    onEditingComplete: () {

                                      int totalMinutes = hourValue * 60 + minuteValue;
                                      print('Total minutes: $totalMinutes');
                                    },
                                    controller: minute,

                                    decoration: InputDecoration(
                                        hintText: '00',
                                        hintStyle: TextStyle(
                                            fontSize: 12,
                                            fontFamily: "font",
                                            color: Color(0xff686868).withOpacity(0.5)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8.0),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor:  Color(0xFFD9D9D9),
                                        errorStyle: TextStyle(color: Colors.grey[700],fontSize: 8,fontFamily: "font",)
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // GestureDetector(
                            //     onTap: (){
                            //       showDialog(
                            //         context: context,
                            //         builder: (_) => FromToTimePicker(
                            //           onTab: (from, to) {
                            //             print('from $from to $to');
                            //           },
                            //           dialogBackgroundColor: Color(0xffFEEAD4),
                            //           fromHeadlineColor: Colors.white,
                            //           toHeadlineColor: Colors.white,
                            //           upIconColor: Colors.white,
                            //           downIconColor: Colors.white,
                            //           timeBoxColor: Color(0xFF1E1E1E),
                            //           timeHintColor: Colors.grey,
                            //           timeTextColor: Colors.white,
                            //           dividerColor: Color(0xFF121212),
                            //           doneTextColor: Colors.white,
                            //           dismissTextColor: Colors.white,
                            //           defaultDayNightColor: Color(0xFF1E1E1E),
                            //           defaultDayNightTextColor: Colors.white,
                            //           colonColor: Colors.white,
                            //           showHeaderBullet: true,
                            //           headerText: 'Time available from 01:00 AM to 11:00 PM',
                            //           headerTextColor: Colors.black,
                            //         ),
                            //       );
                            //     },
                            //     child: clock==''?Text(''):SvgPicture.network(clock)
                            // ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Reading Goals",
                              style: TextStyle(
                                fontSize:18,
                                fontWeight: FontWeight.bold,fontFamily:'font',
                                color:  Color(0xFFFF997A),
                              ),
                            ),
                            SizedBox(height: 5,),

                            SizedBox(
                              height: 50,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 200,
                                  itemBuilder: (BuildContext context, int index) {
                                    int number = index + 1;
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedNumber = number;
                                        });
                                      },
                                      child: Container(
                                        width: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: number == selectedNumber
                                                ?  Color(0xffFEEAD4)
                                                : Colors.transparent,
                                            width: 2.0,
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$number',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,fontFamily:'font',color: Color(0xffFEEAD4)
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20,),
                        ElevatedButton(
                          onPressed: () async{
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.pop(context);
                            int totalMinutes = hourValue * 60 + minuteValue;
                            log(totalMinutes.toString());
                            hour!=0||minute!=0?
                            await _auth.SignUpWithEmailAndPassword(
                                context, widget._email!.text, widget._password!.text,widget._username!.text,selectedAvatar!,totalMinutes,_avatarColor,selectedNumber):
                            Fluttertoast.showToast(msg: "Please enter both the values",backgroundColor: Color(0xff283E50),);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color(0xFFFF997A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
            );
          },
        );
      },
    );
  }

}
