import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String apiKey =
      "30fe2ae32emsh0b5a48e1d0ed53dp17a064jsn7a2f3e3aca01";
  final String apiUrl =
      "https://book-finder1.p.rapidapi.com/api/search?page=2";

  void saveMyBook( String author,String image,) async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to associate books with the user
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Sample book data (customize based on your requirements)
        Map<String, dynamic> bookData = {
          'image': image,
          'author': author,
          // Add other book details as needed
        };

        // Add the book data to the 'myBooks' collection
        await myBooksRef.add(bookData);

        print('Book saved successfully!');
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
        setState(() {
          books = results.map((result) => Book.fromMap(result)).toList();
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
              child: Image.asset(
                "assets/search.png",
                height: 50,
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
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Image.asset(
                      "assets/strick.png",
                      height: 50,
                    ),
                  ),
                  Text("9",style: TextStyle(
                    fontSize: 14,
                    color: Color(0xfffeead4),
                  ),)
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 260.0),
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
                            _showConfirmationDialog(books[index].author,books[index].imageLink);
                          },
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
                                          height:
                                          150, // Set a fixed height for description
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Padding(
                                                padding:
                                                const EdgeInsets.only(top: 10.0),
                                                child: Text(
                                                  "Currently Reading",
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFF283E50),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 24
                                                  ),
                                                ),
                                              ),
                                              SingleChildScrollView(
                                                child: Padding(
                                                  padding:
                                                  const EdgeInsets.only(top: 5.0),
                                                  child: Text(
                                                    books[index].author,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Color(0xFF686868),
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500
                                                    ),
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
                                  right:20,
                                  child: Column(
                                    children: [
                                      Stack(
                                        children:[
                                          CircularProgressIndicator(
                                            value: 0.9,

                                            strokeWidth: 5.0, // Adjust the stroke width as needed
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF283E50),), // Adjust the color as needed
                                          ),
                                          Positioned(
                                            top: 10,
                                            left: 5,
                                            child: Text(
                                              "90%",
                                              style: TextStyle(
                                                color: Color(0xFF283E50),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14
                                              ),
                                            ),
                                          ),
                                        ],

                                      ),
                                      Text(
                                        "Progress",
                                        style: TextStyle(
                                            color: Color(0xFF686868),
                                            fontSize: 14
                                        ),
                                      ),
                                      SizedBox(height: 20,),

                                      Image.asset(
                                        "assets/notes.png",
                                        height: 50,
                                      ),
                                      Text(
                                        "Notes",
                                        style: TextStyle(
                                            color: Color(0xFF686868),
                                            fontSize: 14
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top:100.0,right:80),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.network(
                                      books[index].imageLink,
                                      height: 200,
                                      width: 200,
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) {
                                          // Image is fully loaded, display the actual image
                                          return child;
                                        } else {
                                          // Image is still loading, display a placeholder or loading indicator
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
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
                        );
                      },
                    ),
                  ),
                ],
              ),
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
          content: Text("Are you sure want to change your password?"),
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
