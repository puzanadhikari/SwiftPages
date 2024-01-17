import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Community extends StatefulWidget {
  const Community({Key? key}) : super(key: key);

  @override
  _CommunityState createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('communityBooks').snapshots(),
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
              var bookData = bookDocuments[index].data() as Map<String, dynamic>;
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
    );
  }
}

class BookCard extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final String documentId;
  final int index;

  BookCard({Key? key, required this.bookData, required this.documentId, required this.index}) : super(key: key);

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isLiked = false;
  TextEditingController commentController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    int likes = widget.bookData['likes'] ?? 0;
    List<Map<String, dynamic>> comments = List<Map<String, dynamic>>.from(widget.bookData['comments'] ?? []);
    String currentUsername = widget.bookData['username'] ?? '';
    List<dynamic> likedBy = widget.bookData['likedBy'] ?? [];
    _isLiked = likedBy.contains(currentUsername);

    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=>CommentPage(comments: comments,docId: widget.documentId,)));
      },
      child: Card(
        margin: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(widget.bookData['avatarUrl'] ?? ''),
              ),
              title: Text(widget.bookData['username'] ?? 'Anonymous'),
            ),
            Container(
              height: 150,
              width: double.infinity,
              child: Image.network(
                widget.bookData['imageLink'] ?? '',
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bookData['title'] ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${widget.bookData['notes'] ?? ''}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.thumb_up,
                              color: _isLiked ? Colors.blue : null,
                            ),
                            onPressed: () {
                              updateLikes(_isLiked ? likes-1 : likes + 1, widget.index);
                            },
                          ),
                          Text('$likes'),
                        ],
                      ),

                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(hintText: 'Write your comment'),
                        ),
                      ),
                      if (commentController.text.isEmpty)
                        TextButton(
                          onPressed: () {
                            addComment(commentController.text);
                          },
                          child: Text('Add Comment'),
                        ),

                    ],
                  ),


                ],
              ),
            ),
          ],
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

    // Add the comment map to the 'comments' list
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
    });

    log('Comment added to index: ${widget.index}');
  }

}
class CommentWidget extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final String comment;

  CommentWidget({required this.username, required this.avatarUrl, required this.comment});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
      ),
      title: Text(username),
      subtitle: Text(comment),
    );
  }
}
class CommentPage extends StatefulWidget {
  List<Map<String, dynamic>> comments;
  String docId;

  CommentPage({Key? key, required this.comments,required this.docId}) : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [


            Expanded(
                child: ListView(children:[
      for (var comment in widget.comments)
        CommentWidget(username: comment['username'], avatarUrl: comment['avatarUrl'], comment: comment['comment'])

    ]),),

          // Add Comment Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(hintText: 'Write your comment'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    addComment(commentController.text);
                  },
                  child: Text('Add Comment'),
                ),
              ],
            ),
          ),
        ],
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



