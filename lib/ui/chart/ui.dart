import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../myBooks.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
class GraphPage extends StatefulWidget {
  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PieChartSectionData> pieChartItems = [];
  Timestamp? lastStrikeTime ;
  DateTime? dateTime;
  int? lastStreak;
  int? streak;
  List<DetailBook> myBooks = [];
  List<DetailBook> myBooksToBeRead = [];
  List<DetailBook> myBooksMyReads = [];
  String updatedTime='';
  String completedLength='';
  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchData();
    fetchBooksForPace();
    setState(() {

    });

  }
  String _formatTimestamp(Timestamp timestamp) {
     dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime!); // Format the timestamp as per your requirement
  }
  int totalTimeMin=0;
  int totalTimeSec=0;
  int mediumPaceCount = 0;
  int fastPaceCount = 0;
  int slowPaceCount = 0;
  Future<void> fetchBooksForPace() async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to fetch books
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        QuerySnapshot querySnapshotMyReads = await myBooksRef.where('status', isEqualTo: 'COMPLETED').get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsMyReads = querySnapshotMyReads.docs;
         mediumPaceCount = 0;
         fastPaceCount = 0;
         slowPaceCount = 0;

        setState(() {
          // completedLength = querySnapshotMyReads.docs.length.toString();

          myBooksMyReads = bookDocumentsMyReads
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();


          // Iterate through each book document to check reviews and pace
          for (var doc in bookDocumentsMyReads) {
            // Access the data of the document
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            // Check if the document has a 'reviews' array
            if (data.containsKey('reviews')) {

              // Access the 'reviews' array
              List<dynamic> reviews = data['reviews'];

              // Iterate through each review
              for (var review in reviews) {

                // Check if the review has a 'pace' value
                if (review.containsKey('pace')) {
                  // Increment the corresponding pace count based on the 'pace' value
                  switch (review['pace']) {
                    case 'Medium':
                      mediumPaceCount++;
                      break;
                    case 'Fast':
                      fastPaceCount++;
                      break;
                    case 'Slow':
                      slowPaceCount++;
                      break;
                  }
                }
              }
            }
          }
        });

      }
    } catch (e) {
      print('Error fetching books: $e');
    }
  }

  Future fetchBooks() async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to fetch books
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');




        QuerySnapshot querySnapshotMyReads = await myBooksRef.where('status', isEqualTo: 'COMPLETED').get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsMyReads = querySnapshotMyReads.docs;
        setState(() {
          completedLength=querySnapshotMyReads.docs.length.toString();
          calculate();
          myBooksMyReads = bookDocumentsMyReads
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, double>?)) // Use Map<String, dynamic>
              .toList();


        });


      } else {
        // print('No user is currently signed in.');
      }
    } catch (e) {
      // print('Error fetching books: $e');
    }
  }
  int yearlyGoal=0;
  double percentage = 0;
  Future<void> fetchData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

      if (userDoc.exists) {
        String dailyGoal = userDoc.get('dailyGoal') ?? '0';
        int currentTime = userDoc.get('currentTime') ?? 0;
        totalTimeMin = userDoc.get('totalTimeMin') ?? 0;
        totalTimeSec = userDoc.get('totalTimeSec') ?? 0;
        print(totalTimeMin+totalTimeSec);
        setState(() {
          lastStrikeTime = userDoc.get('lastStrikeTimestamp') ?? 0;
          lastStreak = userDoc.get("lastStrike") ?? 0;
          streak = userDoc.get("strikes") ?? 0;
          yearlyGoal = userDoc.get('yearlyGoal') ?? 0;
        });

        int totalHours = totalTimeMin ~/ 60; // Convert total minutes to total hours
        int additionalMinutes = totalTimeMin % 60; // Get the remaining minutes
        int remainingSeconds = totalTimeSec % 60; // Get the remaining seconds

        updatedTime = '$totalHours:${additionalMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  void calculate(){
    percentage = ((double.parse(completedLength))/yearlyGoal)*100;
    log(percentage.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEEAD4),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height/1.4,
                child: Stack(
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
                      left: MediaQuery
                          .of(context)
                          .size
                          .width / 2.5,
                      child: const Text(
                        "My Stats",
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
                      top: 130,
                      left: 40,
                      child: Container(
                        height: 100,
                        width: MediaQuery.of(context).size.width/1.2,

                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding:
                            const EdgeInsets.all( 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 5,),
                                Text(
                                  "Last Streak History",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Color(0xff283E50),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                const SizedBox(height: 5,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          "assets/strick.png",
                                          height: 50,
                                          color: Color(0xff283E50),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${DateTime.now().toLocal().toString().split(' ')[0]}',
                                              style: TextStyle(fontSize: 16,   color: Color(0xff283E50),),
                                            ),
                                            Text(
                                              '${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5)}',
                                              style: TextStyle(fontSize: 16,   color: Color(0xff283E50),),
                                            ),
                                          ],
                                        ),

                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                   'Last Streak: '+ lastStreak.toString(),
                                          style: TextStyle(fontSize: 16,   color: Color(0xff283E50),),
                                        ),
                                        Text(
                                          'Current Streak: '+ streak.toString(),
                                          style: TextStyle(fontSize: 16,   color: Color(0xff283E50),),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 250,
                      left: 40,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Container(
                              height: 300,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 200,
                                    // width:/,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF997A),
                                      borderRadius: BorderRadius.circular(100.0),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.all( 10.0),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Color(0xffD9D9D9),
                                              child: Text(completedLength.toString(),  style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold
                                              )),
                                            ),
                                            Text(
                                              "Books",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20,),
                                  Container(
                                    height: 200,
                                    // width:/,

                                    decoration: BoxDecoration(
                                      color: const Color(0xFF283E50),
                                      borderRadius: BorderRadius.circular(100.0),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.all( 10.0),
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundColor: Color(0xffD9D9D9),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20,),
                                  Container(
                                    height: 200,
                                    // width:/,

                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF997A),
                                      borderRadius: BorderRadius.circular(100.0),
                                    ),
                                    child: SingleChildScrollView(
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.all( 10.0),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Color(0xffD9D9D9),
                                              child: Text(updatedTime,  style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold
                                              ),),
                                            ),
                                            Text(
                                              "Time",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 100,
                            child: Container(
                              width: 300,
                              height: MediaQuery.of(context).size.height/4,
                              decoration: BoxDecoration(
                                color: Color(0xffD9D9D9),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "Reading Stats",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Color(0xff283E50),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 160.0, // Adjust the width and height for desired size
                                      height: 160.0,
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: Container(
                                              height:120,
                                              width: 120,
                                              child: CircularProgressIndicator(
                                                value: percentage/100,
                                                backgroundColor: Colors.grey,
                                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff283E50)),
                                                strokeWidth: 10.0, // Adjust the strokeWidth for desired size
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Text(
                                              '${(percentage).toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                fontSize: 24.0, // Adjust the font size for desired size
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 10,),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),



                        ],
                      )
                    ),

                  ],
                ),
              ),
              Container(
                width: 300,
                height: MediaQuery.of(context).size.height/4,
                decoration: BoxDecoration(
                  color: Color(0xffD9D9D9),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,

                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Book Pace",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xff283E50),
                              fontSize: 20,
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:20,left: 30.0,right: 30),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Color(0xFFFF997A),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(mediumPaceCount.toString(),style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontSize: 12),),
                                  Text("Medium",style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontSize: 14),),
                                ],
                              ),
                            ),
                            Padding(
                              padding:  EdgeInsets.only(top:40.0),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Color(0xff283E50),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(fastPaceCount.toString(),style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontSize: 14),),
                                    Text("Fast",style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontSize: 14),),
                                  ],
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor:Color(0xffFEEAD4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(slowPaceCount.toString(),style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontSize: 14),),
                                    Text("Slow",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontSize: 14),),
                                  ],
                                ),
                            ),
                          ],
                        ),
                      )


                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

}






