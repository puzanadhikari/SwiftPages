import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
TextEditingController commentController = TextEditingController();
String comment='';
class Community extends StatefulWidget {
  const Community({Key? key}) : super(key: key);

  @override
  _CommunityState createState() => _CommunityState();
}

class _CommunityState extends State<Community> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xfffeead4),
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
                "Community",
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
              padding: const EdgeInsets.only(top:100.0),
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('communityBooks')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  List<QueryDocumentSnapshot> bookDocuments = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: bookDocuments.length,
                    itemBuilder: (context, index) {
                      var bookData =
                          bookDocuments[index].data() as Map<String, dynamic>;
                      var documentId = bookDocuments[index].id;

                      return BookCard(
                        bookData: bookData,
                        documentId: documentId,
                        index: index,
                      );
                    },
                  );
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
  final String documentId;
  final int index;

  BookCard(
      {Key? key,
      required this.bookData,
      required this.documentId,
      required this.index})
      : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isLiked = false;
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int likes = widget.bookData['likes'] ?? 0;
    List<Map<String, dynamic>> comments =
        List<Map<String, dynamic>>.from(widget.bookData['comments'] ?? []);
    log(comments.length.toString());
    String currentUsername = widget.bookData['username'] ?? '';
    List<dynamic> likedBy = widget.bookData['likedBy'] ?? [];
    _isLiked = likedBy.contains(currentUsername);

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
              Column(
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
                      Text(widget.bookData['username'] ?? 'Anonymous'),
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
              Column(
                children: [
                  Row(
                    children: [
                      Text("Review",style: TextStyle(color: Color(0xFF283E50),fontWeight: FontWeight.bold,fontSize: 16),),
                      SizedBox(
                        width: 10,
                      ),
                      Text('${comments.length} ',style: TextStyle(color: Color(0xFF283E50),),),
                      GestureDetector(
                        onTap: (){
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CommentPage(
                                    comments: comments,
                                    docId: widget.documentId,
                                    onPressed: (){
                                      addComment(comment);
                                    },
                                    commentCount: comments.length,
                                  )));
                        },
                        child: SvgPicture.asset(
                          'assets/comment.svg',
                          height: 30,
                        ),
                      ),
                      SizedBox(width: 10,),
                      GestureDetector(
                        onTap: (){
                          updateLikes(
                              _isLiked ? likes - 1 : likes + 1, widget.index);
                        },
                        child: SvgPicture.asset(
                          'assets/like.svg',
                          height: 25,
                          color: _isLiked ? Colors.red: Color(0xFFFEEAD4),
                        ),
                      ),

                      Text(' ${likes}',style: TextStyle(color: Color(0xFF283E50),),),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top:20.0),
                    child: Container(
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
                            '${widget.bookData['notes'] ?? ''}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF686868),
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
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

  void updateLikes(int newLikes, int index) async {
    String currentUsername = widget.bookData['username'] ?? '';
    List<dynamic> likedBy = List<String>.from(widget.bookData['likedBy'] ?? []);

    if (!likedBy.contains(currentUsername)) {
      likedBy.add(currentUsername);

      // Update Firestore document with newLikes and updated likedBy
      await FirebaseFirestore.instance
          .collection('communityBooks')
          .doc(widget.documentId)
          .update({'likes': newLikes, 'likedBy': likedBy});

      log('Liked on index: $index');
    } else {
      likedBy.remove(currentUsername);

      // Update Firestore document with newLikes and updated likedBy
      await FirebaseFirestore.instance
          .collection('communityBooks')
          .doc(widget.documentId)
          .update({'likes': newLikes, 'likedBy': likedBy});

      log('Unliked on index: $index');
    }

    // Update isLiked locally after Firestore update is complete
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void addComment(String newComment) async {
    User? user = FirebaseAuth.instance.currentUser;
    String currentUsername = user?.displayName ?? 'Anonymous';
    String avatarUrl = user?.photoURL ?? '';

    // Create a map representing the comment with username and avatar
    Map<String, dynamic> commentData = {
      'username': currentUsername,
      'avatarUrl': avatarUrl,
      'comment': newComment,
    };

    List<Map<String, dynamic>> updatedComments =
        List<Map<String, dynamic>>.from(widget.bookData['comments'] ?? []);
    updatedComments.add(commentData);

    // Update Firestore document with the new comments
    await FirebaseFirestore.instance
        .collection('communityBooks')
        .doc(widget.documentId)
        .update({'comments': updatedComments});

    // Clear the comment text field after adding a comment
    setState(() {
      commentController.clear();
      comment = '';
    });


    log('Comment added to index: ${widget.index}');
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
