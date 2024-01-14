import 'dart:convert';
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

  List<Book> books = [];

  Future<void> fetchBooks() async {
    final String apiUrl =
        "https://www.googleapis.com/books/v1/volumes?q=novels&maxResults=40";

    final response =
    await http.get(Uri.parse(apiUrl + "&key=$apiKey"));

    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> data = json.decode(response.body);

      // Process the data as needed
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

  @override
  void initState() {
    super.initState();
    fetchBooks();
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
                left: MediaQuery.of(context).size.width/2.5,
                child: Text("My Books",style: const TextStyle(
                  fontFamily: "Abhaya Libre ExtraBold",
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfffeead4),
                  height: 29/22,
                ),)
            ),
            Padding(
              padding: const EdgeInsets.only(top:100.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        height: 200, // Set a fixed height for description
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 10.0),
                                            child: Text(
                                              books[index].description,
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
                        );
                      },
                    ),
                  ),
                  // Other content below the horizontal list
                  // ...
                ],
              ),
            ),
          ],
        ),
        extendBody: true,
        bottomNavigationBar: FloatingNavbar(
          borderRadius: 40.0,
          selectedBackgroundColor: Color(0xFFD9D9D9),
          selectedItemColor: Color(0xffFF997A),
          unselectedItemColor:  Color(0xffFF997A),
          backgroundColor: Color(0xFF283E50),
          onTap: (int val) {
            //returns tab id which is user tapped
          },
          currentIndex:0,
          items: [
            FloatingNavbarItem(icon: Icons.home, title: 'Home'),
            FloatingNavbarItem(icon: Icons.explore, title: 'Explore'),
            FloatingNavbarItem(icon: Icons.chat_bubble_outline, title: 'Chats'),
            FloatingNavbarItem(icon: Icons.settings, title: 'Settings'),
          ],
        ),
      ),
    );
  }
}

class Book {
  final String title;
  final String imageLink;
  final String description;
  final double rating;

  Book({
    required this.title,
    required this.imageLink,
    required this.description,
    required this.rating,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    final volumeInfo = map['volumeInfo'];
    return Book(
      description: volumeInfo['description'] ?? 'No Description',
      title: volumeInfo['title'] ?? 'No Title',
      imageLink: volumeInfo['imageLinks']?['thumbnail'] ?? 'No Image',
      rating: volumeInfo['averageRating']?.toDouble() ?? 0.0,
    );
  }
}
