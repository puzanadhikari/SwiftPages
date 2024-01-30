import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg instead of flutter_svg/svg.dart
import 'package:fluttertoast/fluttertoast.dart';
import 'allBooks.dart';

class AllBookDetailPage extends StatefulWidget {
  final Book book;

  AllBookDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  State<AllBookDetailPage> createState() => _AllBookDetailPageState();
}

class _AllBookDetailPageState extends State<AllBookDetailPage> {

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
              SvgPicture.asset('assets/background.svg',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height,
                color: Colors.grey.withOpacity(0.2),
              ),
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
                         color: Color(0xFF283E50),
                       ),
                       child: Padding(
                         padding: const EdgeInsets.only(top:120.0,left: 5,right: 5),
                         child: Column(
                           children: [
                             Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Column(
                                   children: [
                                     Container(
                                       height:50,
                                       width:100,
                                       decoration: BoxDecoration(
                                         color: Color(0xffFF997A),
                                         borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                       ),
                                       child: Center(child: Text(widget.book.publishedDate.substring(0,4).toString(),style: TextStyle(color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                     ),
                                     Text("Date",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),)
                                   ],
                                 ),
                                 Column(
                                   children: [
                                     Container(
                                       height:50,
                                       width:100,
                                       decoration: BoxDecoration(
                                         color: Color(0xffFF997A),
                                         borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                       ),
                                       child: Center(child: Text(widget.book.rating.toString(),style: TextStyle(color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                     ),
                                     Text("Rating",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),)
                                   ],
                                 ),
                                 Column(
                                   children: [
                                     Container(
                                       height:50,
                                       width:100,
                                       decoration: BoxDecoration(
                                         color: Color(0xffFF997A),
                                         borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
                                       ),
                                       child: Center(child: Text(widget.book.pageCount.toString(),style: TextStyle(color: Color(0xFF283E50),fontSize: 16,fontWeight: FontWeight.bold),)),

                                     ),
                                     Text("Pages",style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),)
                                   ],
                                 ),


                               ],
                             ),
                             SizedBox(height: 20,),
                             Text("About",style: TextStyle(color: Colors.white,fontSize: 25,fontWeight: FontWeight.bold),),

                             SizedBox(height: 10,),
                             Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Text(

                                 widget.book.description,style: TextStyle(color: Colors.white,fontSize: 14),
                                 textAlign: TextAlign.center,),
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
                             Container(
                               child:Text(widget.book.title,style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 18),)
                             ),

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
                       child: Text("Add To Self",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 18),),
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
                    fontWeight: FontWeight.bold,
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

                        saveMyBook( widget.book.title,widget.book.imageLink,widget.book.pageCount,'CURRENTLY READING',widget.book.publishedDate.substring(0,4),widget.book.description); // Example values, replace with your data
                        Navigator.pop(context);
                      },
                      child: Container(
                          // width: 70,
                          child: Center(child: Text("Currently Reading",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 12),))),
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
                        saveMyBook( widget.book.title,widget.book.imageLink,widget.book.pageCount,'COMPLETED',widget.book.publishedDate.substring(0,4),widget.book.description);  // Example values, replace with your data
                        Navigator.pop(context);
                      },
                      child: Container(
                          // width: 70,
                          child: Center(child: Text("Already Read",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 12),))),
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
                    saveMyBook( widget.book.title,widget.book.imageLink,widget.book.pageCount,'TO BE READ',widget.book.publishedDate.substring(0,4),widget.book.description);  // Example values, replace with your data
                    Navigator.pop(context);
                  },
                  child: Container(
                        width: 120,
                      child: Center(child: Text("To Be Read",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 14),))),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),
                ),
                //
                // SizedBox(height: 16.0),
                // ElevatedButton(
                //   onPressed: () {
                //
                //   },
                //   child: Container(
                //       child: Center(child: Text("Save",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 14),))),
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

}
