import 'dart:developer';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'myBooks.dart';


class ReviewPage extends StatefulWidget {
  DetailBook book;

  ReviewPage({Key? key, required this.book}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
double rating=0.0;
TextEditingController reviewController = TextEditingController();
List <String > pace = [
  'Slow',
  'Medium',
  'Fast',
];
List <String > genre = [];
List <String > mood = [];
String selectedPace = '';
String selectedGenre = '';
String selectedMood = '';
String startDate = '';
DateTime? finishedDate ;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
Future<void> fetchData() async {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  try {
    DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
        .collection('myBooks')
        .doc(_auth.currentUser?.uid).collection('books').doc(widget.book.documentId)
        .get();

    if (userDoc.exists) {
      setState(() {
        startDate = userDoc.get('startingDate') ?? '';
        log(startDate);
        // finishedDate = userDoc.get('finishedDate') ?? 0;
      });
    }
  } catch (error) {
    //log('Error fetching data: $error');
  }
}
  @override
  void initState() {
    super.initState();
    fetchData();

  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFD9D9D9),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Stack(
            children: [
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),

                    ),

                  ),
                  child: TextButton(
                    onPressed: () async {
                      int? result = await showDialog<int>(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomAlertDialog(book:widget.book,totalPage: widget.book.totalPage,currentPage: widget.book.currentPage,newReview: reviewController.text.toString(),selectedPace: selectedPace,rating: rating,genre: selectedGenre,mood: selectedMood,);
                        },
                      );

                      if (result != null) {
                        // Do something with the selected number
                        print('Selected Number: $result');
                      }
                    },

