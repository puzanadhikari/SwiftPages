import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MyBooks extends StatefulWidget {
  const MyBooks({Key? key}) : super(key: key);

  @override
  State<MyBooks> createState() => _MyBooksState();
}

class _MyBooksState extends State<MyBooks> {
  final String apiKey =
      "AIzaSyBmb7AmvBdsQsQwLD1uTEuwTQqfDJm7DN0"; // Replace with your actual API key
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
          books = bookDocuments
              .map((doc) => Book.fromMap(doc.data() as Map<String, dynamic>))
              .toList();    print('Books: $books'); // Check the console for the list of books
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
  List<Book> books = [];
  // Future<void> fetchBooks() async {
  //   final String apiUrl =
  //       "https://www.googleapis.com/books/v1/volumes?q=novels&maxResults=40";
  //
  //   final response =
  //   await http.get(Uri.parse(apiUrl + "&key=$apiKey"));
  //
  //   if (response.statusCode == 200) {
  //     // Parse the JSON response
  //     final Map<String, dynamic> data = json.decode(response.body);
  //
  //     // Process the data as needed
  //     if (data.containsKey("items")) {
  //       final List<dynamic> items = data["items"];
  //       if (_mounted) {
  //         setState(() {
  //           books = items.map((item) => Book.fromMap(item)).toList();
  //         });
  //       }
  //
  //     }
  //   } else {
  //     // Handle errors
  //     print("Error: ${response.statusCode}");
  //   }
  // }

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }
  bool _mounted = true;
  @override
  void dispose() {
    _mounted = false; // Add this line
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFEEAD4),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                'assets/Ellipse.png', // Replace with the correct image path
                // Adjust the width as needed
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
              child: Image.asset(
                "assets/search.png",
                height: 50,
              ),
            ),
            Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width / 3,
              child: Text(
                "My Books",
                style: const TextStyle(
                  fontFamily: "Abhaya Libre ExtraBold",
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfffeead4),
                  height: 29 / 22,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: (){},
                          child: Container(
                            width: 250,
                            margin: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Positioned(
                                  top: 180,
                                  child: Container(
                                    height: 300,
                                    width: 250,
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFD9D9D9),
                                      borderRadius: BorderRadius.circular(20.0),
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(height: 30,),
                                        RatingBar.builder(
                                          initialRating: 2.5,
                                          minRating: 1,
                                          direction: Axis.horizontal,
                                          allowHalfRating: true,
                                          itemCount: 5,
                                          itemSize: 20,
                                          itemBuilder: (context, _) => Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                          onRatingUpdate: (rating) {
                                            // You can update the rating if needed
                                          },
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          height: 200,
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.only(top: 10.0),
                                              child: Text(
                                                books[index].author,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
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
                                    height: 200,
                                    width: 200,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        extendBody: true,
      ),
    );
  }
}

class Book {
  final String author;
  final String imageLink;

  Book({
    required this.author,
    required this.imageLink,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      author: map['author'] ?? 'No Author',
      imageLink: map['image'] ?? 'No Image',
    );
  }
}

