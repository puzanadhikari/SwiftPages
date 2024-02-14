import 'dart:developer';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../homePage.dart';
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
  int completedLength=0;

  Map<String, int> moodCounts = {};
  Map<String, int> genreCounts = {};
  int currentYear = 0;
  int startYear = 2019;
  List<int> years = [];

  double ratingTotal =0.0;
  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    currentYear = now.year;
    years = List<int>.generate(currentYear - startYear + 1, (index) => startYear + index);

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
  double mediumPaceCountPer = 0;
  double fastPaceCountPer = 0;
  double slowPaceCountPer = 0;
  double finalRating = 0;
  int __selectedYear =0;
  Future<void> fetchBooksForPace() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;
        moodCounts.clear();

        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        QuerySnapshot querySnapshotMyReads=__selectedYear==0? await myBooksRef.where('status', isEqualTo: 'COMPLETED').get():await myBooksRef.where('status', isEqualTo: 'COMPLETED').where('year',isEqualTo:__selectedYear).get();


        List<DocumentSnapshot> bookDocumentsMyReads = querySnapshotMyReads.docs;


        setState(() {
          myBooksMyReads = bookDocumentsMyReads
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();
        });
        
        mediumPaceCount = 0;
        fastPaceCount = 0;
        slowPaceCount = 0;
        ratingTotal = 0.0;
        completedLength = bookDocumentsMyReads.length;

        if (completedLength > 0) {
          for (var doc in bookDocumentsMyReads) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

            if (data.containsKey('reviews')) {
              List<dynamic> reviews = data['reviews'];

              for (var review in reviews) {
                if (review.containsKey('pace')) {
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

                if (review.containsKey('rating')) {
                  double rating = review['rating'];
                  ratingTotal += rating;
                }
                if (review.containsKey('mood')) {
                  String mood = review['mood'];
                  moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
                }
                if (review.containsKey('genre')) {
                  String genre = review['genre'];
                  genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
                }
              }
            }
          }

          setState(() {
            mediumPaceCountPer = (mediumPaceCount / completedLength) * 100;
            fastPaceCountPer = (fastPaceCount / completedLength) * 100;
            slowPaceCountPer = (slowPaceCount / completedLength) * 100;

            finalRating = ratingTotal / completedLength;
          });
        }
      }
    } catch (e) {
      print('Error fetching books for pace: $e');
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




        QuerySnapshot querySnapshotMyReads=__selectedYear==0? await myBooksRef.where('status', isEqualTo: 'COMPLETED').get():await myBooksRef.where('status', isEqualTo: 'COMPLETED').where('year',isEqualTo:__selectedYear).get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsMyReads = querySnapshotMyReads.docs;
        setState(() {
          completedLength=querySnapshotMyReads.docs.length;
         completedLength ==''?'': calculate();
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

  double percentage = 10.0;
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

        });

        int totalHours = totalTimeMin ~/ 60; // Convert total minutes to total hours
        int additionalMinutes = totalTimeMin % 60; // Get the remaining minutes
        int remainingSeconds = totalTimeSec % 60; // Get the remaining seconds

        updatedTime = '$totalHours:${additionalMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
      }
    } catch (error) {
      print('Error fetching data second: $error');
    }
  }

  void calculate() {
    if (yearlyGoal != 0) {
      percentage = (completedLength / yearlyGoal) * 100;
      //log(percentage.toString());
    } else {
      percentage = 0; // or any other default value you prefer
      //log("Yearly goal is zero");
    }
  }

  final _random = Random();
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
                      top: 130,
                      left: 40,
                      child: Container(
                        height: 150,
                        width: MediaQuery.of(context).size.width/1.2,

                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                "Reading Stats",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xff283E50),
                                    fontSize: 30,fontFamily: 'font',
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              SizedBox(height: 20,),
                              Text(
                                "You are viewing the stats for the year",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 16,fontFamily: 'font',
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              SizedBox(height: 15,),
                              Padding(
                                padding: const EdgeInsets.only(left:50.0,right: 50),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  color: Color(0xFFFF997A),
                                  elevation: 8,
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      hint: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(__selectedYear==0?"Select year":__selectedYear.toString(),style: TextStyle(color: Color(0xff283E50)),),
                                      ),
                                      onChanged: (int? newValue) {
                                        setState(() {
                                           totalTimeMin=0;
                                           totalTimeSec=0;
                                           mediumPaceCount = 0;
                                           fastPaceCount = 0;
                                           slowPaceCount = 0;
                                           mediumPaceCountPer = 0;
                                           fastPaceCountPer = 0;
                                           slowPaceCountPer = 0;
                                           finalRating = 0;
                                           __selectedYear =0;
                                         moodCounts = {};
                                        genreCounts = {};
                                          __selectedYear = newValue!;
                                          fetchBooksForPace();
                                          fetchBooks();
                                        });
                                      },
                                      icon: Icon(Icons.add,color: Color(0xFFFF997A),),
                                      
                                      items: years.map<DropdownMenuItem<int>>((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(value.toString()),
                                        );
                                      }).toSet().toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                                              child: Text(completedLength.toString(),  style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,fontFamily: 'font',
                                                  fontWeight: FontWeight.bold
                                              )),
                                            ),
                                            Text(
                                              "Books",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,fontFamily: 'font',
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
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 30,
                                              backgroundColor: Color(0xffD9D9D9),
                                              child: Text(finalRating.toStringAsFixed(1)+'/5',  style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,fontFamily: 'font',
                                                  fontWeight: FontWeight.bold
                                              ),),
                                            ),
                                            Text(
                                              "Ratings",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xffD9D9D9),
                                                  fontSize: 14,fontFamily: 'font',
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
                                                  fontWeight: FontWeight.bold,
                                           fontFamily: 'font',
                                              ),),
                                            ),
                                            Text(
                                              "Time",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  color: Color(0xff283E50),
                                                  fontSize: 14,fontFamily: 'font',
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
                                        "Yearly Book Goals",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Color(0xff283E50),
                                            fontSize: 20,fontFamily: 'font',
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
                                                fontWeight: FontWeight.bold,fontFamily:'font',
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
              Padding(
                padding: const EdgeInsets.only(top:30,left: 30.0,right: 30),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  // height: MediaQuery.of(context).size.height/4,
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
                                fontSize: 20,fontFamily: 'font',
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top:20,left: 30.0,right: 30,bottom: 30),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Color(0xFFFF997A),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(mediumPaceCountPer.toStringAsFixed(2)+'%',style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),),
                                    Text("Medium",style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 14),),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:  EdgeInsets.only(top:40.0),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Color(0xff283E50),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(fastPaceCountPer.toStringAsFixed(2)+'%',style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),),
                                      Text("Fast",style: TextStyle(color: Color(0xffFEEAD4),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 13),),
                                    ],
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 30,
                                backgroundColor:Color(0xffFEEAD4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(slowPaceCountPer.toStringAsFixed(2)+'%',style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),),
                                      Text("Slow",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 13),),
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
              ),
              Visibility(
                visible: genreCounts.isEmpty?false:true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, left: 30.0, right: 30),
                  child: Container(
                    height:MediaQuery.of(context).size.height/2.8,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Color(0xffD9D9D9),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Genre",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xff283E50),
                              fontSize: 20,
                              fontFamily: 'font',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height/3.5 ,
                          child: AspectRatio(
                            aspectRatio:1.5,
                            child: PieChart(
                              PieChartData(
                                sections: genreCounts.entries.map((entry) {
                                  String genre = entry.key;
                                  int count = entry.value;

                                  return PieChartSectionData(
                                    color: _getNextColor(), // Use the next color from the list
                                    value: (count / completedLength).toDouble(),
                                    title: '$genre\n${((count / completedLength) * 100).toStringAsFixed(2)}%',
                                    titleStyle: TextStyle(fontFamily: 'font'),
                                    radius: 70,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: moodCounts.isEmpty?false:true,
                child: Padding(
                  padding: const EdgeInsets.only(top:30,left: 30.0,right: 30),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
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
                              "Mood",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xff283E50),
                                  fontSize: 20,fontFamily: 'font',
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20, left: 30.0, right: 30),
                            child: Column(
                              children: List.generate((moodCounts.length / 3).ceil(), (index) {
                                int startIndex = index * 3;
                                int endIndex = startIndex + 3;

                                // Ensure endIndex does not exceed the length of the moodCounts list
                                endIndex = endIndex > moodCounts.length ? moodCounts.length : endIndex;

                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: moodCounts.entries.toList().sublist(startIndex, endIndex).map((entry) {
                                    String mood = entry.key;
                                    int count = entry.value;

                                    // Calculate radius based on percentage
                                    double radius = (count / completedLength) * 10 + 30; // Adjust the scaling factor 50 as needed

                                    // Determine the color based on the index
                                    Color backgroundColor = moodCounts.keys.toList().indexOf(mood).isOdd ? Color(0xff283E50) : Color(0xFFFF997A);

                                    return CircleAvatar(
                                      radius: radius,
                                      backgroundColor: backgroundColor,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${((count / completedLength) * 100).toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              color: Color(0xFFD9D9D9),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'font',
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            mood,
                                            style: TextStyle(
                                              color: Color(0xFFD9D9D9),
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'font',
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              }),
                            ),
                          ),





                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  int _colorIndex = 0;

  Color _getNextColor() {
    List<Color> colors = [
      Color(0xFFE57373),
      Color(0xFFFF8A65),
      Color(0xFFFFD54F),
      Color(0xFFAED581),
      Color(0xFF64B5F6),
      Color(0xFF9575CD),
      Color(0xFFFFD700),
      // Add more colors as needed
    ];

    Color nextColor = colors[_colorIndex % colors.length];
    _colorIndex++;
    return nextColor;
  }

  Color _getRandomColor() {
    return Color((0xFF000000 & 0xFFFFFF) | _random.nextInt(0xFFFFFF));
  }
}






