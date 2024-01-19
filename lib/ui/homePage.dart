import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swiftpages/ui/timerPage/ui.dart';

import 'books/allBooks.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  final String apiKey =
      "30fe2ae32emsh0b5a48e1d0ed53dp17a064jsn7a2f3e3aca01";
  final String apiUrl =
      "https://book-finder1.p.rapidapi.com/api/search?page=2";
  int strikesCount = 0;

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

        // Update the UI with the new strikes count
        setState(() {});
      }
    } catch (e) {
      print('Error fetching strikes: $e');
    }
  }
  void saveMyBook(String author, String image) async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to associate books with the user
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Check if the book with the same author and image already exists
        QuerySnapshot existingBooks = await myBooksRef
            .where('author', isEqualTo: author)
            .where('image', isEqualTo: image)
            .get();

        if (existingBooks.docs.isEmpty) {
          // Book does not exist, add it to the collection
          Map<String, dynamic> bookData = {
            'image': image,
            'author': author,
            // Add other book details as needed
          };

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
  String email = ' ';
  String userName = ' ';

  Future<void> fetchBooks() async {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        "X-RapidAPI-Key": apiKey,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data.containsKey("results")) {
        final List<dynamic> results = data["results"];

        // Fetch only the first 5 books
        List<dynamic> firstFiveBooks = results.take(5).toList();

        setState(() {
          books = firstFiveBooks.map((result) => Book.fromMap(result)).toList();
        });
      } else {
        print("Error: 'results' key not found in the response");
      }
    } else {
      // Handle errors
      print("Error: ${response.statusCode}");
    }
  }

  Future<void> fetchUserInfo() async {
SharedPreferences preferences = await SharedPreferences.getInstance();
email  = preferences.getString("email")!;
userName  = preferences.getString("userName")!;
  }

  @override
  void initState() {
    super.initState();
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String uid = user.uid;
      _userStream =
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
      fetchStrikes();
    }
      fetchBooks();
    fetchUserInfo();

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
                "Welcome ${userName} !!",
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5,),
                        const Text(
                        "Today's Goal",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 5,),
                        const Text(
                          "Today: 30 mins",
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
                            const Text(
                              "Completed: 10 mins",
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
                  ),
                  Text("${strikesCount}", style: TextStyle(
                    fontSize: 14,
                    color: Color(0xfffeead4),
                  )),

                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 260.0),
              child: Column(
                children: [
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
                                                  books[index].author,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    _showConfirmationDialog(books[index].author, books[index].imageLink);
                                                  },
                                                  child: Text("Read"),
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
                      padding: const EdgeInsets.only(bottom: 150.0),
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
    );
  }
  void _showConfirmationDialog(String author,String image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit User Name",
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
                    saveMyBook( author,image);
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
}

class Book {
  final String author;
  final String imageLink;

  Book({required this.author, required this.imageLink});

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      author: map['title'] ?? 'No Author',
      imageLink: map['published_works'][0]['cover_art_url'] ?? 'No Image',
    );
  }
}
