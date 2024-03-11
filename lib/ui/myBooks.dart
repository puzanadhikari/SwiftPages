import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:swiftpages/ui/timerPage/ui.dart';

import 'books/allBooks.dart';
import 'books/detailEachForBookStatus.dart';
import 'books/reviewDonePages.dart';
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
  String _selectedItem = '';
  bool _isDropdownOpen = false;
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
  final List<String> items = [
    'Item1',
    'Item2',
    'Item3',
    'Item4',
    'Item5',
    'Item6',
    'Item7',
    'Item8',
  ];
  String? selectedValue;
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
      Fluttertoast.showToast(msg: "Book saved to currently reading successfully!",backgroundColor: Color(0xFFFF997A));
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

          Fluttertoast.showToast(msg: "Book saved successfully!",backgroundColor: Color(0xFFFF997A));
        } else {
          Fluttertoast.showToast(msg: "Book already exists!",backgroundColor: Color(0xFFFF997A));
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
  Future<void> _refresh(){
    return fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: Color(0xff283E50),
        onRefresh: _refresh,
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
                    child: SvgPicture.asset(
                        "assets/Ellipse1.svg",
                        fit: BoxFit.fill
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
                      onTap: (){
                        Navigator.push(context, MaterialPageRoute(builder: (context)=>AllBooks()));
                      },
                      child: Image.asset(
                        "assets/search.png",
                        height: 50,
                      ),
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
                          myBooksMyReads.isEmpty?Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Container(
                              height: 300,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.circular(40.0),
                              ),
                              child: Center(
                                child: Text(
                                  "No Books. Add Books",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:  Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,fontFamily:'font',
                                  ),
                                ),
                              ),
                            ),
                          ):  Container(
                            height: MediaQuery.of(context).size.height/2,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: myBooksMyReads.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context)=>ReviewDonePage(book: myBooksMyReads[index],)));

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
                                                // SizedBox(height: 30,),
                                                // RatingBar.builder(
                                                //   initialRating: myBooksMyReads[index].reviewsmyBooksMyReads[index].reviews[0]['rating'],
                                                //   minRating: 1,
                                                //   direction: Axis.horizontal,
                                                //   allowHalfRating: true,
                                                //   itemCount: 5,
                                                //   itemSize: 20,
                                                //   itemBuilder: (context, _) => Icon(
                                                //     Icons.star,
                                                //     color: Color(0xff283E50),
                                                //   ),
                                                //   onRatingUpdate: (rating) {
                                                //     // You can update the rating if needed
                                                //   },
                                                // ),
                                                SizedBox(height: 10),
                                                Container(
                                                  height: 70,
                                                  child: SingleChildScrollView(
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(top: 10.0),
                                                      child: Text(
                                                        myBooksMyReads[index].author,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                            color: Color(0xff283E50),
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
                                                        // shareBookDetailsForComplete(myBooksMyReads[index],myBooksMyReads[index].reviews[0]['review'],myBooksMyReads[index].reviews[0]['rating'],myBooksMyReads[index].reviews[0]['pace'],myBooksMyReads[index].reviews[0]['genre'],myBooksMyReads[index].reviews[0]['mood'],);
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
                          myBooksToBeRead.isEmpty?Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Container(
                              height: 300,
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD9D9D9),
                                borderRadius: BorderRadius.circular(40.0),
                              ),
                              child: Center(
                                child: Text(
                                  "No Books. Add Books",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color:  Colors.grey[700],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,fontFamily:'font',
                                  ),
                                ),
                              ),
                            ),
                          ):Container(
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
                                    width: 150,
                                    margin: EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [

                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.network(
                                            myBooksToBeRead[index].imageLink,
                                            height: 200,
                                            width: 200,
                                          ),
                                        ),
                                        Positioned(
                                          left:110 ,
                                          child:  DropdownButtonHideUnderline(
                                            child: CircleAvatar(
                                              backgroundColor: Color(0xFF283E50),
                                              child:DropdownButtonHideUnderline(
                                                child: DropdownButton2<String>(
                                                  isExpanded: true,
                                                  isDense: false,
                                                  hint: Container(
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color:Color(0xFF283E50),
                                                    ),

                                                    width: 30,
                                                    height: 30,
                                                    child: Padding(
                                                      padding: const EdgeInsets.only(left:8.0),
                                                      child: Icon(
                                                        Icons.list,
                                                        size: 25,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),

                                                  items: [
                                                    DropdownMenuItem<String>(
                                                      value: 'Read',
                                                      child: Text('Read', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF283E50),)),
                                                    ),
                                                    DropdownMenuItem<String>(
                                                      value: 'Remove',
                                                      child: Text('Remove', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color:Color(0xFF283E50),)),
                                                    ),
                                                    DropdownMenuItem<String>(
                                                      value: 'Share',
                                                      child: Text('Share', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color:Color(0xFF283E50),)),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    // Perform actions based on the selected item
                                                    if (value == 'Read') {
                                                      updateStatusOfBook('CURRENTLY READING', myBooksToBeRead[index].documentId);
                                                      setState(() {});
                                                    } else if (value == 'Remove') {
                                                      _showRemoveBookDialog(myBooksToBeRead[index]);
                                                    } else if (value == 'Share') {
                                                      _showAddNotesDialog(myBooksToBeRead[index]);
                                                    }
                                                  },
                                                  dropdownStyleData: DropdownStyleData(
                                                    width: 160,
                                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(14),
                                                      color: Colors.white,
                                                    ),
                                                    offset: const Offset(-20, 0),

                                                  ),

                                                  menuItemStyleData: const MenuItemStyleData(
                                                    height: 40,
                                                    padding: EdgeInsets.only(left: 14, right: 14),
                                                  ),
                                                  iconStyleData: IconStyleData(
                                                    iconSize: 0
                                                  ),
                                                ),
                                              ),

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
                  ),

                ],
              ),
            ),
          ),
          extendBody: true,
        ),
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
          backgroundColor: Color(0xffFEEAD4),
          title: Text('Add Notes',style: TextStyle(fontFamily: 'font',color: Color(0xFF283E50),),),
          content: TextField(
            controller: notesController,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: 'Write your notes here...',
              hintStyle: TextStyle(color: Color(0xFF283E50),fontFamily: 'font')
            ),
          ),
          actions: <Widget>[
            Container(
              width: 100,
              height: 45,
              decoration: BoxDecoration(
                color: Color(0xFF283E50),
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              // Add your action widgets here
              child: TextButton(
                onPressed: () {

                  Navigator.pop(context);

                },
                child: Text(
                  'Close',
                  style: TextStyle(
                      color: Colors.white,fontFamily: 'font'
                  ),
                ),
              ),
            ),
            Container(
              width: 100,
              height: 45,
              decoration: BoxDecoration(
                color: Color(0xFF283E50),
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              // Add your action widgets here
              child: TextButton(
                onPressed: () {

                  String newNote = notesController.text.trim();
                  if (newNote.isNotEmpty) {
                    shareBookDetails(book, notesController.text);

                    Navigator.pop(context);
                    notesController.clear();// Close the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Book shared successfully!',style: TextStyle(fontFamily: 'font'),),
                      ),
                    );
                  }
                },
                child: Text(
                  'Share',
                  style: TextStyle(
                      color: Colors.white,fontFamily: 'font'
                  ),
                ),
              ),
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
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Column(
            children: [
              Text('Remove Book',style: TextStyle(fontFamily: 'font',color: Color(0xFF283E50)),),
              Divider(
                color: Color(0xFF283E50),
                thickness: 1,
              ),
            ],
          ),
          content: Text("Are you sure want to remove the book from your read list?",style: TextStyle(fontFamily: 'font',color: Colors.grey[700]),),
          actions: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
              Navigator.pop(context);
                  },
                  child: Text("Cancel",style: TextStyle(  fontFamily: 'font'),),
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
                    // Handle remove action
                    removeBook(book);
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
              ],
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
  final bool increaseStrike; // Updated to bool type
  int currentPage;
  int totalPage;
  double rating;
  List<Map<String, dynamic>> notes;
  List<Map<String, dynamic>> quotes;
  List<Map<String, dynamic>> reviews;

  DetailBook({
    required this.author,
    required this.imageLink,
    required this.documentId,
    required this.description,
    required this.publishedDate,
    required this.status,
    required this.startingDate,
    required this.increaseStrike, // Updated to bool type
    this.currentPage = 0,
    this.totalPage = 0,
    required this.rating,
    this.notes = const [],
    this.quotes = const [],
    this.reviews = const [],
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
        increaseStrike: false, // Default value for bool
        totalPage: 100,
        rating: 0.0
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
      increaseStrike: map['increaseStrike'] ?? false, // Parse as bool
      currentPage: map['currentPage'] ?? 0,
      totalPage: map['totalPageCount'] ?? 0,
      rating: map['rating']??0.0,
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? []),
      quotes: List<Map<String, dynamic>>.from(map['quotes'] ?? []),
      reviews: List<Map<String, dynamic>>.from(map['reviews'] ?? []),
    );
  }
}
class MenuItem {
  const MenuItem({
    required this.text,
    required this.icon,
  });

  final String text;
  final IconData icon;
}

abstract class MenuItems {
  static const List<MenuItem> firstItems = [home, share, settings];

  static const home = MenuItem(text: 'Read', icon: Icons.book);
  static const share = MenuItem(text: 'Remove', icon: Icons.delete);
  static const settings = MenuItem(text: 'Share', icon: Icons.share);

  static Widget buildItem(MenuItem item) {
    return Row(
      children: [
        Icon(item.icon, color: Color(0xFF283E50), size: 22),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Text(
            item.text,
            style: const TextStyle(
              color: Color(0xFF283E50),
            ),
          ),
        ),
      ],
    );
  }

  static void onChanged(BuildContext context, MenuItem item) {
    switch (item) {
      case MenuItems.home:

        break;
      case MenuItems.settings:
      // Do something
        break;
      case MenuItems.share:
      // Do something
        break;
    }
  }
}