                    child: Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: Text('Rate The Book',style: TextStyle(
                    color:  Color(0xff283E50),fontSize: 24,fontWeight: FontWeight.bold
                ),)),
              ),


              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.topLeft,
                          children: [

                            Padding(
                              padding: const EdgeInsets.only(top:30.0),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(30.0),
                                    child: Image.network(
                                      widget.book.imageLink,
                                      height: 200,
                                      width: 150,
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
                                                  ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                      .expectedTotalBytes ??
                                                      1)
                                                  : null,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 10,),

                                  // Container(
                                  //   height: 40,
                                  //   width: 100,
                                  //   child: ElevatedButton(
                                  //     onPressed: _startPauseTimer,
                                  //     style: ElevatedButton.styleFrom(
                                  //       primary: Color(0xff283E50), // Set your desired button color
                                  //       shape: RoundedRectangleBorder(
                                  //         borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
                                  //       ),
                                  //     ),
                                  //     child: Padding(
                                  //       padding: const EdgeInsets.all(10.0), // Adjust the padding as needed
                                  //       child:Text(
                                  //         _isRunning ? 'Pause' : 'Start',
                                  //         style: TextStyle(fontSize: 16.0),
                                  //       ),
                                  //     ),
                                  //   ),
                                  // )
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                            // width: 200,
                            child: Center(child: Text(widget.book.author,style: TextStyle(color: Color(0xff686868),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 16),))),

                        RatingBar.builder(
                          glow: false,
                          initialRating: rating,
                          minRating: 0,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 40,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Color(0xFF283E50),
                          ),
                          onRatingUpdate: (value) {
                          setState(() {
                            rating = value;
                          });
                          },
                        ),
                        Divider(
                          color:Color(0xffFEEAD4) ,
                          thickness: 1,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  Text("Starting Date",style: TextStyle(color: Color(0xff686868),fontSize: 12,fontWeight: FontWeight.bold,fontFamily: 'font'),),
                                  SizedBox(height: 5,),
                                  Text(startDate,style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold,fontFamily: 'font'),),
                                ],
                              ),
                              Column(
                                children: [
                                  Text("Finished Date",style: TextStyle(color: Color(0xff686868),fontSize: 12,fontWeight: FontWeight.bold,fontFamily: 'font'),),
                                  SizedBox(height: 5,),
                                  Text(DateTime.now().year.toString()+'/'+DateTime.now().month.toString()+'/'+DateTime.now().day.toString(),style: TextStyle(color: Color(0xff283E50),fontSize: 20,fontWeight: FontWeight.bold,fontFamily: 'font'),),
                                ],
                              ), ],
                          ),
                        ),

                        Divider(
                          color:Color(0xffFEEAD4) ,
                          thickness: 1,
                        ),

                        Text("Review",  style: const TextStyle(
                            color: Color(0xFF283E50),
                            fontWeight: FontWeight.bold,fontFamily:'font',
                            fontSize: 20),),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onTap: (){
                              _showAddReviewDialog(widget.book);
                            },
                            child: Container(
                              // height: 250,
                              width: MediaQuery.of(context).size.width,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEEAD4),
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reviewController.text.isEmpty?'Add your review here':reviewController.text, style: TextStyle(color:  Color(0xFF283E50) ,fontWeight: FontWeight.bold,fontFamily: 'font'),),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20,),
                        Text("Pace of the Book",  style: const TextStyle(
                            color: Color(0xFF283E50),
                            fontWeight: FontWeight.bold,fontFamily:'font',
                            fontSize: 24),),
                        SizedBox(height: 20,),
                        Container(
                          width: 300,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10.0,
                              mainAxisSpacing: 10.0,
                            ),
                            itemCount: pace.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedPace = pace[index];
                                    log(selectedPace.toString());
                                  });
                                },
                                child: Container(
                                  // width: 100.0,
                                  // height: .0,
                                  decoration: BoxDecoration(


                                    shape: BoxShape.rectangle,
                                    color: selectedPace == pace[index] ? Color(0xFF283E50) : Color(0xfffeead4),
                                    border: Border.all(
                                      color: selectedPace == pace[index] ? index % 2 == 0 ? Color(0xFF283E50) : Color(0xfffeead4) : Colors.transparent,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(pace[index], style: TextStyle(color: selectedPace != pace[index] ? Color(0xFF283E50) : Color(0xfffeead4),fontWeight: FontWeight.bold,fontFamily: 'font'),),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20,),
                        Text("Genre Tags",  style: const TextStyle(
                            color: Color(0xFF283E50),
                            fontWeight: FontWeight.bold,fontFamily:'font',
                            fontSize: 24),),
                        SizedBox(height: 20,),

                        StreamBuilder(
                          stream: FirebaseFirestore.instance.collection('genre').doc('LRagKW0Akvpz8E8cquRW').snapshots(),
                          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (!snapshot.hasData) {
                              return CircularProgressIndicator();
                            }

                            if (!snapshot.data!.exists) {
                              return Text('Document does not exist');
                            }

                            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                            List<String> names = List.from(data['names']);

                            return Container(
                              width: MediaQuery.of(context).size.width,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Color(0xFFD9D9D9),
                              ),

                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4.0,
                                    mainAxisSpacing: 16.0,
                                    childAspectRatio: 2.0
                                ),
                                itemCount: names.length,
                                itemBuilder: (context, index) {
                                  final isSelected = selectedGenre == names[index];
                                  return GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        selectedGenre = names[index];
                                        log(selectedGenre.toString());
                                      });
                                    },
                                    child: Card(
                                      child: Container(
                                          width: 200,
                                          height: 100,
                                          color: isSelected ? Color(0xFF283E50): Color(0xFFFEEAD4),
                                          child: Center(child: Text(names[index],style: TextStyle(fontWeight: FontWeight.bold,fontFamily:'font',color: isSelected?Color(0xFFFEEAD4):Color(0xFF283E50)),))),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20,),
                        Text("Mood Tags",  style: const TextStyle(
                            color: Color(0xFF283E50),
                            fontWeight: FontWeight.bold,fontFamily:'font',
                            fontSize: 24),),
                        SizedBox(height: 20,),

                        StreamBuilder(
                          stream: FirebaseFirestore.instance.collection('mood').doc('wMRGe5BuXbNeTkwOsNGh').snapshots(),
                          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (!snapshot.hasData) {
                              return CircularProgressIndicator();
                            }

                            if (!snapshot.data!.exists) {
                              return Text('Document does not exist');
                            }

                            Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                            List<String> names = List.from(data['names']);

                            return Container(
                              width: MediaQuery.of(context).size.width,
                              height: 150,
                              decoration: BoxDecoration(
                                color: Color(0xFFD9D9D9),
                              ),

                              child: GridView.builder(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 4.0,
                                    mainAxisSpacing: 16.0,
                                    childAspectRatio: 2.0
                                ),
                                itemCount: names.length,
                                itemBuilder: (context, index) {
                                  final isSelected = selectedMood == names[index];
                                  return GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        selectedMood = names[index];
                                        log(selectedMood.toString());
                                      });
                                    },
                                    child: Card(
                                      child: Container(
                                          width: 200,
                                          height: 100,
                                          color: isSelected ? Color(0xFF283E50): Color(0xFFFEEAD4),
                                          child: Center(child: Text(names[index],style: TextStyle(fontWeight: FontWeight.bold,fontFamily:'font',color: isSelected?Color(0xFFFEEAD4):Color(0xFF283E50)),))),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )

                      ],
                    ),
                  ),
                ),
              ),



            ],
          ),
        ),
        extendBody: true,

      ),
    );
  }
