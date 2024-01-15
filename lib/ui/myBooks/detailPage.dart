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
  Book? book;

  MyBooksDetailPage({Key? key, this.book}) : super(key: key);

  @override
  _MyBooksDetailPageState createState() => _MyBooksDetailPageState();
}

class _MyBooksDetailPageState extends State<MyBooksDetailPage> {
  TextEditingController _textFieldController = TextEditingController();
  int selectedPageNumber = 1;
  int totalPages = 150;
  double calculatePercentage() {
    if (widget.book==null) {
      return 0.0; // Avoid division by zero
    }


    // int totalPages = totalPages; // Adjust maxPagesPerBook as needed
    // int totalReadPages = books.fold(0, (sum, book) => sum + book.currentPage);

    return ( widget.book!.currentPage/totalPages ) * 100;
  }
  void updatePageNumber(Book book, int newPageNumber) async {
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

  @override
  void initState() {
    super.initState();
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
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {},
                child: SvgPicture.asset(
                  'assets/logoutIcon.svg',
                  height: 30,
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
                      top: 100,
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
                                      fontSize: 12),
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
                  color: Colors.grey[200],
                ),
                child: DropdownButton<int>(
                  value: selectedPageNumber,
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 36,
                  elevation: 16,
                  style: TextStyle(color: Colors.black, fontSize: 18),
                  underline: Container(
                    height: 2,
                    color: Colors.blue,
                  ),
                  items: List.generate(1000, (index) => index + 1)
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
                        updatePageNumber(widget.book!, selectedPageNumber);
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
