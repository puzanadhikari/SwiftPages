
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
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
          backgroundColor: Color(0xffD9D9D9),
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

                      deleteAllActivities();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20.0),),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(Icons.delete_forever,color: Colors.red,),
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

                      return ListView.builder(
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
                                                  ? ' liked your post'
                                                  : ' disliked' +
                                                  ' your post',style: TextStyle(color: Color(0xff283E50),fontFamily: 'font',),)),
                                      Visibility(
                                          visible: activity['type'] ==
                                              'Comment'
                                              ? true
                                              : false,
                                          child: Text(activity['type'] ==
                                              'Comment'
                                              ? ' commented your post'
                                              : '',style: TextStyle(color: Color(0xff283E50),fontFamily: 'font',),)),
                                      Text(  '${timeFormatter.format(activity['time'].toDate())}',style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),),
                            ]),
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
}
