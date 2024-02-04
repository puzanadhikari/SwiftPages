import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:swiftpages/ui/timerPage/ui.dart';

import 'myBooks/detailPage.dart';

class MyBooks extends StatefulWidget {
  const MyBooks({Key? key}) : super(key: key);

  @override
  State<MyBooks> createState() => _MyBooksState();
}

class _MyBooksState extends State<MyBooks> {
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

  List<DetailBook> books = [];
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
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();  print('Books: $books'); // Check the console for the list of books
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

  static const int maxPagesPerBook = 100;


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
    // log('Percentage of Books Read: ${calculatePercentage()}%');
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
                          onTap: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>MyBooksDetailPage(book: books[index],)));

                          },
                          child: Container(
                            width: 250,
                            margin: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                Positioned(
                                  top: 180,
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
                                          height: 70,
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (context)=>TimerPage(book: books[index],)));
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
                                                _showRemoveBookDialog(books[index]);
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
                                                _showAddNotesDialog(books[index]);
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

        // Remove the book from the state
        setState(() {
          books.remove(book);
        });

        print('Book removed successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error removing book: $e');
    }
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



}
class DetailBook {
  final String author;
  final String imageLink;
  final String documentId;
  final String description;
  final String publishedDate ;
  final String status ;
  int currentPage; // Add this field
  int totalPage; // Add this field
  List<String> notes; // Add this field
  List<String> quotes; // Add this field

  DetailBook({
    required this.author,
    required this.imageLink,
    required this.documentId,
    required this.description,
    required this.publishedDate,
    required this.status,
    this.currentPage = 0, // Set the default value to 0
    this.totalPage = 0, // Set the default value to 0
    this.notes = const [], // Initialize notes as an empty list
    this.quotes = const [], // Initialize notes as an empty list
  });

  factory DetailBook.fromMap(String documentId, Map<String, dynamic>? map) {
    if (map == null) {
      return DetailBook(
        author: 'No Author',
        imageLink: 'No Image',
        documentId: documentId,
          description: 'description',
          publishedDate: 'publishedDate',
          status: 'status',

        totalPage: 100
      );
    }
    return DetailBook(
      author: map['author'] ?? 'No Author',
      imageLink: map['image'] ?? 'No Image',
      documentId: documentId,
      description: map['description']??'No Description',
      publishedDate: map['publishedDate']??'-',
      status: map['status']??'-',
      currentPage: map['currentPage'] ?? 0, // Set the currentPage value
      totalPage: map['totalPageCount'] ?? 0, // Set the currentPage value
      notes: List<String>.from(map['notes'] ?? []), // Set the notes value
      quotes: List<String>.from(map['quotes'] ?? []), // Set the notes value
    );
  }
}
