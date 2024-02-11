import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'detailPage.dart';

class AllBooks extends StatefulWidget {
  @override
  State<AllBooks> createState() => _AllBooksState();
}

class _AllBooksState extends State<AllBooks> {
  TextEditingController searchController = TextEditingController();
  List<Book> books = [];
  List<Book> filteredBooks = [];
  String searchQuery = 'novels';
  @override
  void initState() {
    super.initState();
    // Set up a listener to call fetchBooks when the text changes
    searchController.addListener(() {
      fetchBooks(searchController.text);
    });

    // Initial fetch
    fetchBooks(searchController.text);
  }


  Future<void> fetchBooks(String search) async {
    final String apiKey = "AIzaSyBmb7AmvBdsQsQwLD1uTEuwTQqfDJm7DN0";
    final String apiUrl =
        "https://www.googleapis.com/books/v1/volumes?q=${search}&maxResults=40";

    final response = await http.get(Uri.parse(apiUrl + "&key=$apiKey"));

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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFEEAD4),
        body: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    height: 55,
                    decoration: ShapeDecoration(
                      color: Color(0xFFD9D9D9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(92),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search Books...',
                          hintStyle: TextStyle(
                            color: Color(0xFF283E50),
                            fontSize: 18,
                            fontFamily: 'font',
                            fontWeight: FontWeight.w700,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF283E50),
                          ),
                        ),
                        style: TextStyle(
                          color: Color(0xFF686868),
                          fontSize: 18,
                          fontFamily: 'font',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            searchController.text.isEmpty?Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top:80.0),
                child: SvgPicture.asset('assets/oops.svg',
                  height: 500,
                ),
              ),
            ): Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  return buildBookItem(books[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  void saveMyBook(String author, String image,int totalPage) async {
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
            'status':'TO BE READ',
            'currentPage':0
          };

          // Add the book data to the 'myBooks' collection
          await myBooksRef.add(bookData);

          Fluttertoast.showToast(msg: "Book saved successfully!",backgroundColor: Color(0xFFFF997A));
        } else {
          Fluttertoast.showToast(msg: "Book already exists!",backgroundColor:Color(0xFFFF997A));
        }
      } else {
        print('No user is currently signed in.',);
      }
    } catch (e) {
      print('Error saving book: $e');
    }
  }

  Widget buildBookItem(Book book) {
    return GestureDetector(
        onTap: (){
          log(book.imageLink.toUpperCase());
          // _showConfirmationDialog( book.title, book.imageLink,book.pageCount);
          Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBookDetailPage(book: book,)));
        },
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFF997A),
            borderRadius: BorderRadius.circular(31),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            book.imageLink=="No Image"?Container(
          width: 116,
            height: 100,
            decoration: ShapeDecoration(

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
            ),
              child: Center(child: Text("No Image")),
          ):  Container(
                width: 116,
                height: 100,
                decoration: ShapeDecoration(
                  image: DecorationImage(
                    image: NetworkImage(book.imageLink),
                    fit: BoxFit.fill,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              SizedBox(
                child: Text(
                  book.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF283E50),
                    fontSize: 12,
                    fontFamily: 'font',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showConfirmationDialog(String author,String image,int totalPage) {
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
                saveMyBook( author,image,totalPage);
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
  final String title;
  final String imageLink;
  final String description;
  final double rating;
  final int pageCount;
  final String publishedDate;

  Book({
    required this.title,
    required this.imageLink,
    required this.description,
    required this.rating,
    required this.pageCount,
    required this.publishedDate,

  });

  factory Book.fromMap(Map<String, dynamic> map) {
    final volumeInfo = map['volumeInfo'];
    return Book(
      description: volumeInfo['description'] ?? 'No Description',
      title: volumeInfo['title'] ?? 'No Title',
      imageLink: volumeInfo['imageLinks']?['thumbnail'] ?? 'No Image',
      rating: volumeInfo['averageRating']?.toDouble() ?? 0.0,
      pageCount: volumeInfo['pageCount'] ?? 0,
      publishedDate: volumeInfo['publishedDate'] ?? '-', // Extract and set the publication date

    );
  }
}
