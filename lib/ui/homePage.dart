import 'dart:convert';
import 'dart:developer';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftpages/ui/choosePage.dart';
import 'package:swiftpages/ui/myBooks/detailPage.dart';
import 'package:swiftpages/ui/timerPage/ui.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../signUpPage.dart';
import 'books/allBooks.dart';
import 'books/detailEachForBookStatus.dart';
import 'myBooks.dart';
int currentTimeCount = 0;
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late Stream<List<String>> textDataStream;
  final GlobalKey timeKey = GlobalKey();
  final GlobalKey readKey = GlobalKey();
  final GlobalKey moreKey = GlobalKey();
  final GlobalKey streakRowKey = GlobalKey();
  TutorialCoachMark? tutorialCoachMark;
  late bool _isRunning;
  List<TargetFocus> targets= [];
  final String apiKey =
      "30fe2ae32emsh0b5a48e1d0ed53dp17a064jsn7a2f3e3aca01";
  final String apiUrl =
      "https://book-finder1.p.rapidapi.com/api/search?page=2";
  int strikesCount = 0;
  int totalTimeMin=0;
  int totalTimeSec=0;
  int yearlyGoal=0;
  int _currentIndex = 0;
  Future<void> fetchBooksFromGoogle() async {
    final String apiKey = "AIzaSyBmb7AmvBdsQsQwLD1uTEuwTQqfDJm7DN0";
    final String apiUrl =
        "https://www.googleapis.com/books/v1/volumes?q=novels&maxResults=5";

    final response = await http.get(Uri.parse(apiUrl + "&key=$apiKey"));

    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey("items")) {
        final List<dynamic> items = data["items"];
        setState(() {
          books = items.map((item) => Book.fromMap(item)).toList();

        });
      }
    } else {
      // Handle errors
      // print("Error: ${response.statusCode}");
    }
  }
  String twoDigitMinutes='';
  String twoDigitSeconds='';
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> fetchData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

      if (userDoc.exists) {
        setState(() {
          totalTimeMin = userDoc.get('totalTimeMin') ?? 0;
          totalTimeSec = userDoc.get('totalTimeSec') ?? 0;
          yearlyGoal = userDoc.get('yearlyGoal') ?? 0;
        });
      }
    } catch (error) {
      log('Error fetching data: $error');
    }
  }

  Future<void> fetchStrikes() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

        strikesCount = userDoc.data()?.containsKey('strikes') ?? false
            ? userDoc.get('strikes')
            : 0;
        currentTimeCount = userDoc.data()?.containsKey('currentTime') ?? false
            ? userDoc.get('currentTime')
            : 0;
        // log(currentTimeCount.toString());
        setState(() {});
      }
    } catch (e) {
      print('Error fetching strikes: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    // log(twoDigitMinutes.toString()+twoDigitSeconds);
    return '$twoDigitMinutes:$twoDigitSeconds';
  }
  void saveMyBook(String author, String image,String description) async {
    try {

      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to associate books with the user
        String uid = user.uid;
        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        QuerySnapshot existingBooks = await myBooksRef
            .where('author', isEqualTo: author)
            .where('image', isEqualTo: image)
            .get();

        if (existingBooks.docs.isEmpty) {
          // Book does not exist, add it to the collection
          Map<String, dynamic> bookData = {
            'image': image,
            'author': author,
            'description':description
            // Add other book details as needed
          };
          fetchBooks();
          // Add the book data to the 'myBooks' collection
          await myBooksRef.add(bookData);

          Fluttertoast.showToast(msg: "Book saved successfully!");
        } else {
          Fluttertoast.showToast(msg: "Book already exists!");
        }
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error saving book: $e');
    }
  }

  List<Book> books = [];

  List<DetailBook> myBooks = [];
  List<DetailBook> myBooksToBeRead = [];
  List<DetailBook> myBooksMyReads = [];

  String email = ' ';
  String userName = ' ';
  String dailyGoal = ' ';
  int finalTime=0;
  int _duration = 0;
  Future<void> _retrieveStoredTime() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        String storedTime = userDoc.get('dailyGoal') ?? 0;
        setState(() {
          // _duration = storedTime;
          dailyGoal = storedTime;
        });
        // if (_duration > 0) {
        //   _controller.resume();
        // }
      }
    } catch (error) {
      print('Error retrieving stored time: $error');
    }
  }
  Future<void> _retrieveStoredTimeDetail() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        int storedTime = userDoc.get('currentTime') ?? 0;
        String storedTime2 = userDoc.get('dailyGoal') ?? 0;
        setState(() {
          // _duration = storedTime;
          currentTime = storedTime;
          _duration = int.parse(storedTime2);
          finalTime = currentTime==0? _duration * 60 :currentTime;

        });
        // if (_duration > 0) {
        //   _controller.resume();
        // }
      }
    } catch (error) {
      print('Error retrieving stored time: $error');
    }
  }
  // Future<void> fetchBooks() async {
  //   final response = await http.get(
  //     Uri.parse(apiUrl),
  //     headers: {
  //       "X-RapidAPI-Key": apiKey,
  //     },
  //   );
  //
  //   if (response.statusCode == 200) {
  //     final Map<String, dynamic> data = json.decode(response.body);
  //
  //     if (data.containsKey("results")) {
  //       final List<dynamic> results = data["results"];
  //       log(results.toString());
  //       // Fetch only the first 5 books
  //       List<dynamic> firstFiveBooks = results.take(5).toList();
  //
  //       setState(() {
  //         books = firstFiveBooks.map((result) => Book.fromMap(result)).toList();
  //       });
  //     } else {
  //       print("Error: 'results' key not found in the response");
  //     }
  //   } else {
  //     // Handle errors
  //     print("Error: ${response.statusCode}");
  //   }
  // }
  TextEditingController _currentPage = TextEditingController();
  final CountdownController _controller = CountdownController(autoStart: false);
  final CountdownController _additionalController = CountdownController(autoStart: false);
  void _startAdditionalTimer() {


  }

  void _pauseAdditionalTimer() {
    setState(() {

    });
  }
  int currentTime=0;
  Future<void> fetchUserInfo() async {
SharedPreferences preferences = await SharedPreferences.getInstance();
email  = preferences.getString("email")!;
userName  = preferences.getString("userName")!;
// dailyGoal  = preferences.getString("dailyGoal")!;
  }

  Future<void> _storeCurrentTime() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    // Get the current elapsed time in minutes and seconds
    int elapsedMinutes = _stopwatch.elapsed.inMinutes;
    int elapsedSeconds = _stopwatch.elapsed.inSeconds % 60;

    try {
      // Retrieve the stored time from Firestore
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

      if (userDoc.exists) {
        // Get the stored time values
        int storedMinutes = userDoc.get('totalTimeMin') ?? 0;
        int storedSeconds = userDoc.get('totalTimeSec') ?? 0;

        // Calculate the difference between the current time and stored time
        int updatedMinutes = storedMinutes + elapsedMinutes;
        int updatedSeconds = storedSeconds + elapsedSeconds;

        // Update the Firestore document with the new values
        await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
          'currentTime': currentTime,
          'totalTimeMin': updatedMinutes,
          'totalTimeSec': updatedSeconds,
        });

        print('Data updated for user with ID: ${_auth.currentUser?.uid}');
      }
    } catch (error) {
      print('Error updating data for user with ID: ${_auth.currentUser?.uid} - $error');
    }
  }
  // void _showInvitationCodePopupToEnterCurrentPage(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20.0),
  //         ),
  //         child: Container(
  //           padding: EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: Color(0xffD9D9D9),
  //             borderRadius: BorderRadius.circular(20.0),
  //           ),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 'Which page currently are you in?',
  //                 style: TextStyle(
  //                   fontSize: 18.0,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF283E50),
  //                 ),
  //               ),
  //               Divider(
  //                 color: Color(0xFF283E50),
  //                 thickness: 1,
  //               ),
  //               SizedBox(height: 16.0),
  //               Container(
  //                 height: 50,
  //                 padding: EdgeInsets.all(8.0),
  //                 decoration: BoxDecoration(
  //                   borderRadius: BorderRadius.circular(50.0),
  //                   color: Colors.grey[200], // Change the color as needed
  //                 ),
  //                 child: TextField(
  //                   controller: _currentPage,
  //                   keyboardType: TextInputType.number,
  //                   decoration: InputDecoration(
  //                     hintText: 'Enter the current page number',
  //                     prefixIcon: Icon(Icons.pages),
  //                     border: InputBorder.none, // Remove the default border
  //                   ),
  //                   // onChanged: _onSearchChanged,
  //                 ),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () {
  //                   if(int.parse(_currentPage.text)>widget.book.totalPage){
  //                     _currentPage.clear();
  //                     Fluttertoast.showToast(msg: "The number is greater than the total page of the book!");
  //                   }else{
  //
  //                     updatePageNumber(widget.book,int.parse(_currentPage.text));
  //                     _currentPage.clear();
  //                   }
  //
  //                   Navigator.pop(context);
  //                 },
  //                 child: Container(
  //                     width: 120,
  //                     child: Center(child: Text("Update",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 14),))),
  //                 style: ButtonStyle(
  //                   backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
  //                   shape: MaterialStateProperty.all<RoundedRectangleBorder>(
  //                     RoundedRectangleBorder(
  //                       borderRadius: BorderRadius.circular(15.0),
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  Future<void> _storeCurrentTimeOnFinished() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'currentTime':0});
      print('Strikes increased for user with ID: ${_auth.currentUser?.uid}');
    } catch (error) {
      print('Error increasing strikes for user with ID: ${_auth.currentUser?.uid} - $error');
      // Handle the error (e.g., show an error message)
    }
  }
  late Stopwatch _stopwatch;
  void _startPauseTimer() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        // _isRunning = false;
      } else {
        _stopwatch.start();

        // _isRunning = true;
      }
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.start();
        _additionalController.start();
        _startAdditionalTimer();
      } else {
        _storeCurrentTime();
        // _showInvitationCodePopupToEnterCurrentPage(context);
        _controller.pause();
        _additionalController.pause();
        _pauseAdditionalTimer();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _retrieveStoredTime();
    fetchBooks();
    // textDataStream = getQuoteDataStream();
    fetchData();
    User? user = FirebaseAuth.instance.currentUser;

    _isRunning = false;

    _stopwatch = Stopwatch();

    if (user != null) {
      String uid = user.uid;
      _userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
      fetchStrikes();
    }
    fetchBooksFromGoogle();
    fetchUserInfo();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _retrieveStoredTimeDetail(); // Retrieve stored time when the widget is loaded
    });
    // Future.delayed(Duration(seconds: 1), ()async{
    //   SharedPreferences preferences = await SharedPreferences.getInstance();
    //   preferences.getBool('firstTime')==false?
    //   '':_showTutorialCoachMark();
    // });

  }
