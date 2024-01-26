import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
TextEditingController commentController = TextEditingController();
String comment='';
class SavedPosts extends StatefulWidget {
  const SavedPosts({Key? key}) : super(key: key);

  @override
  _SavedPostsState createState() => _SavedPostsState();
}

class _SavedPostsState extends State<SavedPosts> {
  String? currentUserName = FirebaseAuth.instance.currentUser?.displayName;
  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  Future<void> getSavedPosts() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String currentUserId = user.uid;

      // Query the saved posts for the current user
      QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('savedPosts')
          .get();

      // Handle the query results if needed
      // List<QueryDocumentSnapshot<Map<String, dynamic>>> savedPosts = querySnapshot.docs;
      // Do something with the saved posts...

      // If you don't need to return anything, you can simply return here.
      return;
    }

    // If the user is not logged in, you can perform other actions or return a default value.
    print('User is not logged in');
  }






  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xffD9D9D9),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top:10.0),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('savedPosts')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    List savedPosts = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: savedPosts.length,
                      itemBuilder: (context, index) {
                        var savedPostData =
                        savedPosts[index].data() as Map<String, dynamic>;
                        String savedId = savedPosts[index].id;

                        return BookCard(bookData: savedPostData, savedId:savedId);
                      },
                    );
                  }
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class BookCard extends StatefulWidget {
  final Map<String, dynamic> bookData;
  String savedId;


  BookCard(
      {Key? key,
        required this.bookData,
        required this.savedId,
        })
      : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isLiked = false;
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // int likes = widget.bookData['likes'] ?? 0;


    return GestureDetector(
      onTap: () {

      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
        ),
        color: Color(0xFFFF997A),
        elevation: 8,
        margin: EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor:  Color(0xFFFEEAD4),
                          backgroundImage: NetworkImage(
                            widget.bookData['avatarUrl'] ?? '',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(widget.bookData['postedBy'] ?? 'Anonymous'),

                      ],
                    ),
                    SizedBox(height: 10,),
                    Container(
                      height: 150,
                      width: 100,
                      child: Image.network(
                        widget.bookData['imageLink'] ?? '',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 10,)
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top:20.0),
                  child: Column(
                    children: [
                      Container(
                        height:120,
                        width: 200,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Container(
                          height: 150,
                          width: 150,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Text(
                              '${widget.bookData['note'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Color(0xFF686868),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showDeletePostDialog(widget.savedId);
                        },
                        child: Text("Delete"),
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
                ),
              ),

              // ListTile(
              //   leading: CircleAvatar(
              //     backgroundImage: NetworkImage(widget.bookData['avatarUrl'] ?? ''),
              //   ),
              //   title: Text(widget.bookData['username'] ?? 'Anonymous'),
              // ),
              // Container(
              //   height: 150,
              //   width: double.infinity,
              //   child: Image.network(
              //     widget.bookData['imageLink'] ?? '',
              //     fit: BoxFit.contain,
              //   ),
              // ),
              // Padding(
              //   padding: EdgeInsets.all(8),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         widget.bookData['title'] ?? '',
              //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //       ),
              //       SizedBox(height: 8),
              //       Text(
              //         '${widget.bookData['notes'] ?? ''}',
              //         style: TextStyle(fontSize: 14),
              //       ),
              //       SizedBox(height: 8),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Row(
              //             children: [
              //               IconButton(
              //                 icon: Icon(
              //                   Icons.thumb_up,
              //                   color: _isLiked ? Colors.blue : null,
              //                 ),
              //                 onPressed: () {
              //                   updateLikes(_isLiked ? likes-1 : likes + 1, widget.index);
              //                 },
              //               ),
              //               Text('$likes'),
              //             ],
              //           ),
              //
              //         ],
              //       ),
              //       Row(
              //         children: [
              //           Expanded(
              //             child: TextField(
              //               controller: commentController,
              //               decoration: InputDecoration(hintText: 'Write your comment'),
              //             ),
              //           ),
              //           if (commentController.text.isEmpty)
              //             TextButton(
              //               onPressed: () {
              //                 addComment(commentController.text);
              //               },
              //               child: Text('Add Comment'),
              //             ),
              //
              //         ],
              //       ),
              //
              //
              //     ],
              //   ),
              // ),
            ],
          ),

        ),
      ),
    );
  }
  void _showDeletePostDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController notesController = TextEditingController();

        return AlertDialog(
          title: Text('Delete Post'),
          content: Text("Are you sure wantt to delete the Post?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  deletePost(docId);

                });
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void deletePost(String docId) async {
    try {
      // Get the current authenticated user
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // User is signed in, use the UID to remove the book
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myPostRed =
        FirebaseFirestore.instance.collection('users').doc(uid).collection('savedPosts');


        await myPostRed.doc(docId).delete();


        setState(() {

        });

        print('Post removed successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error removing book: $e');
    }
  }

}

class CommentWidget extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final String comment;

  CommentWidget(
      {required this.username, required this.avatarUrl, required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor:  Color(0xFFFEEAD4),
      ),
      title: Text(username.toUpperCase(),style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
      subtitle: Text(comment,style: TextStyle(fontSize: 14),),
    );
  }
}

class CommentPage extends StatefulWidget {
  List<Map<String, dynamic>> comments;
  String docId;
  final VoidCallback onPressed;
  int commentCount;

  CommentPage({Key? key, required this.comments, required this.docId,required this.onPressed,required this.commentCount})
      : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
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
              left: MediaQuery.of(context).size.width / 3,
              child: Text(
                "Comments",
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
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
                ),
                color: Color(0xFFFF997A),
                elevation: 8,
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:widget.commentCount==0?Center(
                    child: Column(
                      children: [
                        Expanded(
                            child: Center(child: Text("No Comments yet"))
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  // controller: commentController,
                                  onChanged: (value){
                                    setState(() {
                                      comment = value;
                                    });
                                  },
                                  decoration: InputDecoration(hintText: 'Write your comment'),
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onPressed,
                                child: Text('Comment',style: TextStyle(color: Colors.white),),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ):Column(
                    children: [
                      Expanded(
                        child: ListView(children: [
                          for (var comment in widget.comments)
                            CommentWidget(
                                username: comment['username'],
                                avatarUrl: comment['avatarUrl'],
                                comment: comment['comment'])
                        ]),
                      ),

                      // Add Comment Section
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                // controller: commentController,
                                onChanged: (value){
                                  setState(() {
                                    comment = value;
                                  });
                                },
                                decoration: InputDecoration(hintText: 'Write your comment'),
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onPressed,
                              child: Text('Comment',style: TextStyle(color: Colors.white),),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              ),
            ),


          ],
        ),
      ),
    );
  }

  void addComment(String newComment) async {
    User? user = FirebaseAuth.instance.currentUser;
    String currentUsername = user?.displayName ?? 'Anonymous';
    String avatarUrl = user?.photoURL ?? '';

    // Add the comment to the 'comments' collection under the specific book
    await FirebaseFirestore.instance
        .collection('communityBooks')
        .doc(widget.docId)
        .collection('comments')
        .add({
      'username': currentUsername,
      'avatarUrl': avatarUrl,
      'comment': newComment,
    });

    // Clear the comment text field after adding a comment
    setState(() {
      commentController.clear();
    });
  }
}
