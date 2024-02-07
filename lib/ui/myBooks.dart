import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:swiftpages/ui/timerPage/ui.dart';

import 'books/detailEachForBookStatus.dart';
import 'myBooks/detailPage.dart';

class MyBooks extends StatefulWidget {
  const MyBooks({Key? key}) : super(key: key);

  @override
  State<MyBooks> createState() => _MyBooksState();
}

class _MyBooksState extends State<MyBooks> {
  void shareBookDetailsForComplete(DetailBook book,String note,double rating,String pace,String genre,String mood) async {
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
          'userId':uid,
          'rating':rating,
          'pace':pace,
          'genre':genre,
          'mood':mood
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
  List<DetailBook> myBooksToBeRead = [];
  List<DetailBook> myBooksMyReads = [];
  List<DetailBook> books = [];
  final String apiKey =
      "AIzaSyBmb7AmvBdsQsQwLD1uTEuwTQqfDJm7DN0"; // Replace with your actual API key
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

        QuerySnapshot querySnapshotMyReads = await myBooksRef.where('status', isEqualTo: 'COMPLETED').get();


        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsMyReads = querySnapshotMyReads.docs;
        setState(() {

          myBooksMyReads = bookDocumentsMyReads
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();
          // print('Books: $myBooks'); // Check the console for the list of books
        });


        QuerySnapshot querySnapshotToBeRead = await myBooksRef.where('status', isEqualTo: 'TO BE READ').get();

        // Access the documents in the query snapshot
        List<DocumentSnapshot> bookDocumentsToBeRead = querySnapshotToBeRead.docs;
        setState(() {
          myBooksToBeRead = bookDocumentsToBeRead
              .map((doc) => DetailBook.fromMap(doc.id, doc.data() as Map<String, dynamic>?))
              .toList();

        });

        for (DocumentSnapshot doc in bookDocumentsToBeRead) {
          Map<String, dynamic> bookData = doc.data() as Map<String, dynamic>;






        }
      } else {
        // print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error fetching books: $e');
    }
  }
  void updateStatusOfBook(String status,String docId)async{

    FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

// Reference to the 'myBooks' collection with the UID as the document ID
    CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

// Specify the ID of the book you want to update
    String bookIdToUpdate = docId; // Replace with the actual ID

// Fetch the specific book document
    DocumentSnapshot bookSnapshot = await myBooksRef.doc(bookIdToUpdate).get();

    if (bookSnapshot.exists) {
      // Access the document data
      Map<String, dynamic> bookData = bookSnapshot.data() as Map<String, dynamic>;

      // Print the current status for reference
      print('Current Status: ${bookData['status']}');

      // Update the status to 'CURRENTLY READING'
      await myBooksRef.doc(bookIdToUpdate).update({'status': status});
      Fluttertoast.showToast(msg: "Book saved to currently reading successfully!");
      print('Status updated successfully');
    } else {
      // Handle the case where the specified book does not exist
      print('Book with ID $bookIdToUpdate does not exist.');
    }

  }
  void saveMyBook(String author, String image,int totalPage,String status,String publishedDate,String description) async {
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
            .where('totalPageCount', isEqualTo: totalPage)
            .get();

        if (existingBooks.docs.isEmpty) {
          // Book does not exist, add it to the collection
          Map<String, dynamic> bookData = {
            'image': image,
            'author': author,
            'totalPageCount': totalPage==0?150:totalPage,
            'status':status,
            'currentPage':0,
            'description':description,
            'publishedDate':publishedDate
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
        body: SingleChildScrollView(
          child: Container(
            // height: MediaQuery.of(context).size.height*1.5,
            child: Stack(
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
                      fontFamily: "font",
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xfffeead4),
                      height: 29 / 22,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top:100.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "My Reads",

                          style: TextStyle(
                            fontFamily: "font",
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xfffeead4),
                            height: 29 / 20,

                          ),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height/2,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: myBooksMyReads.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBookDetailPageEachStatus(book: myBooksMyReads[index],)));

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
                                                initialRating: myBooksMyReads[index].reviews[0]['rating'],
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
                                                      myBooksMyReads[index].author,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontFamily: 'font'
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
                                                      _showRemoveBookDialog(myBooksMyReads[index]);
                                                    },
                                                    child: Text("Remove",style: TextStyle(  fontFamily: 'font'),),
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
                                                      shareBookDetailsForComplete(myBooksMyReads[index],myBooksMyReads[index].reviews[0]['review'],myBooksMyReads[index].reviews[0]['rating'],myBooksMyReads[index].reviews[0]['pace'],myBooksMyReads[index].reviews[0]['genre'],myBooksMyReads[index].reviews[0]['mood'],);
                                                      _showAddNotesDialog(myBooksMyReads[index]);
                                                    },
                                                    child: Text("Share",style: TextStyle(  fontFamily: 'font'),),
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
                                          myBooksMyReads[index].imageLink,
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
                        Text(
                          "To Be Read",

                          style: TextStyle(
                            fontFamily: "font",
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF283E50),
                            height: 29 / 20,
                          ),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height/2,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: myBooksToBeRead.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBookDetailPageEachStatus(book: myBooksToBeRead[index],)));

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

                                              SizedBox(height: 8),
                                              Container(
                                                height: 70,
                                                child: SingleChildScrollView(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(top: 10.0),
                                                    child: Text(
                                                      myBooksToBeRead[index].author,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                          fontFamily: 'font'
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
                                                      updateStatusOfBook(
                                                        'CURRENTLY READING',
                                                        myBooksToBeRead[index].documentId,
                                                      );
                                                    setState(() {

                                                    });
                                                    },
                                                    child: Text("Read",style: TextStyle(    fontFamily: 'font'),),
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
                                                      _showRemoveBookDialog(myBooksToBeRead[index]);
                                                    },
                                                    child: Text("Remove",style: TextStyle(    fontFamily: 'font'),),
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
                                                      _showAddNotesDialog(myBooksToBeRead[index]);
                                                    },
                                                    child: Text("Share",style: TextStyle(    fontFamily: 'font'),),
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
                                          myBooksToBeRead[index].imageLink,
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
                ),

              ],
            ),
          ),
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
          title: Text('Add Notes',style: TextStyle(fontFamily: 'font'),),
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
              child: Text('Cancel',style: TextStyle(fontFamily: 'font'),),
            ),
            TextButton(
              onPressed: () {
                String newNote = notesController.text.trim();
                if (newNote.isNotEmpty) {
                  shareBookDetails(book, notesController.text);
                  Navigator.pop(context); // Close the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Book shared successfully!',style: TextStyle(fontFamily: 'font'),),
                    ),
                  );
                }
              },
              child: Text('Save',style: TextStyle(fontFamily: 'font'),),
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
          title: Text('Remove Book',style: TextStyle(fontFamily: 'font'),),
          content: Text("Are you sure wantt to remove the book from your read list?",style: TextStyle(fontFamily: 'font'),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel',style: TextStyle(fontFamily: 'font'),),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  removeBook(book);

                });
                Navigator.pop(context);
              },
              child: Text('Remove',style: TextStyle(fontFamily: 'font'),),
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
  final String publishedDate;
  final String status;
  final String startingDate;
  int currentPage;
  int totalPage;
  List<Map<String, dynamic>> notes;
  List<Map<String, dynamic>> quotes;
  List<Map<String, dynamic>> reviews; // Updated to list of maps

  DetailBook({
    required this.author,
    required this.imageLink,
    required this.documentId,
    required this.description,
    required this.publishedDate,
    required this.status,
    required this.startingDate,
    this.currentPage = 0,
    this.totalPage = 0,
    this.notes = const [],
    this.quotes = const [],
    this.reviews = const [], // Initialize reviews as an empty list of maps
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
        startingDate: 'startingDate',
        totalPage: 100,
      );
    }
    return DetailBook(
      author: map['author'] ?? 'No Author',
      imageLink: map['image'] ?? 'No Image',
      documentId: documentId,
      description: map['description'] ?? 'No Description',
      publishedDate: map['publishedDate'] ?? '-',
      status: map['status'] ?? '-',
      startingDate: map['startingDate'] ?? '-',
      currentPage: map['currentPage'] ?? 0,
      totalPage: map['totalPageCount'] ?? 0,
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? []),
      quotes: List<Map<String, dynamic>>.from(map['quotes'] ?? []),
      reviews: List<Map<String, dynamic>>.from(map['reviews'] ?? []),
    );
  }
}