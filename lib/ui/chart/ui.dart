import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../myBooks.dart';

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
  @override
  void initState() {
    super.initState();
    fetchData();
    fetchBooks();
  }
  String _formatTimestamp(Timestamp timestamp) {
     dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime!); // Format the timestamp as per your requirement
  }
  int totalTimeMin=0;
  int totalTimeSec=0;
  Future fetchBooks() async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to fetch books
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Fetch books with status 'CURRENTLY READING'
        QuerySnapshot querySnapshot = await myBooksRef.where('status', isEqualTo: 'CURRENTLY READING').get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocuments = querySnapshot.docs;
        setState(() {
          myBooks = bookDocuments
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();
          // print('Books: $myBooks'); // Check the console for the list of books
        });

        QuerySnapshot querySnapshotMyReads = await myBooksRef.where('status', isEqualTo: 'COMPLETED').get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsMyReads = querySnapshotMyReads.docs;
        setState(() {
          myBooksMyReads = bookDocumentsMyReads
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();
          // print('Books: $myBooksMyReads'); // Check the console for the list of books
        });


        QuerySnapshot querySnapshotToBeRead = await myBooksRef.where('status', isEqualTo: 'TO BE READ').get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsToBeRead = querySnapshotToBeRead.docs;
        setState(() {
          myBooksToBeRead = bookDocumentsToBeRead
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();
          // print('Books: $myBooksToBeRead'); // Check the console for the list of books
        });

        for (DocumentSnapshot doc in bookDocumentsToBeRead) {
          Map<String, dynamic> bookData = doc.data() as Map<String, dynamic>;

          // Print or use the fetched book data
          // log('Book: $bookData');





        }
      } else {
        // print('No user is currently signed in.');
      }
    } catch (e) {
      // print('Error fetching books: $e');
    }
  }
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
      setState(() {
        lastStrikeTime = userDoc.get('lastStrikeTimestamp') ?? 0;
        lastStreak =  userDoc.get("lastStrike")??0;
        streak =  userDoc.get("strikes")??0;
      });
        int additionalMinutes = totalTimeSec ~/ 60; // Get the whole minutes part
        int remainingSeconds = totalTimeSec % 60; // Get the remaining seconds

        totalTimeMin += additionalMinutes;

         updatedTime = '$totalTimeMin:${remainingSeconds.toString().padLeft(2, '0')}';

        _formatTimestamp(lastStrikeTime!);
        setState(() {
          pieChartItems = [
            PieChartSectionData(
              color: Colors.blue,
              value: double.parse(dailyGoal),
              title: 'Daily Goal ${double.parse(dailyGoal)}',
              radius: 70,
              titleStyle: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff)),
            ),
            PieChartSectionData(
              color: Colors.green,
              value: currentTime.toDouble(),
              title: 'Current Time${currentTime}',
              radius: 70,
              titleStyle: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff)),
            ),
            PieChartSectionData(
              color: Colors.red,
              value: totalTimeMin * 60 + totalTimeSec.toDouble(),
              title: 'Total${totalTimeMin * 60 + totalTimeSec.toDouble()}',
              radius: 70,
              titleStyle: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff)),
            ),
          ];
        });
      }
    } catch (error) {
      log('Error fetching data: $error');
    }
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
              top: 300,
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
                                      child: Text(myBooksMyReads.length.toString(),  style: TextStyle(
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
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Color(0xffD9D9D9),
                                  child: Text(updatedTime,  style: TextStyle(
                                      color: Color(0xff283E50),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold
                                  ),),
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
                      height: 200,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Color(0xffD9D9D9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                        ],
                      ),

                    ),
                  )
                ],
              )
            ),
      //   Padding(
      //   padding: const EdgeInsets.all(16.0),
      //   child: PieChart(
      //     PieChartData(
      //       sectionsSpace: 0,
      //       centerSpaceRadius: 80,
      //       sections: pieChartItems,
      //       borderData: FlBorderData(
      //         show: false,
      //       ),
      //     ),
      //   ),
      // ),
          ],
        ),
      ),
    );
  }
}

//       Scaffold(
//       appBar: AppBar(
//         title: Text('Graph Page'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: PieChart(
//           PieChartData(
//             sectionsSpace: 0,
//             centerSpaceRadius: 80,
//             sections: pieChartItems,
//             borderData: FlBorderData(
//               show: false,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