// void _showTutorialCoachMark()async{
//     SharedPreferences preferences = await SharedPreferences.getInstance();
//     preferences.setBool("firstTime", false);
//     _initTarget();
//     tutorialCoachMark = TutorialCoachMark(
//       targets: targets,
//
//     )..show(context: context);
// }
//   void _initTarget() {
//     targets = [
//       TargetFocus(
//         identify: 'streaks',
//         keyTarget: streakRowKey,
//         contents: [
//           TargetContent(
//             builder: (context, controller) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [SizedBox(height: 20,),
//                   Container(
//                       height: 150,
//                       width: 200,
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFD9D9D9),
//                         borderRadius: BorderRadius.circular(20.0),
//                       ),
//                       child: Column(
//                         crossAxisAlignment:CrossAxisAlignment.end,
//                         children: [
//                           Text("Here you can find the streaks , \n The streak counts increases as per you complete \n your daily goal of reading."),
//                           ElevatedButton(
//                             onPressed: () {
//                               controller.next();
//                             },
//                             child: Text("Next"),
//                             style: ButtonStyle(
//                               backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
//                               shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                                 RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(15.0),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )),
//
//                 ],
//               );
//             },
//             align: ContentAlign.bottom,
//           ),
//         ],
//       ),
//       TargetFocus(
//         identify: 'time',
//         keyTarget: timeKey,
//         contents: [
//           TargetContent(
//             builder: (context, controller) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [SizedBox(height: 20,),
//                   Container(
//                       height: 150,
//                       width: 200,
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFD9D9D9),
//                         borderRadius: BorderRadius.circular(20.0),
//                       ),
//                       child: Column(
//                         crossAxisAlignment:CrossAxisAlignment.end,
//                         children: [
//                           Text("Here you can find the times of your daily goal, \n and the total time you have spent reading."),
//                           ElevatedButton(
//                             onPressed: () {
//                               controller.next();
//                             },
//                             child: Text("Next"),
//                             style: ButtonStyle(
//                               backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
//                               shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                                 RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(15.0),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )),
//
//                 ],
//               );
//             },
//             align: ContentAlign.bottom,
//           ),
//         ],
//       ),
//       // TargetFocus(
//       //   identify: 'read',
//       //   keyTarget: readKey,
//       //   contents: [
//       //     TargetContent(
//       //       builder: (context, controller) {
//       //         return Column(
//       //           crossAxisAlignment: CrossAxisAlignment.start,
//       //           children: [SizedBox(height: 20,),
//       //             Container(
//       //                 height: 150,
//       //                 width: 200,
//       //                 padding: EdgeInsets.all(8),
//       //                 decoration: BoxDecoration(
//       //                   color: Color(0xFFD9D9D9),
//       //                   borderRadius: BorderRadius.circular(20.0),
//       //                 ),
//       //                 child: Column(
//       //                   crossAxisAlignment:CrossAxisAlignment.end,
//       //                   children: [
//       //                     Text("Here you can find the latest books and can \n add them into your reading list."),
//       //                     ElevatedButton(
//       //                       onPressed: () {
//       //                         controller.next();
//       //                       },
//       //                       child: Text("Next"),
//       //                       style: ButtonStyle(
//       //                         backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
//       //                         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//       //                           RoundedRectangleBorder(
//       //                             borderRadius: BorderRadius.circular(15.0),
//       //                           ),
//       //                         ),
//       //                       ),
//       //                     ),
//       //                   ],
//       //                 )),
//       //
//       //           ],
//       //         );
//       //       },
//       //       align: ContentAlign.bottom,
//       //     ),
//       //   ],
//       // ),
//       TargetFocus(
//         identify: 'more',
//         keyTarget: moreKey,
//         contents: [
//           TargetContent(
//             builder: (context, controller) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [SizedBox(height: 20,),
//                   Container(
//                       height: 150,
//                       width: 200,
//                       padding: EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Color(0xFFD9D9D9),
//                         borderRadius: BorderRadius.circular(20.0),
//                       ),
//                       child: Column(
//                         crossAxisAlignment:CrossAxisAlignment.end,
//                         children: [
//                           Text("Here you can find the all the books and can \n add them into your reading list."),
//                           ElevatedButton(
//                             onPressed: () {
//                               controller.next();
//                             },
//                             child: Text("Next"),
//                             style: ButtonStyle(
//                               backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
//                               shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                                 RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(15.0),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       )),
//
//                 ],
//               );
//             },
//             align: ContentAlign.bottom,
//           ),
//         ],
//       ),
//     ];
//   }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEEAD4),
        body: SingleChildScrollView(
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
                top: -20,
                left: -10,
                child: Image.asset(
                  "assets/logo.png",
                  height: 120,
                ),
              ),
              Positioned(
                top: 90,
                left: 10,
                child: Text(
                  "Welcome ${guestLogin==true?'Guest':userName} !!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Color(0xffFEEAD4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBooks()));
                  },
                  child: Image.asset(
                    "assets/search.png",
                    height: 50,
                  ),
                ),
              ),
          Positioned(
            top: 130,
            left: 20,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 100,
                    width: MediaQuery.of(context).size.width/2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5,),
                            Text(
                              "Today's Goal",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color:  Color(0xff283E50),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              "Today: ${dailyGoal} mins",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              "Completed: ${((totalTimeMin * 60 + totalTimeSec) / 60).toStringAsFixed(2)} mins",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10), // Adjust the spacing between the two containers
                  Container(
                    height: 100,
                    width: MediaQuery.of(context).size.width/2.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          key: timeKey,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5,),
                            Text(
                              "Reading Goal",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF283E50),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              "Total: ${yearlyGoal} books",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 5,),
                            Text(
                              "Completed: ${myBooksMyReads.length} books",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                top: 20,
                left: MediaQuery.of(context).size.width / 2.5,
                child: Row(
                  key: streakRowKey,
                  children: [
                    const Text(
                      "Home",
                      style: TextStyle(
                        fontFamily: "Abhaya Libre ExtraBold",
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xfffeead4),
                        height: 29 / 22,
                      ),
                    ),
                    Image.asset(
                      "assets/strick.png",
                      height: 50,
                        // key: streakKey,
                    ),
                    Text("${strikesCount}", style: TextStyle(
                      fontSize: 14,
                      color: Color(0xfffeead4),
                    )),

                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 250.0),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      height:MediaQuery.of(context).size.height*1.2,
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text("My Reads",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                          // Expanded(
                          //   flex: 1,
                          //   child: myBooksMyReads.isEmpty?
                          //   Container(
                          //       height: 100,
                          //       child: Center(child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         mainAxisAlignment: MainAxisAlignment.center,
                          //         children: [
                          //           Text("You don't have any book in your list",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                          //           SizedBox(height: 10,),
                          //           GestureDetector(
                          //             onTap: (){
                          //               Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBooks()));
                          //             },
                          //             child: Row(
                          //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //               children: [
                          //                 Image.asset('assets/self.png'),
                          //                 Image.asset('assets/self.png'),
                          //                 Image.asset('assets/self.png'),
                          //                 Image.asset('assets/self.png'),
                          //                 Image.asset('assets/self.png'),
                          //               ],
                          //             ),
                          //           )
                          //         ],
                          //       )))
                          //       : ListView.builder(
                          //     scrollDirection: Axis.horizontal,
                          //     itemCount: myBooksMyReads.length,
                          //     itemBuilder: (context, index) {
                          //       return GestureDetector(
                          //         onTap: (){
                          //           Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBookDetailPageEachStatus(book: myBooksMyReads[index],)));
                          //         },
                          //         child:Padding(
                          //           padding: const EdgeInsets.only(top:10.0),
                          //           child: Container(
                          //             width: 200,
                          //             height: 300,
                          //
                          //             margin: EdgeInsets.symmetric(horizontal: 10.0),
                          //             child: Stack(
                          //               alignment: Alignment.topCenter,
                          //               children: [
                          //                 Positioned(
                          //                   top: 120,
                          //                   child: Container(
                          //                     height: 300,
                          //                     width: 250,
                          //                     padding: EdgeInsets.all(8),
                          //                     decoration: BoxDecoration(
                          //                       color: Color(0xFFD9D9D9),
                          //                       borderRadius: BorderRadius.circular(20.0),
                          //                     ),
                          //                     child: Column(
                          //                       children: [
                          //                         SizedBox(height: 8),
                          //                         Container(
                          //                           height: 200,
                          //                           width: 200,
                          //                           child: Padding(
                          //                             padding: const EdgeInsets.only(top: 30.0,left: 20,right: 20),
                          //                             child: Text(
                          //                               myBooksMyReads[index].description,
                          //                               textAlign: TextAlign.left,
                          //                               maxLines: 6,
                          //
                          //                               style: TextStyle(
                          //                                 color: Colors.black,
                          //                                 fontSize: 13
                          //                               ),
                          //                             ),
                          //                           ),
                          //                         ),
                          //                         SizedBox(height: 20,),
                          //
                          //                       ],
                          //                     ),
                          //                   ),
                          //                 ),
                          //                 Padding(
                          //                   padding: const EdgeInsets.all(8.0),
                          //                   child: Image.network(
                          //                     myBooksMyReads[index].imageLink,
                          //                     height: 150,
                          //                     width: 150,
                          //                   ),
                          //                 ),
                          //               ],
                          //             ),
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //   ),
                          // ),
                          //
                          // SizedBox(height: 10),
                          Text("Currently Reading",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                          myBooks.isEmpty?
                          Container(
                              height: 100,
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset('assets/self.png'),
                                    Image.asset('assets/self.png'),
                                    Image.asset('assets/self.png'),
                                    Image.asset('assets/self.png'),
                                    Image.asset('assets/self.png'),
                                  ],
                                ),
                              ))
                              : Expanded(
                            flex: 1,
                                child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: myBooks.length,
                            itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>TimerPage(book: myBooks[index],)));
                                  },
                                  child:Padding(
                                    padding: const EdgeInsets.only(top:10.0),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      // height: 200,

                                      // margin: EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Stack(
                                                alignment: Alignment.topLeft,
                                                children: [
                                                  // Positioned(
                                                  //   top: 0,
                                                  //   left: 30,
                                                  //   child: Container(
                                                  //     height: 250,
                                                  //     width: 250,
                                                  //     padding: const EdgeInsets.all(8),
                                                  //     decoration: BoxDecoration(
                                                  //       color: const Color(0xFFD9D9D9),
                                                  //       borderRadius: BorderRadius.circular(20.0),
                                                  //     ),
                                                  //     child: Column(
                                                  //       crossAxisAlignment: CrossAxisAlignment.start,
                                                  //       children: [
                                                  //         const SizedBox(height: 8),
                                                  //         Container(
                                                  //           height: 150,
                                                  //           // Set a fixed height for description
                                                  //           child: Column(
                                                  //             crossAxisAlignment: CrossAxisAlignment.start,
                                                  //             children: [
                                                  //               Padding(
                                                  //                 padding: const EdgeInsets.only(top: 10.0),
                                                  //                 child: Text(
                                                  //                   "Currently Reading",
                                                  //                   textAlign: TextAlign.center,
                                                  //                   style: const TextStyle(
                                                  //                       color: Color(0xFF283E50),
                                                  //                       fontWeight: FontWeight.bold,
                                                  //                       fontSize: 14),
                                                  //                 ),
                                                  //               ),
                                                  //               SingleChildScrollView(
                                                  //                 child: Padding(
                                                  //                   padding:
                                                  //                       const EdgeInsets.only(top: 5.0),
                                                  //                   child: Text(
                                                  //                     myBooks[index].author,
                                                  //                     textAlign: TextAlign.center,
                                                  //                     style: const TextStyle(
                                                  //                         color: Color(0xFF686868),
                                                  //                         fontSize: 12,
                                                  //                         fontWeight: FontWeight.w500),
                                                  //                   ),
                                                  //                 ),
                                                  //               ),
                                                  //             ],
                                                  //           ),
                                                  //         ),
                                                  //       ],
                                                  //     ),
                                                  //   ),
                                                  // ),
                                                  // Positioned(
                                                  //   top: 105,
                                                  //   right: 10,
                                                  //   child: Column(
                                                  //     children: [
                                                  //       Stack(
                                                  //         children: [
                                                  //           CircularProgressIndicator(
                                                  //             value: calculatePercentage() / 100,
                                                  //             strokeWidth: 5.0,
                                                  //             backgroundColor: Colors.black12,
                                                  //             // Adjust the stroke width as needed
                                                  //             valueColor: AlwaysStoppedAnimation<Color>(
                                                  //               Color(0xFF283E50),
                                                  //             ), // Adjust the color as needed
                                                  //           ),
                                                  //           Positioned(
                                                  //             top: 10,
                                                  //             left: 5,
                                                  //             child: Text(
                                                  //               "${calculatePercentage().toStringAsFixed(1)}%",
                                                  //               style: TextStyle(
                                                  //                   color: Color(0xFF283E50),
                                                  //                   fontWeight: FontWeight.bold,
                                                  //                   fontSize: 11),
                                                  //             ),
                                                  //           ),
                                                  //         ],
                                                  //       ),
                                                  //       SizedBox(
                                                  //         height: 10,
                                                  //       ),
                                                  //       Text(
                                                  //         "Progress",
                                                  //         style: TextStyle(
                                                  //             color: Color(0xFF686868), fontSize: 14),
                                                  //       ),
                                                  //       SizedBox(
                                                  //         height: 20,
                                                  //       ),
                                                  //
                                                  //     ],
                                                  //   ),
                                                  // ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(top:30.0),
                                                    child: Column(
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(30.0),
                                                          child: Image.network(
                                                            myBooks[index].imageLink,
                                                            height: 200,
                                                            width: 150,
                                                            loadingBuilder: (BuildContext context, Widget child,
                                                                ImageChunkEvent? loadingProgress) {
                                                              if (loadingProgress == null) {
                                                                // Image is fully loaded, display the actual image
                                                                return child;
                                                              } else {
                                                                // Image is still loading, display a placeholder or loading indicator
                                                                return Center(
                                                                  child: CircularProgressIndicator(
                                                                    value: loadingProgress.expectedTotalBytes !=
                                                                        null
                                                                        ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                        (loadingProgress
                                                                            .expectedTotalBytes ??
                                                                            1)
                                                                        : null,
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                        SizedBox(height: 10,),
                                                        Container(
                                                          height: 40,
                                                          width: 100,
                                                          child: ElevatedButton(
                                                            onPressed:(){
                                                              Navigator.push(context, MaterialPageRoute(builder: (context)=>TimerPage(book: myBooks[index],)));

                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              primary: Color(0xff283E50), // Set your desired button color
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
                                                              ),
                                                            ),
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(10.0), // Adjust the padding as needed
                                                              child:Text(
                                                                'Start',
                                                                style: TextStyle(fontSize: 16.0),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Column(
                                                    // crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: <Widget>[

                                                      SizedBox(
                                                        width: 150,
                                                        child: Text(myBooks[index].author,
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(0xff686868),
                                                              fontWeight: FontWeight.bold
                                                          ),),
                                                      ),
                                                      SizedBox(height: 16,),
                                                      Card(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(
                                                              20.0), // Adjust the radius as needed
                                                        ),
                                                        color: Color(0xFFFF997A),

                                                        child: Container(
                                                          width: 200,
                                                          height: 50,
                                                          child: Countdown(
                                                            controller: _controller,
                                                            seconds:finalTime,
                                                            build: (_, double time) {
                                                              currentTime = time.toInt();
                                                              return Padding(
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      'Daily Goal: ',
                                                                      style: TextStyle(
                                                                          fontSize: 14,
                                                                          color: Color(0xff283E50),
                                                                          fontWeight: FontWeight.bold
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      time.floor().toString()+ ' sec',
                                                                      style: TextStyle(
                                                                          fontSize: 14,
                                                                          color: Color(0xff686868),
                                                                          fontWeight: FontWeight.bold
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              );
                                                            },
                                                            interval: Duration(milliseconds: 100),
                                                            onFinished: () {
                                                              print('Countdown finished!');
                                                              try {
                                                                // Your existing code here
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(
                                                                    content: Text('Timer is done!'),
                                                                  ),
                                                                );
                                                                // updateStrikeInFirestore();
                                                                _storeCurrentTimeOnFinished();
                                                                _controller.pause();
                                                                setState(() {
                                                                  // _isRunning = false;
                                                                });
                                                              } catch (e) {
                                                                print('Error in onFinished callback: $e');
                                                                log('Error in onFinished callback: $e');
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                      // SizedBox(height: 16),
                                                      Card(
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(
                                                              20.0), // Adjust the radius as needed
                                                        ),
                                                        color: Color(0xFFFF997A),

                                                        child: Container(
                                                          width: 200,
                                                          height: 50,
                                                          child: Center(
                                                            child: Padding(
                                                              padding: const EdgeInsets.all(8.0),
                                                              child: Row(
                                                                children: [
                                                                  Text(
                                                                    'Total Read: ',
                                                                    style: TextStyle(
                                                                        fontSize: 14,
                                                                        color: Color(0xff283E50),
                                                                        fontWeight: FontWeight.bold
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    _formatDuration(_stopwatch.elapsed),
                                                                    style: TextStyle(
                                                                        fontSize: 14,
                                                                        color: Color(0xff686868),
                                                                        fontWeight: FontWeight.bold
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                        onTap: (){
                                                          // _showInvitationCodePopupToEnterCurrentPage(context);
                                                        },
                                                        child: Card(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(
                                                                20.0), // Adjust the radius as needed
                                                          ),
                                                          color: Color(0xFFFF997A),

                                                          child: Container(
                                                            width: 200,
                                                            height: 50,
                                                            child: Center(
                                                              child: Padding(
                                                                padding: const EdgeInsets.all(8.0),
                                                                child: Row(
                                                                  children: [
                                                                    Text(
                                                                      'Pages Read: ',
                                                                      style: TextStyle(
                                                                          fontSize: 14,
                                                                          color: Color(0xff283E50),
                                                                          fontWeight: FontWeight.bold
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      myBooks[index].currentPage.toString()+'/'+myBooks[index].totalPage.toString(),
                                                                      style: TextStyle(
                                                                          fontSize: 14,
                                                                          color: Color(0xff686868),
                                                                          fontWeight: FontWeight.bold
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 20.0),

                                                      // Container(
                                                      //   padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      //   child: ElevatedButton(
                                                      //     child: Text(_isRunning ? 'Pause' : 'Start'),
                                                      //     onPressed: () {
                                                      //       setState(() {
                                                      //         _isRunning = !_isRunning;
                                                      //         if (_isRunning) {
                                                      //           _controller.start();
                                                      //           _additionalController.start();
                                                      //           _startAdditionalTimer();
                                                      //         } else {
                                                      //           _storeCurrentTime();
                                                      //           _controller.pause();
                                                      //           _additionalController.pause();
                                                      //           _pauseAdditionalTimer();
                                                      //         }
                                                      //       });
                                                      //     },
                                                      //   ),
                                                      // ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          Divider(
                                              endIndent: 10,
                                              indent: 10,
                                              thickness: 1,
                                              color: Color(0xff283E50)
                                          ),


                                          Padding(
                                            padding: const EdgeInsets.only(left:15.0,right: 15),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text("Notes",  style: const TextStyle(
                                                    color: Color(0xFF283E50),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),),
                                                GestureDetector(
                                                    onTap: (){
                                                      _showAddNotesDialog(myBooks[index]);
                                                    },
                                                    child: Icon(Icons.add,color:  Color(0xFF283E50),))
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              // height: 250,
                                              width: MediaQuery.of(context).size.width,
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD9D9D9),
                                                borderRadius: BorderRadius.circular(20.0),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: myBooks[index].notes.map((note) {
                                                      return Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.end,
                                                          children: [
                                                            Text(
                                                              '-'+note['note'],
                                                              style: TextStyle(fontSize: 14, color: Color(0xFF283E50),fontWeight: FontWeight.bold),
                                                            ),
                                                            Text(
                                                              'Page -'+note['pageNumber'],
                                                              style: TextStyle(fontSize: 14, color: Color(0xFF283E50),fontWeight: FontWeight.bold),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                  // Padding(
                                                  //   padding:
                                                  //       const EdgeInsets.only(top: 5.0),
                                                  //   child: Text(
                                                  //     myBooks[index].description,
                                                  //     textAlign: TextAlign.center,
                                                  //     maxLines: 12, // Adjust the number of lines as needed
                                                  //     overflow: TextOverflow.ellipsis,
                                                  //     style: const TextStyle(
                                                  //       color: Color(0xFF686868),
                                                  //       fontSize: 12,
                                                  //       fontWeight: FontWeight.w500,
                                                  //     ),
                                                  //   )
                                                  //
                                                  // ),

                                                ],
                                              ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(left:15.0,right: 15),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text("Quotes",  style: const TextStyle(
                                                    color: Color(0xFF283E50),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),),
                                                GestureDetector(
                                                    onTap: (){
                                                      _showAddQuotesDialog(myBooks[index]);
                                                    },
                                                    child: Icon(Icons.add,color:  Color(0xFF283E50),))
                                              ],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: MediaQuery.of(context).size.width,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: Color(0xFFD9D9D9),
                                              ),
                                              padding: EdgeInsets.all(12),
                                              child: Column(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: myBooks[index].quotes.map((quotes) {
                                                      return Padding(
                                                        padding: EdgeInsets.symmetric(vertical: 8),
                                                        child: Text(
                                                          '-'+quotes,
                                                          style: TextStyle(fontSize: 14, color: Color(0xFF283E50)),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),

                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ),
                                );
                            },
                          ),
                              ),
                          // SizedBox(height: 20,),
                          // Text("To Be Read",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                          // Expanded(
                          //   flex: 1,
                          //   child: myBooksToBeRead.isEmpty?
                          //   Container(
                          //       height: 100,
                          //       child: Center(child: Column(
                          //         crossAxisAlignment: CrossAxisAlignment.center,
                          //         mainAxisAlignment: MainAxisAlignment.center,
                          //         children: [
                          //           Text("You don't have any book in your list",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                          //           SizedBox(height: 10,),
                          //           Row(
                          //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //             children: [
                          //               Image.asset('assets/self.png'),
                          //               Image.asset('assets/self.png'),
                          //               Image.asset('assets/self.png'),
                          //               Image.asset('assets/self.png'),
                          //               Image.asset('assets/self.png'),
                          //             ],
                          //           )
                          //         ],
                          //       )))
                          //       : ListView.builder(
                          //     scrollDirection: Axis.horizontal,
                          //     itemCount: myBooksToBeRead.length,
                          //     itemBuilder: (context, index) {
                          //       return GestureDetector(
                          //         onTap: (){
                          //           Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBookDetailPageEachStatus(book: myBooksToBeRead[index],)));
                          //         },
                          //         child:Padding(
                          //           padding: const EdgeInsets.only(top:10.0),
                          //           child: Container(
                          //             width: 250,
                          //             height: 300,
                          //
                          //             margin: EdgeInsets.symmetric(horizontal: 16.0),
                          //             child: Stack(
                          //               alignment: Alignment.topCenter,
                          //               children: [
                          //                 Positioned(
                          //                   top: 120,
                          //                   child: Container(
                          //                     height: 300,
                          //                     width: 250,
                          //                     padding: EdgeInsets.all(8),
                          //                     decoration: BoxDecoration(
                          //                       color: Color(0xFFD9D9D9),
                          //                       borderRadius: BorderRadius.circular(10.0),
                          //                     ),
                          //                     child: Column(
                          //                       children: [
                          //                         Container(
                          //                           height: 200,
                          //                           child: SingleChildScrollView(
                          //                             child: Padding(
                          //                               padding: const EdgeInsets.only(top: 30.0),
                          //                               child: Text(
                          //                                 myBooksToBeRead[index].description,
                          //                                 textAlign: TextAlign.center,
                          //                                 style: TextStyle(
                          //                                   color: Colors.black,
                          //                                 ),
                          //                               ),
                          //                             ),
                          //                           ),
                          //                         ),
                          //                         SizedBox(height: 20,),
                          //
                          //                       ],
                          //                     ),
                          //                   ),
                          //                 ),
                          //                 Padding(
                          //                   padding: const EdgeInsets.all(8.0),
                          //                   child: Image.network(
                          //                     myBooksToBeRead[index].imageLink,
                          //                     height: 150,
                          //                     width: 150,
                          //                   ),
                          //                 ),
                          //               ],
                          //             ),
                          //           ),
                          //         ),
                          //       );
                          //     },
                          //   ),
                          // ),

                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            fetchBooks();
          },
          tooltip: 'Refresh',
          child: Icon(Icons.refresh),
          backgroundColor: Color(0xFF283E50),
        ),
      ),
    );
  }
  void _showAddNotesDialog(DetailBook book) {
    showDialog(

      context: context,
      builder: (BuildContext context) {
        TextEditingController notesController = TextEditingController();
        TextEditingController pageNumberController = TextEditingController();

        return AlertDialog(
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
          ),
          title: Text('Notes'),

          content: Container(
            height: 50,
            decoration: BoxDecoration(
              color:Colors.grey[100],
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: TextField(
                      controller: notesController,
                      onChanged: (value) {

                      },
                      cursorColor: Color(0xFFD9D9D9),
                      decoration: InputDecoration(
                        hintText: 'Write your note',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,

                      ),

                    ),
                  ),
                ),

              ],
            ),
          ),
          actions: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF283E50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),

                        ),

                      ),
                      child: TextButton(
                        onPressed: (){
                          setState(() {
                            String newNote = notesController.text.trim();
                            if (newNote.isNotEmpty) {
                              addNote(book, newNote,pageNumberController.text);
                              notesController.clear();
                              Fluttertoast.showToast(
                                msg: "Note added successfully!",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Color(0xFF283E50),
                                textColor: Colors.white,
                              );
                              Navigator.pop(context);
                            }
                          });
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color:Colors.grey[100],
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left:8.0),
                      child: TextField(
                        controller: pageNumberController,
                        onChanged: (value) {

                        },
                        cursorColor: Color(0xFFD9D9D9),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,

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
  void _showAddQuotesDialog(DetailBook book) {
    showDialog(

      context: context,
      builder: (BuildContext context) {

        TextEditingController quotesController = TextEditingController();

        return AlertDialog(
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
          ),
          title: Text('Quotes'),

          content: Container(
            height: 50,
            decoration: BoxDecoration(
              color:Colors.grey[100],
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left:8.0),
                    child: TextField(
                      controller: quotesController,
                      onChanged: (value) {

                      },
                      cursorColor: Color(0xFFD9D9D9),
                      decoration: InputDecoration(
                        hintText: 'Write your Quote',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,

                      ),

                    ),
                  ),
                ),

              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),

                    ),

                  ),
                  child: TextButton(
                    onPressed: (){
                      setState(() {
                        String newQuote = quotesController.text.trim();
                        if (newQuote.isNotEmpty) {
                          addQuote(book, newQuote);
                          quotesController.clear();
                          Fluttertoast.showToast(
                            msg: "Note added successfully!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF283E50),
                            textColor: Colors.white,
                          );
                        }
                      });
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),

          ],
        );
      },
    );
  }
  void addNote(DetailBook book, String newNote,String pageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'notes': FieldValue.arrayUnion([
            {'note': newNote, 'pageNumber': pageNumber}
          ]),
        });
        // Update the local state with the new notes
        setState(() {
          book.notes.add({'note': newNote, 'pageNumber': pageNumber});
        });
        print('Note added successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding note: $e');
    }
  }
  void addQuote(DetailBook book, String newQuote) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'quotes': FieldValue.arrayUnion([newQuote]),
        });

        // Update the local state with the new notes
        setState(() {
          book.quotes.add(newQuote);
        });

        print('Quotes added successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding note: $e');
    }
  }
  void shareBookDetails(DetailBook book,String note) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        CollectionReference communityBooksRef =
        FirebaseFirestore.instance.collection('communityBooks');
        await communityBooksRef.add({
          'author': book.author,
          'imageLink': book.imageLink,
          'currentPage': book.currentPage,
          'notes': note,
          'username': user.displayName ?? 'Anonymous',
          'avatarUrl': user.photoURL ?? '',
          'userId':uid
          // Add other fields as needed
        });

        // Display a notification or feedback to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book shared successfully!'),
          ),
        );
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error sharing book: $e');
    }
  }

  void _showRemoveBookDialog(DetailBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController notesController = TextEditingController();

        return AlertDialog(
          title: Text('Remove Book'),
          content: Text("Are you sure wantt to remove the book from your read list?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeBook(book);

                });
                Navigator.pop(context);
              },
              child: Text('Remove'),
            ),
          ],
        );
      },
    );
  }
  void removeBook(DetailBook book) async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to remove the book
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Remove the book document from Firestore using its document ID
        await myBooksRef.doc(book.documentId).delete();

        setState(() {
          books.remove(book);
        });
        fetchBooks();
        print('Book removed successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error removing book: $e');
    }
  }

  void _showConfirmationDialog(String author,String image,String description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Add the book",
            style: TextStyle(color: Colors.blue), // Set title text color
          ),
          content: Text("Are you sure want to add this book in your list?"),
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
                    saveMyBook( author,image,description);
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

}

