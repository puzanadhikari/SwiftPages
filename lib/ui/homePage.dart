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
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../signUpPage.dart';
import 'books/allBooks.dart';
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
  List<TargetFocus> targets= [];
  final String apiKey =
      "30fe2ae32emsh0b5a48e1d0ed53dp17a064jsn7a2f3e3aca01";
  final String apiUrl =
      "https://book-finder1.p.rapidapi.com/api/search?page=2";
  int strikesCount = 0;
  int totalTimeMin=0;
  int totalTimeSec=0;
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
      print("Error: ${response.statusCode}");
    }
  }
  void fetchBooks() async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to fetch books
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Fetch all books from the 'books' subcollection
        QuerySnapshot querySnapshot = await myBooksRef.get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocuments = querySnapshot.docs;
        setState(() {
          myBooks = bookDocuments
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();  print('Books: $myBooks'); // Check the console for the list of books
        });
        // Process each book document
        for (DocumentSnapshot doc in bookDocuments) {
          Map<String, dynamic> bookData = doc.data() as Map<String, dynamic>;

          // Print or use the fetched book data
          log('Book: $bookData');
        }
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error fetching books: $e');
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
        log(currentTimeCount.toString());
        setState(() {});
      }
    } catch (e) {
      print('Error fetching strikes: $e');
    }
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

  String email = ' ';
  String userName = ' ';
  String dailyGoal = ' ';
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

  Future<void> fetchUserInfo() async {
SharedPreferences preferences = await SharedPreferences.getInstance();
email  = preferences.getString("email")!;
userName  = preferences.getString("userName")!;
// dailyGoal  = preferences.getString("dailyGoal")!;
  }

  @override
  void initState() {
    super.initState();
    _retrieveStoredTime();
    fetchBooks();
    textDataStream = getQuoteDataStream();
    fetchData();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;
      _userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
      fetchStrikes();
    }
    fetchBooksFromGoogle();
    fetchUserInfo();
    Future.delayed(Duration(seconds: 1), ()async{
      SharedPreferences preferences = await SharedPreferences.getInstance();
      preferences.getBool('firstTime')==false?
      '':_showTutorialCoachMark();
    });

  }
