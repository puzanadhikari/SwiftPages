import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:swiftpages/ui/spashScreen.dart';

import '../myBooks.dart';

class MyBooksDetailPage extends StatefulWidget {
  DetailBook? book;

  MyBooksDetailPage({Key? key, this.book}) : super(key: key);

  @override
  _MyBooksDetailPageState createState() => _MyBooksDetailPageState();
}

class _MyBooksDetailPageState extends State<MyBooksDetailPage> {
  TextEditingController _textFieldController = TextEditingController();
  int? selectedPageNumber;
  String dropdownValue = 'Reading';
  // int totalPages = widget.book.totalPage;

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
          // books.remove(book);
        });

        print('Book removed successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error removing book: $e');
    }
  }

  void _showConfirmationDialog(DetailBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit User Name",
            style: TextStyle(color: Colors.blue), // Set title text color
          ),
          content: Text("Are you sure want to remove the book from your list?"),
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
                removeBook(book);
                Navigator.pop(context); // Close the dialog
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
  double calculatePercentage() {
    if (widget.book==null) {
      return 0.0; // Avoid division by zero
    }


    // int totalPages = totalPages; // Adjust maxPagesPerBook as needed
    // int totalReadPages = books.fold(0, (sum, book) => sum + book.currentPage);

    return ( widget.book!.currentPage/(widget.book!.totalPage==0?150:widget.book!.totalPage) ) * 100;
  }
  void updatePageNumber(DetailBook book, int newPageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books');

        // Update the page number in the Firestore document
        await myBooksRef
            .doc(book.documentId)
            .update({'currentPage': newPageNumber});

        // Update the local state with the new page number
        setState(() {
          book.currentPage = newPageNumber;
        });

        print('Page number updated successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error updating page number: $e');
    }
  }
  // void addNote(DetailBook book, String newNote) async {
  //   try {
  //     User? user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       String uid = user.uid;
  //
  //       CollectionReference myBooksRef =
  //       FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');
  //
  //       // Update the notes in the Firestore document
  //       await myBooksRef.doc(book.documentId).update({
  //         'notes': FieldValue.arrayUnion([newNote]),
  //       });
  //
  //       // Update the local state with the new notes
  //       setState(() {
  //         book.notes.add(newNote);
  //       });
  //
  //       print('Note added successfully!');
  //     } else {
  //       print('No user is currently signed in.');
  //     }
  //   } catch (e) {
  //     print('Error adding note: $e');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    selectedPageNumber = widget.book!.currentPage;
    log(widget.book!.totalPage.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEEAD4),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
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
                left: MediaQuery.of(context).size.width / 2.5,
                child: const Text(
                  "My books",
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
                top: 20,
                right: 50,
                child: GestureDetector(
                  onTap: () {},
                  child: SvgPicture.asset(
                    'assets/logoutIcon.svg',
                    height: 20,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 0,
                        left: 30,
                        child: Container(
                          height: 250,
                          width: 250,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9D9D9),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Container(
                                height: 150, // Set a fixed height for description
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10.0),
                                      child: Text(
                                        "Currently Reading",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color(0xFF283E50),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24),
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 5.0),
                                        child: Text(
                                          widget.book!.author,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: Color(0xFF686868),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 105,
                        right: 20,
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: calculatePercentage()/100,
                                  strokeWidth: 5.0,
                                  // Adjust the stroke width as needed
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF283E50),
                                  ), // Adjust the color as needed
                                ),
                                Positioned(
                                  top: 10,
                                  left: 5,
                                  child: Text(
                                    "${calculatePercentage().toStringAsFixed(1)}%",
                                    style: TextStyle(
                                        color: Color(0xFF283E50),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "Progress",
                              style: TextStyle(
                                  color: Color(0xFF686868), fontSize: 14),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Image.asset(
                              "assets/notes.png",
                              height: 50,
                            ),
                            Text(
                              "Notes",
                              style: TextStyle(
                                  color: Color(0xFF686868), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 100.0, right: 80),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            widget.book!.imageLink,
                            height: 200,
                            width: 200,
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
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            (loadingProgress.expectedTotalBytes ??
                                                1)
                                        : null,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).size.height / 2),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    // color: Colors.grey[200],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          DropdownButton<int>(
                            value: selectedPageNumber==0?1:selectedPageNumber,
                            icon: Icon(Icons.arrow_drop_down),
                            iconSize: 36,
                            elevation: 16,
                            style: TextStyle(color: Colors.black, fontSize: 18),
                            underline: Container(
                              height: 2,
                              color: Colors.white,
                            ),
                            items: List.generate(widget.book!.totalPage==0?150:widget.book!.totalPage, (index) => index + 1)
                                .map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedPageNumber = newValue;
                                  // selectedPageNumber==widget.book!.totalPage?updateStatusOfBook(widget.book!.documentId):
                                  updatePageNumber(widget.book!, selectedPageNumber!);
                                });
                              }
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              _showConfirmationDialog(widget.book!);

                            },
                            child: Icon(Icons.delete)
                          ),
                  DropdownButton<String>(
                    value: dropdownValue,
                    icon: const Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                        updateStatusOfBook(widget.book!.documentId);
                      });

                    },
                    items: <String>['Reading', 'Completed', 'To Read']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  )
                        ],
                      ),
                      TextField(
                        controller: _textFieldController,
                        decoration: InputDecoration(
                          hintText: 'Add Note',
                          suffixIcon: IconButton(
                            onPressed: () {
                              String newNote = _textFieldController.text.trim();
                              if (newNote.isNotEmpty) {
                                // addNote(widget.book!, newNote);
                                _textFieldController.clear();
                                Fluttertoast.showToast(
                                  msg: "Note added successfully!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.green,
                                  textColor: Colors.white,
                                );
                              }
                            },
                            icon: Icon(Icons.add),
                          ),
                        ),
                      ),
                      // Container(
                      //   width: MediaQuery.of(context).size.width,
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(10),
                      //     color: Colors.grey[200],
                      //   ),
                      //   padding: EdgeInsets.all(12),
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: widget.book!.notes.map((note) {
                      //       return Padding(
                      //         padding: EdgeInsets.symmetric(vertical: 8),
                      //         child: Text(
                      //           note,
                      //           style: TextStyle(fontSize: 16, color: Color(0xFF686868)),
                      //         ),
                      //       );
                      //     }).toList(),
                      //   ),
                      // ),
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

  void updateStatusOfBook(String bookId)async{

    FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

// Reference to the 'myBooks' collection with the UID as the document ID
    CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

// Specify the ID of the book you want to update
    String bookIdToUpdate = bookId; // Replace with the actual ID

// Fetch the specific book document
    DocumentSnapshot bookSnapshot = await myBooksRef.doc(bookIdToUpdate).get();

    if (bookSnapshot.exists) {
      // Access the document data
      Map<String, dynamic> bookData = bookSnapshot.data() as Map<String, dynamic>;

      // Print the current status for reference
      print('Current Status: ${bookData['status']}');

      // Update the status to 'CURRENTLY READING'
      await myBooksRef.doc(bookIdToUpdate).update({'status': dropdownValue=='Completed'?'COMPLETED':dropdownValue=='Reading'?'CURRENTLY READING':'TO BE READ'});

      print('Status updated successfully');
    } else {
      // Handle the case where the specified book does not exist
      print('Book with ID $bookIdToUpdate does not exist.');
    }

  }
}