// class DetailBook {
//   final String author;
//   final String imageLink;
//   final String documentId;
//   final String description;
//   int currentPage; // Add this field
//   int totalPage; // Add this field
//   List<String> notes; // Add this field
//   List<String> quotes; // Add this field
//
//   DetailBook({
//     required this.author,
//     required this.imageLink,
//     required this.documentId,
//     required this.description,
//     this.currentPage = 0, // Set the default value to 0
//     this.totalPage = 0, // Set the default value to 0
//     this.notes = const [], // Initialize notes as an empty list
//     this.quotes = const [], // Initialize notes as an empty list
//   });
//
//   factory DetailBook.fromMap(String documentId, Map<String, dynamic>? map) {
//     if (map == null) {
//       return DetailBook(
//           author: 'No Author',
//           imageLink: 'No Image',
//           documentId: documentId,
//           description: 'description',
//           totalPage: 100
//       );
//     }
//     return DetailBook(
//       author: map['author'] ?? 'No Author',
//       imageLink: map['image'] ?? 'No Image',
//       documentId: documentId,
//       description: map['description']??'Description',
//       currentPage: map['currentPage'] ?? 0, // Set the currentPage value
//       totalPage: map['totalPageCount'] ?? 0, // Set the currentPage value
//       notes: List<String>.from(map['notes'] ?? []), // Set the notes value
//       quotes: List<String>.from(map['quotes'] ?? []), // Set the notes value
//     );
//   }
// }
// class Book {
//   final String author;
//   final String imageLink;
//
//   Book({required this.author, required this.imageLink});
//
//   factory Book.fromMap(Map<String, dynamic> map) {
//     return Book(
//       author: map['title'] ?? 'No Author',
//       imageLink: map['published_works'][0]['cover_art_url'] ?? 'No Image',
//     );
//   }
// }
class Book {
  final String title;
  final String imageLink;
  final String description;
  final double rating;
  final int pageCount;

  Book({
    required this.title,
    required this.imageLink,
    required this.description,
    required this.rating,
    required this.pageCount,

  });

  factory Book.fromMap(Map<String, dynamic> map) {
    final volumeInfo = map['volumeInfo'];
    return Book(
      description: volumeInfo['description'] ?? 'No Description',
      title: volumeInfo['title'] ?? 'No Title',
      imageLink: volumeInfo['imageLinks']?['thumbnail'] ?? 'No Image',
      rating: volumeInfo['averageRating']?.toDouble() ?? 0.0,
      pageCount: volumeInfo['pageCount'] ?? 0,
    );
  }
}