void _showAddReviewDialog(DetailBook book) {
  showDialog(

    context: context,
    builder: (BuildContext context) {

      TextEditingController pageNumberController = TextEditingController();

      return AlertDialog(
        backgroundColor: Color(0xffFEEAD4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
        ),
        title: Text('Review',style: TextStyle(fontFamily: 'font'),),

        content: Container(
          height: 50,
          decoration: BoxDecoration(
            color:Colors.grey[100],
            borderRadius: BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left:8.0),
                  child: TextField(
                    controller: reviewController,
                    onChanged: (value) {

                    },
                    cursorColor: Color(0xFFD9D9D9),
                    decoration: InputDecoration(
                      hintText: 'Write Your Review',
                      hintStyle: TextStyle(color: Colors.grey,fontFamily: 'font'),
                      border: InputBorder.none,

                    ),

                  ),
                ),
              ),

            ],
          ),
        ),
        actions: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF283E50),
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),

                  ),

                ),
                child: TextButton(
                  onPressed: (){
                    setState(() {
                      String newReview = reviewController.text.trim();
                      if (newReview.isNotEmpty) {

                        // reviewController.clear();
                        Fluttertoast.showToast(
                          msg: "Review added successfully!",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Color(0xFF283E50),
                          textColor: Colors.white,
                        );
                        Navigator.pop(context);
                      }
                    });
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(color: Colors.white,fontFamily: 'font'),
                  ),
                ),
              ),
            ),
          ),

        ],
      );
    },
  );
}


}


class CustomAlertDialog extends StatefulWidget {
  DetailBook book;
  final int totalPage;
  final int currentPage;
  String newReview;
  String selectedPace;
  double rating;
  String genre;
  String mood;

  CustomAlertDialog({required this.book,required this.totalPage,required this.currentPage,required this.newReview,required this.selectedPace,required this.rating,required this.genre,required this.mood});

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  int selectedNumber = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedNumber = widget.currentPage;
  }
  void addReview(DetailBook book, String newReview) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;
        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'reviews': FieldValue.arrayUnion([
            {'review': newReview,
              'pace':widget.selectedPace,
              'rating':widget.rating,
              'genre':widget.genre,
              'mood':widget.mood
            }
          ]),
        });
        log(newReview.toString());
        log(widget.selectedPace.toString());
        log(widget.rating.toString());

        setState(() {
          book.notes.add({'review': newReview,});
        });

        print('Note added successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding note: $e');
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
          'userId':uid,
          'rating':widget.rating,
          'pace':widget.selectedPace,
          'genre':widget.genre,
          'mood':widget.mood
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
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          Text('Done Reviewing?',style: TextStyle(color:  Color(0xff283E50),fontFamily: 'font'),),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
  ],
      ),

      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {
                      addReview(widget.book, widget.newReview);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      setState(() {

                      });
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {
                      addReview(widget.book, widget.newReview);
                      shareBookDetails(widget.book, widget.newReview);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      setState(() {

                      });
                    },
                    child: Text(
                      'Save and share',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

      ],
    );
  }


  void updateStatusOfBook(String status)async{

    FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

// Reference to the 'myBooks' collection with the UID as the document ID
    CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

// Specify the ID of the book you want to update
    String bookIdToUpdate = widget.book.documentId; // Replace with the actual ID

// Fetch the specific book document
    DocumentSnapshot bookSnapshot = await myBooksRef.doc(bookIdToUpdate).get();

    if (bookSnapshot.exists) {
      // Access the document data
      Map<String, dynamic> bookData = bookSnapshot.data() as Map<String, dynamic>;

      // Print the current status for reference
      print('Current Status: ${bookData['status']}');

      // Update the status to 'CURRENTLY READING'
      await myBooksRef.doc(bookIdToUpdate).update({'status': status});

      print('Status updated successfully');
    } else {
      // Handle the case where the specified book does not exist
      print('Book with ID $bookIdToUpdate does not exist.');
    }

  }
  void updatePageNumber(DetailBook book, int newPageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

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
}
