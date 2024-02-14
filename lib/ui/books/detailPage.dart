import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg instead of flutter_svg/svg.dart
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'allBooks.dart';

class AllBookDetailPage extends StatefulWidget {
  final Book book;

  AllBookDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  State<AllBookDetailPage> createState() => _AllBookDetailPageState();
}

class _AllBookDetailPageState extends State<AllBookDetailPage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    log(widget.book.publishedDate.toString());
  }
  List<int> year = [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024];
  List<int> days = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31
  ];

  List<String> month = [
    'Jan',
    'Feb',
    'March',
    'April',
    'May',
    'June',
    'July',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec'
  ];
  int selectedYear = 0;
  int selectedDays = 0;
  String selectedMonth = '';
  String gotDocId = '';

  Future<String?> saveMyBook(String author, String image, int totalPage, String status, String publishedDate, String description, double rating) async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to associate books with the user
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

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
            'totalPageCount': totalPage == 0 ? 150 : totalPage,
            'status': status,
            'currentPage': 0,
            'description': description,
            'publishedDate': publishedDate,
            'rating': rating
          };

          // Add the book data to the 'myBooks' collection
          DocumentReference newBookRef = await myBooksRef.add(bookData);

          Fluttertoast.showToast(msg: "Book saved successfully!", backgroundColor: Color(0xFFFF997A));
          setState(() {
            gotDocId = newBookRef.id;
          });
          int? result = await showDialog<int>(
            context: context,
            builder: (BuildContext context) {
              return
                CustomAlertForStartDateDialog(
                  year: year,
                  days: days,
                  month: month, gotId: newBookRef.id,
                );
            },
          );
          // _showInvitationCodePopupForStartingDate();
          return newBookRef.id;
        } else {
          Fluttertoast.showToast(msg: "Book already exists!", backgroundColor: Color(0xFFFF997A));
        }
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error saving book: $e');
    }

    return null; // Return null if there was an error or the book already exists
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xffFEEAD4),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child:Stack(
            children: [
              Positioned(
                top: 20,
                left: 30,
                child: GestureDetector(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: Icon(Icons.arrow_back,),
                ),
              ),
              // SvgPicture.asset('assets/background.svg',
              //   fit: BoxFit.cover,
              //   height: MediaQuery.of(context).size.height,
              //   color: Colors.grey.withOpacity(0.2),
              // ),
             Stack(
               children: [
                 Padding(
                   padding: const EdgeInsets.only(top:200.0,left: 20,right: 20),
                   child: SingleChildScrollView(
                     scrollDirection: Axis.vertical,
                     child: Container(
                       height: MediaQuery.of(context).size.height,
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(30),
                         color: Color(0xFFD9D9D9),
                       ),
                       child: Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Column(
                           children: [

                             Padding(
                               padding: const EdgeInsets.only(top:50.0,left: 40,right: 40),
                               child: Column(
                                 children: [
                                   Padding(
                                     padding: const EdgeInsets.only(left: 30.0,right: 30),
                                     child: Container(
                                         child:Text(
                                           widget.book.title,
                                           textAlign: TextAlign.center,
                                           style: TextStyle(color: Colors.grey[700],fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 16),)
                                     ),
                                   ),
                                   SizedBox(height: 25,),
                                   Row(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Column(
                                         children: [

                                           Container(
                                             height:40,
                                             width:70,
                                             decoration: BoxDecoration(
                                               color: Color(0xffFF997A),
                                               borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                             ),
                                             child: Center(child: Text(widget.book.publishedDate=='-'?'-':widget.book.publishedDate.substring(0,4).toString(),style: TextStyle(fontFamily: 'font',color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                           ),
                                           SizedBox(height: 5,),
                                           Text("Date",style: TextStyle(color:Color(0xFF283E50),    fontFamily: 'font',fontSize: 14,fontWeight: FontWeight.bold),)
                                         ],
                                       ),
                                       Column(
                                         children: [
                                           Container(
                                             height:40,
                                             width:70,
                                             decoration: BoxDecoration(
                                               color: Color(0xffFF997A),
                                               borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                             ),
                                             child: Center(child: Text(widget.book.rating.toString(),style: TextStyle(fontFamily: 'font',color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                           ),
                                           SizedBox(height: 5,),
                                           Text("Rating",style: TextStyle(color: Color(0xFF283E50),    fontFamily: 'font',fontSize: 14,fontWeight: FontWeight.bold),)
                                         ],
                                       ),
                                       Column(
                                         children: [
                                           Container(
                                             height:40,
                                             width:70,
                                             decoration: BoxDecoration(
                                               color: Color(0xffFF997A),
                                               borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                             ),
                                             child: Center(child: Text(widget.book.pageCount.toString(),style: TextStyle(    fontFamily: 'font',color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                           ),
                                           SizedBox(height: 5,),
                                           Text("Pages",style: TextStyle(color: Color(0xFF283E50),fontSize: 14,fontWeight: FontWeight.bold,    fontFamily: 'font'),)
                                         ],
                                       ),


                                     ],
                                   ),
                                 ],
                               ),
                             ),
                             SizedBox(height: 20,),
                             Divider(
                               color: Colors.white.withOpacity(0.2),
                               indent: 15,
                               endIndent: 15,
                               thickness: 1,
                             ),
                             SizedBox(height: 10,),
                             Text("About",style: TextStyle(fontFamily: 'font',color: Color(0xFF283E50),fontSize: 20,fontWeight: FontWeight.bold),),

                             SizedBox(height: 10,),
                             Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Text(

                                 widget.book.description,style: TextStyle(color: Color(0xFF686868),fontSize: 14,fontFamily: 'font'),
                                 textAlign: TextAlign.center,
                                 maxLines: 30,
                               ),
                             ),

                           ],
                         ),
                       ),

                     ),
                   ),
                 ),

                 Padding(
                   padding: const EdgeInsets.only(top: 50.0),
                   child: Align(
                     alignment: Alignment.topCenter,
                     child: Column(
                       children: [
                         Column(
                           children: [
                             Container(
                               child: Image.network(widget.book.imageLink),
                             ),
                             SizedBox(height: 10,),

                           ],
                         ),
                       ],
                     ),
                   ),
                 ),
                 Center(
                   child: Padding(
                     padding:  EdgeInsets.only(top:MediaQuery.of(context).size.height/1.2),
                     child: ElevatedButton(
                       onPressed: () {
                         _showInvitationCodePopup(); // Example values, replace with your data

                       },
                       child: Text("Add To Self",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 18),),
                       style: ButtonStyle(
                         backgroundColor: MaterialStateProperty.all<Color>(Color(0xffFF997A)),
                         shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                           RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(15.0),
                           ),
                         ),
                       ),
                     ),
                   ),
                 ),
               ],
             )
            ],
          )
        ),
      ),
    );
  }
  String startingDate = '';
  Future<void> addStartingDate(String docId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Sample user data (customize based on your requirements)
        Map<String, dynamic> contactFormData = {
          "startingDate": startingDate,
        };

        DocumentReference contactFormRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books')
            .doc(docId);

        await contactFormRef.set(contactFormData, SetOptions(merge: true));

        print('Starting date added successfully!');
      }
    } catch (e) {
      print('Error adding starting date: $e');
    }
  }
  void _showInvitationCodePopup() {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color(0xffD9D9D9),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add To Self ?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,fontFamily:'font',
                    color: Color(0xFF283E50),
                  ),
                ),
                Divider(
                  color: Color(0xFF283E50),
                  thickness: 1,
                ),
                SizedBox(height: 16.0),
                Row(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    ElevatedButton(
                      onPressed: () {

                        saveMyBook( widget.book.title,widget.book.imageLink,widget.book.pageCount,'CURRENTLY READING',widget.book.publishedDate.substring(0,4),widget.book.description,widget.book.rating); // Example values, replace with your data

                        //
                        // Navigator.pop(context);
                        // Navigator.pop(context);
                        // Navigator.pop(context);
                      },
                      child: Container(
                          // width: 70,
                          child: Center(child: Text("Currently Reading",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),))),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Color(0xffFF997A)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        saveMyBook( widget.book.title,widget.book.imageLink,widget.book.pageCount,'COMPLETED',widget.book.publishedDate.substring(0,4),widget.book.description,widget.book.rating);  // Example values, replace with your data

                        Navigator.pop(context);
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Container(
                          // width: 70,
                          child: Center(child: Text("Already Read",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),))),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Color(0xffFF997A)),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    saveMyBook( widget.book.title,widget.book.imageLink,widget.book.pageCount,'TO BE READ',widget.book.publishedDate.substring(0,4),widget.book.description,widget.book.rating);  // Example values, replace with your data
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Container(
                        width: 80,
                      child: Center(child: Text("To Be Read",style: TextStyle(color:  Color(0xFF283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 12),))),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Color(0xFFFF997A)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),
                ),
                //
                //
                // SizedBox(height: 16.0),
                // ElevatedButton(
                //   onPressed: () {},
                //   child: Container(
                //       child: Center(child: Text("Save",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 14),))),
                //   style: ButtonStyle(
                //     backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                //     shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                //       RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(15.0),
                //       ),
                //     ),
                //   ),
                // ),

                //
                // SizedBox(height: 16.0),
                // ElevatedButton(
                //   onPressed: () {
                //
                //   },
                //   child: Container(
                //       child: Center(child: Text("Save",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 14),))),
                //   style: ButtonStyle(
                //     backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                //     shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                //       RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(15.0),
                //       ),
                //     ),
                //   ),
                // ),

              ],
            ),
          ),
        );
      },
    );
  }

  void _showInvitationCodePopupForStartingDate() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color(0xffD9D9D9),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Started Date',
                          style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
                        ),
                        Container(
                          width: 100,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xFF283E50),
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: TextButton(
                            onPressed: () {
                              DateTime now = DateTime.now();
                              startingDate = DateFormat('yyyy/MMM/dd', 'en_US').format(now);
                              addStartingDate(gotDocId);
                              // log(formattedDate);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              setState(() {});
                            },
                            child: Text(
                              'Today',
                              style: TextStyle(
                                  color: Colors.white,fontFamily: 'font'
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(
                      color: Colors.grey,
                      thickness: 1,
                    ),
                  ],
                ),
                Container(
                  height: 50,
                  // width: 100,
                  decoration: BoxDecoration(
                    color: Color(0xffFEEAD4),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            height: 50,

                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount:year.length,
                              itemBuilder: (BuildContext context, int index) {
                                int number =year[index];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedYear = number;
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: number == selectedYear
                                          ? Color(0xffD9D9D9)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: number == selectedYear
                                            ? Color(0xffD9D9D9)
                                            : Colors.transparent,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$number',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,fontFamily:'font',
                                        color: Color(0xff686868),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount:month.length,
                              itemBuilder: (BuildContext context, int index) {
                                String number = month[index];
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedMonth = number;
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: number == selectedMonth
                                          ? Color(0xffD9D9D9)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: number == selectedMonth
                                            ? Color(0xffD9D9D9)
                                            : Colors.transparent,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$number',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,fontFamily:'font',
                                        color: Color(0xff686868),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: days.length,
                              itemBuilder: (BuildContext context, int index) {
                                int number = index + 1;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      selectedDays = number;
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: number == selectedDays
                                          ? Color(0xffD9D9D9)
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: number == selectedDays
                                            ? Color(0xffD9D9D9)
                                            : Colors.transparent,
                                        width: 2.0,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$number',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,fontFamily:'font',
                                        color: Color(0xff686868),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 115,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(0xFF283E50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            startingDate = selectedYear.toString()+'/'+selectedMonth.toString()+'/'+selectedDays.toString();
                            log(startingDate);
                          });
                          addStartingDate(gotDocId);
                          Navigator.pop(context);
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: Text(
                          'Update',
                          style: TextStyle(
                              color: Colors.white,fontFamily: 'font'
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ),
        );
      },
    );
  }

}
class CustomAlertForStartDateDialog extends StatefulWidget {
 String gotId;
  List<int> year;
  List<int> days;
  List<String> month;

  CustomAlertForStartDateDialog(
      {required this.gotId,
        required this.year,
        required this.days,
        required this.month});

  @override
  _CustomAlertForStartDateDialogState createState() =>
      _CustomAlertForStartDateDialogState();
}
class _CustomAlertForStartDateDialogState
    extends State<CustomAlertForStartDateDialog> {
  int selectedYear = 0;
  int selectedDays = 0;
  String selectedMonth = '';
  String startingDate = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Started Date',
                style: TextStyle(color: Color(0xff283E50),fontFamily: 'font'),
              ),
              Container(
                width: 100,
                height: 30,
                decoration: BoxDecoration(
                  color: Color(0xFF283E50),
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                child: TextButton(
                  onPressed: () {
                    DateTime now = DateTime.now();
                    startingDate = DateFormat('yyyy/MMM/dd', 'en_US').format(now);
                    addStartingDate(widget.gotId);
                    // log(formattedDate);
                    Navigator.pop(context);
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Text(
                    'Today',
                    style: TextStyle(
                        color: Colors.white,fontFamily: 'font'
                    ),
                  ),
                ),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: BoxDecoration(
          color: Color(0xffFEEAD4),
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 50,

                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.year.length,
                    itemBuilder: (BuildContext context, int index) {
                      int number = widget.year[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedYear = number;
                          });
                        },
                        child: Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: number == selectedYear
                                ? Color(0xffD9D9D9)
                                : Colors.transparent,
                            border: Border.all(
                              color: number == selectedYear
                                  ? Color(0xffD9D9D9)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,fontFamily:'font',
                              color: Color(0xff686868),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.month.length,
                    itemBuilder: (BuildContext context, int index) {
                      String number = widget.month[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedMonth = number;
                          });
                        },
                        child: Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: number == selectedMonth
                                ? Color(0xffD9D9D9)
                                : Colors.transparent,
                            border: Border.all(
                              color: number == selectedMonth
                                  ? Color(0xffD9D9D9)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,fontFamily:'font',
                              color: Color(0xff686868),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.days.length,
                    itemBuilder: (BuildContext context, int index) {
                      int number = index + 1;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedDays = number;
                          });
                        },
                        child: Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: number == selectedDays
                                ? Color(0xffD9D9D9)
                                : Colors.transparent,
                            border: Border.all(
                              color: number == selectedDays
                                  ? Color(0xffD9D9D9)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,fontFamily:'font',
                              color: Color(0xff686868),
                            ),
                          ),
                        ),
                      );
                    },
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
              width: 115,
              height: 45,
              decoration: BoxDecoration(
                color: Color(0xFF283E50),
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    startingDate = selectedYear.toString()+'/'+selectedMonth.toString()+'/'+selectedDays.toString();
                    log(startingDate);
                  });
                  addStartingDate(widget.gotId);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text(
                  'Update',
                  style: TextStyle(
                      color: Colors.white,fontFamily: 'font'
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Future<void> addStartingDate(String docId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Sample user data (customize based on your requirements)
        Map<String, dynamic> contactFormData = {
          "startingDate": startingDate,
        };

        DocumentReference contactFormRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books')
            .doc(docId);

        await contactFormRef.set(contactFormData, SetOptions(merge: true));

        print('Starting date added successfully!');
      }
    } catch (e) {
      print('Error adding starting date: $e');
    }
  }

}