void _showTutorialCoachMark()async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setBool("firstTime", false);
    _initTarget();
    tutorialCoachMark = TutorialCoachMark(
      targets: targets,

    )..show(context: context);
}
  void _initTarget() {
    targets = [
      TargetFocus(
        identify: 'streaks',
        keyTarget: streakRowKey,
        contents: [
          TargetContent(
            builder: (context, controller) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [SizedBox(height: 20,),
                  Container(
                      height: 150,
                      width: 200,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        crossAxisAlignment:CrossAxisAlignment.end,
                        children: [
                          Text("Here you can find the streaks , \n The streak counts increases as per you complete \n your daily goal of reading."),
                          ElevatedButton(
                            onPressed: () {
                              controller.next();
                            },
                            child: Text("Next"),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),

                ],
              );
            },
            align: ContentAlign.bottom,
          ),
        ],
      ),
      TargetFocus(
        identify: 'time',
        keyTarget: timeKey,
        contents: [
          TargetContent(
            builder: (context, controller) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [SizedBox(height: 20,),
                  Container(
                      height: 150,
                      width: 200,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        crossAxisAlignment:CrossAxisAlignment.end,
                        children: [
                          Text("Here you can find the times of your daily goal, \n and the total time you have spent reading."),
                          ElevatedButton(
                            onPressed: () {
                              controller.next();
                            },
                            child: Text("Next"),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),

                ],
              );
            },
            align: ContentAlign.bottom,
          ),
        ],
      ),
      // TargetFocus(
      //   identify: 'read',
      //   keyTarget: readKey,
      //   contents: [
      //     TargetContent(
      //       builder: (context, controller) {
      //         return Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [SizedBox(height: 20,),
      //             Container(
      //                 height: 150,
      //                 width: 200,
      //                 padding: EdgeInsets.all(8),
      //                 decoration: BoxDecoration(
      //                   color: Color(0xFFD9D9D9),
      //                   borderRadius: BorderRadius.circular(20.0),
      //                 ),
      //                 child: Column(
      //                   crossAxisAlignment:CrossAxisAlignment.end,
      //                   children: [
      //                     Text("Here you can find the latest books and can \n add them into your reading list."),
      //                     ElevatedButton(
      //                       onPressed: () {
      //                         controller.next();
      //                       },
      //                       child: Text("Next"),
      //                       style: ButtonStyle(
      //                         backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
      //                         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
      //                           RoundedRectangleBorder(
      //                             borderRadius: BorderRadius.circular(15.0),
      //                           ),
      //                         ),
      //                       ),
      //                     ),
      //                   ],
      //                 )),
      //
      //           ],
      //         );
      //       },
      //       align: ContentAlign.bottom,
      //     ),
      //   ],
      // ),
      TargetFocus(
        identify: 'more',
        keyTarget: moreKey,
        contents: [
          TargetContent(
            builder: (context, controller) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [SizedBox(height: 20,),
                  Container(
                      height: 150,
                      width: 200,
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        crossAxisAlignment:CrossAxisAlignment.end,
                        children: [
                          Text("Here you can find the all the books and can \n add them into your reading list."),
                          ElevatedButton(
                            onPressed: () {
                              controller.next();
                            },
                            child: Text("Next"),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),

                ],
              );
            },
            align: ContentAlign.bottom,
          ),
        ],
      ),
    ];
  }

  Stream<List<String>> getQuoteDataStream() {
    return FirebaseFirestore.instance
        .collection('app_quotes')
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
      return snapshot.docs
          .map((DocumentSnapshot<Map<String, dynamic>> doc) =>
      doc['quotes'] as String)
          .toList();
    });
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
                  // Navigator.push(context, MaterialPageRoute(builder: (context)=>Timer()));
                },
                child: Image.asset(
                  "assets/search.png",
                  height: 50,
                ),
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
                      key: timeKey,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5,),
                         Text(
                        "Today's Goal",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),

                        ),
                        const SizedBox(height: 5,),
                         Text(
                          "Today: ${dailyGoal} mins",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF686868),
                              fontSize: 16,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 5,),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              "Completed: ${((totalTimeMin * 60 + totalTimeSec)/60).toStringAsFixed(2)} mins",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Color(0xFF686868),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500

                              ),
                            ),
                            Image.asset(
                              "assets/clock.png",
                              height: 20,
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
            // Padding(
            //   padding: const EdgeInsets.only(top: 100.0),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Expanded(
            //         child: ListView.builder(
            //           scrollDirection: Axis.horizontal,
            //           itemCount: myBooks.length,
            //           itemBuilder: (context, index) {
            //             return GestureDetector(
            //               onTap: (){
            //                 Navigator.push(context, MaterialPageRoute(builder: (context)=>MyBooksDetailPage(book: myBooks[index],)));
            //
            //               },
            //               child: Container(
            //                 width: 250,
            //                 margin: EdgeInsets.symmetric(horizontal: 16.0),
            //                 child: Stack(
            //                   alignment: Alignment.topCenter,
            //                   children: [
            //                     Positioned(
            //                       top: 180,
            //                       child: Container(
            //                         // height: 300,
            //                         width: 250,
            //                         padding: EdgeInsets.all(8),
            //                         decoration: BoxDecoration(
            //                           color: Color(0xFFD9D9D9),
            //                           borderRadius: BorderRadius.circular(20.0),
            //                         ),
            //                         child: Column(
            //                           children: [
            //                             SizedBox(height: 30,),
            //                             RatingBar.builder(
            //                               initialRating: 2.5,
            //                               minRating: 1,
            //                               direction: Axis.horizontal,
            //                               allowHalfRating: true,
            //                               itemCount: 5,
            //                               itemSize: 20,
            //                               itemBuilder: (context, _) => Icon(
            //                                 Icons.star,
            //                                 color: Colors.amber,
            //                               ),
            //                               onRatingUpdate: (rating) {
            //                                 // You can update the rating if needed
            //                               },
            //                             ),
            //                             SizedBox(height: 8),
            //                             Container(
            //                               height: 70,
            //                               child: SingleChildScrollView(
            //                                 child: Padding(
            //                                   padding: const EdgeInsets.only(top: 10.0),
            //                                   child: Text(
            //                                     myBooks[index].author,
            //                                     textAlign: TextAlign.center,
            //                                     style: TextStyle(
            //                                       color: Colors.black,
            //                                     ),
            //                                   ),
            //                                 ),
            //                               ),
            //                             ),
            //                             Row(
            //                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 ElevatedButton(
            //                                   onPressed: () {
            //                                     Navigator.push(context, MaterialPageRoute(builder: (context)=>TimerPage(book: myBooks[index],)));
            //                                   },
            //                                   child: Text("Read"),
            //                                   style: ButtonStyle(
            //                                     backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
            //                                     minimumSize: MaterialStateProperty.all<Size>(Size(double.minPositive,40)),
            //                                     shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            //                                       RoundedRectangleBorder(
            //                                         borderRadius: BorderRadius.circular(15.0),
            //                                       ),
            //                                     ),
            //                                   ),
            //                                 ),
            //                                 ElevatedButton(
            //                                   onPressed: () {
            //                                     _showRemoveBookDialog(myBooks[index]);
            //                                   },
            //                                   child: Text("Remove"),
            //                                   style: ButtonStyle(
            //                                     backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
            //                                     shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            //                                       RoundedRectangleBorder(
            //                                         borderRadius: BorderRadius.circular(15.0),
            //                                       ),
            //                                     ),
            //                                   ),
            //                                 ),
            //                                 ElevatedButton(
            //                                   onPressed: () {
            //                                     _showAddNotesDialog(myBooks[index]);
            //                                   },
            //                                   child: Text("Share"),
            //                                   style: ButtonStyle(
            //                                     backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
            //                                     // minimumSize: MaterialStateProperty.all<Size>(Size(double.infinity, 50)),
            //                                     shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            //                                       RoundedRectangleBorder(
            //                                         borderRadius: BorderRadius.circular(15.0),
            //                                       ),
            //                                     ),
            //                                   ),
            //                                 ),
            //
            //                               ],
            //                             ),
            //                           ],
            //                         ),
            //                       ),
            //                     ),
            //                     Padding(
            //                       padding: const EdgeInsets.all(8.0),
            //                       child: Image.network(
            //                         myBooks[index].imageLink,
            //                         height: 200,
            //                         width: 200,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             );
            //           },
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            Positioned(
              top: 260,

              child:StreamBuilder<List<String>>(
                stream: getQuoteDataStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Show loading indicator while fetching data
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text('No quotes available');
                  } else {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      height: 100,
                      child: Column(
                        children: [
                          CarouselSlider(
                            items: snapshot.data!.map((quote) {
                              return Text(
                                '"$quote"',
                                style: TextStyle(fontSize: 14.0,fontWeight: FontWeight.bold,fontStyle: FontStyle.italic),
                              );
                            }).toList(),
                            options: CarouselOptions(
                              height: 20.0,
                              enableInfiniteScroll: true,
                              autoPlay: true,
                              autoPlayInterval: Duration(seconds: 3),
                              autoPlayAnimationDuration: Duration(milliseconds: 800),
                              autoPlayCurve: Curves.fastOutSlowIn,
                              pauseAutoPlayOnTouch: true,
                              enlargeCenterPage: true,
                              onPageChanged: (index, reason) {
                                _currentIndex = index;
                                // log(_currentIndex.toString());

                              },
                            ),

                          ),
                          // DotsIndicator(
                          //   dotsCount: snapshot.data!.length,
                          //   position: _currentIndex,
                          //   // decorator: DotsDecorator(
                          //   //   size: const Size.square(8.0),
                          //   //   activeSize: const Size(20.0, 8.0),
                          //   //   activeShape: RoundedRectangleBorder(
                          //   //     borderRadius: BorderRadius.circular(5.0),
                          //   //   ),
                          //   // ),
                          // ),
                        ],
                      ),

                    );
                  }
                },
              )
            ),

            Padding(
              padding: const EdgeInsets.only(top: 300.0),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height:MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Currently Reading",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                        Expanded(
                          child: myBooks.isEmpty?
                          Container(
                              height: 100,
                              child: Center(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("You don't have any book in your list",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),
                                  SizedBox(height: 10,),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBooks()));
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Image.asset('assets/self.png'),
                                        Image.asset('assets/self.png'),
                                        Image.asset('assets/self.png'),
                                        Image.asset('assets/self.png'),
                                        Image.asset('assets/self.png'),
                                      ],
                                    ),
                                  )
                                ],
                              )))
                              : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: myBooks.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>MyBooksDetailPage(book: myBooks[index],)));
                                },
                                child:Container(
                                  width: 250,
                                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      Positioned(
                                        top: 120,
                                        child: Container(
                                          // height: 300,
                                          width: 250,
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFD9D9D9),
                                            borderRadius: BorderRadius.circular(20.0),
                                          ),
                                          child: Column(
                                            children: [
                                              // SizedBox(height: 30,),
                                              // RatingBar.builder(
                                              //   initialRating: 2.5,
                                              //   minRating: 1,
                                              //   direction: Axis.horizontal,
                                              //   allowHalfRating: true,
                                              //   itemCount: 5,
                                              //   itemSize: 20,
                                              //   itemBuilder: (context, _) => Icon(
                                              //     Icons.star,
                                              //     color: Colors.amber,
                                              //   ),
                                              //   onRatingUpdate: (rating) {
                                              //     // You can update the rating if needed
                                              //   },
                                              // ),
                                              SizedBox(height: 8),
                                              Container(
                                                height: 70,
                                                child: SingleChildScrollView(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 30.0),
                                                    child: Text(
                                                      myBooks[index].author,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 20,),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.push(context, MaterialPageRoute(builder: (context)=>TimerPage(book: myBooks[index],)));
                                                    },
                                                    child: Text("Read"),
                                                    style: ButtonStyle(
                                                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                                                      minimumSize: MaterialStateProperty.all<Size>(Size(double.minPositive,40)),
                                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(15.0),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _showRemoveBookDialog(myBooks[index]);
                                                    },
                                                    child: Text("Remove"),
                                                    style: ButtonStyle(
                                                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(15.0),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _showAddNotesDialog(myBooks[index]);
                                                    },
                                                    child: Text("Share"),
                                                    style: ButtonStyle(
                                                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                                                      // minimumSize: MaterialStateProperty.all<Size>(Size(double.infinity, 50)),
                                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(15.0),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.network(
                                          myBooks[index].imageLink,
                                          height: 150,
                                          width: 150,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20,),
                        Text("Explore",style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold),),

                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 250,
                                margin: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    Positioned(
                                      top: 120,
                                      child: Container(
                                        height: 150,
                                        width: 250,
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFD9D9D9),
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              height: 30,
                                            ),
                                            SizedBox(height: 8),
                                            Container(
                                              child: SingleChildScrollView(
                                                child: Padding(
                                                  padding: const EdgeInsets.only(top: 10.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                    children: [
                                                      Text(
                                                        books[index].title,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      ElevatedButton(
                                                        // key: readKey,
                                                        onPressed: () {
                                                          guestLogin==true?_showPersistentBottomSheet( context): _showConfirmationDialog(books[index].title, books[index].imageLink,books[index].description);
                                                        },
                                                        child: Text("Add to list"),
                                                        style: ButtonStyle(
                                                          backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                                                          minimumSize: MaterialStateProperty.all<Size>(Size(double.infinity, 50)),
                                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                            RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(15.0),
                                                            ),
                                                          ),
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
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.network(
                                        books[index].imageLink,
                                        height: 150,
                                        width: 150,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 200.0),
                            child: GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBooks()));
                              },
                              child: Text(
                                "More books>>", // Add your additional text here
                                style: TextStyle(
                                    color: Colors.black,
                                    decoration: TextDecoration.underline
                                ),
                                key: moreKey,
                              ),
                            ),
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
    );
  }
  void _showAddNotesDialog(DetailBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController notesController = TextEditingController();

        return AlertDialog(
          title: Text('Add Notes'),
          content: TextField(
            controller: notesController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Write your notes here...',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String newNote = notesController.text.trim();
                if (newNote.isNotEmpty) {
                  shareBookDetails(book,notesController.text);
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Note added successfully!'),
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
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