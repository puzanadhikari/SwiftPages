
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';


class ActivityList extends StatefulWidget {


  @override
  _ActivityListState createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  late Stream<List<Map<String, dynamic>>> activitiesStream;

  Stream<List<Map<String, dynamic>>> getActivitiesStream() {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('activity')
        .snapshots()
        .map((querySnapshot) {
      List<Map<String, dynamic>> activities = [];
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        activities.add(doc.data() as Map<String, dynamic>);
      }
      return activities;
    });
  }


  Future<void> deleteAllActivities() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    CollectionReference activityCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('activity');
    QuerySnapshot querySnapshot = await activityCollection.get();
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await activityCollection.doc(doc.id).delete();
    }
  }

  @override
  void initState() {
    super.initState();
    activitiesStream = getActivitiesStream();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
        child: Scaffold(
          backgroundColor:Color(0xfffeead4),
          body:Stack(
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
                      _showConfirmationDialog(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset('assets/delete.svg',
                        fit: BoxFit.cover,
                        height:30,
                        color:Color(0xFF283E50)
                      ),
                    ),
                  )
              ),

              Positioned(
                top: 20,
                left: MediaQuery.of(context).size.width / 3,
                child: Text(
                  "Notification",
                  style: const TextStyle(
                    fontFamily: "font",
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xfffeead4),
                    height: 29 / 22,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: activitiesStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color:Color(0xFF283E50),
                          size: 80,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    } else {
                      List<Map<String, dynamic>> activityList =
                          snapshot.data ?? [];

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height:MediaQuery.of(context).size.height/1.2 ,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(40.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(top:20.0,right: 8.0,left: 8.0,bottom: 4.0),
                            child: ListView.builder(
                              itemCount: activityList.length,
                              itemBuilder: (context, index) {
                                var activity = activityList[index];
                                final timeFormatter = DateFormat('hh:mm a');
                                return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20.0), // Adjust the radius as needed
                                    ),
                                    color: Color(0xFFFF997A),
                                    elevation: 8,
                                    margin: EdgeInsets.all(10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundImage: NetworkImage(activity['avatar'] ?? ''),
                                                      backgroundColor: Color(0xfffeead4),
                                                    ),
                                                    SizedBox(width: 5,),
                                                    Text("${activity['activityBy']}",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 16),),

                                                  ],
                                                ),
                                                SizedBox(width: 10),
                                                // Visibility(
                                                //     visible: activity['type'] ==
                                                //         'Liked' ||
                                                //         activity['type'] ==
                                                //             'Unliked'
                                                //         ? true
                                                //         : false,
                                                //     child: Icon(activity['type'] ==
                                                //         'Liked'
                                                //         ? Icons.thumb_up
                                                //         : Icons.thumb_down)),
                                                // Visibility(
                                                //   visible: activity['type'] ==
                                                //       'Comment'
                                                //       ? true
                                                //       : false,
                                                //   child: Icon(
                                                //       activity['type'] == 'Comment'
                                                //           ? Icons.comment
                                                //           : Icons.add),
                                                // ),
                                                // SizedBox(
                                                //   width: 10,
                                                // ),
                                                Visibility(
                                                    visible: activity['type'] ==
                                                        'Liked' ||
                                                        activity['type'] ==
                                                            'Unliked'
                                                        ? true
                                                        : false,
                                                    child: Text(
                                                        activity['type'] == 'Liked'
                                                            ? 'liked your post'
                                                            : 'disliked' +
                                                            ' your post',style: TextStyle(color:Colors.grey.shade700,fontFamily: 'font',fontSize: 12),)),
                                                Visibility(
                                                    visible: activity['type'] ==
                                                        'Comment'
                                                        ? true
                                                        : false,
                                                    child: Text(activity['type'] ==
                                                        'Comment'
                                                        ? 'commented your post'
                                                        : '',style: TextStyle(color:Colors.grey.shade700,fontFamily: 'font',fontSize: 12),)),
                                  ]),
                                          Text(  '${timeFormatter.format(activity['time'].toDate())}',style: TextStyle(color: Colors.grey.shade700,fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),),
                                        ],
                                      ),
                                ) );
                                //   Container(
                                //   decoration: ShapeDecoration(
                                //     color: Color(0xFFFF997A),
                                //     shape: RoundedRectangleBorder(
                                //       borderRadius: BorderRadius.circular(20),
                                //     ),
                                //   ),
                                //   child:  Padding(
                                //     padding: const EdgeInsets.all(8.0),
                                //     child: ListTile(
                                //       title: Text(activity['type'] ?? ''),
                                //       subtitle: Text(activity['activityBy'] ?? ''),
                                //       // Add other fields as needed
                                //     ),
                                //   ),
                                // );

                              },
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),








        ),
      ),
    );
  }
  void _showConfirmationDialog(context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            children: [
              Text(
                'Delete Notifications',
                style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
              ),
              Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ],
          ),
          content: Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(

              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Are you sure want to delete all the Notifications?",style: TextStyle(fontFamily: 'font',color: Colors.grey.shade700),)
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
                      decoration: BoxDecoration(
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
                        child: Text(
                          'No',
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
                      decoration: BoxDecoration(
                        color: Color(0xFF283E50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          deleteAllActivities();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Yes',
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
      },
    );
  }
}
