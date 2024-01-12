import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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

  List<Book> books = [];

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
        // Handle the case when "results" key is not present in the response
        print("Error: 'results' key not found in the response");
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
              left: MediaQuery.of(context).size.width / 2.5,
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
                                      SizedBox(
                                        height: 30,
                                      ),
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
                                        height:
                                        200, // Set a fixed height for description
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.only(top: 10.0),
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

                            ],
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
