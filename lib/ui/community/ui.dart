import 'dart:developer';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../chats/ui.dart';
import '../notificationPage.dart';

TextEditingController commentController = TextEditingController();
String comment = '';

class Community extends StatefulWidget {
  const Community({Key? key}) : super(key: key);

  @override
  _CommunityState createState() => _CommunityState();
}

class _CommunityState extends State<Community> {
  String? currentUserName = FirebaseAuth.instance.currentUser?.displayName;
  Stream<int> getActivityCountStream() async* {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String currentUserId = user.uid;

      yield* FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('activity')
          .snapshots()
          .map((querySnapshot) => querySnapshot.size);
    } else {
      yield 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xffD9D9D9),
        body: Stack(
          children: [

            Padding(
              padding: const EdgeInsets.only(top: 10.0),
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

                  List<QueryDocumentSnapshot> bookDocuments =
                      snapshot.data!.docs;

                  return ListView.builder(
                    reverse: false,
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

void savePost(
  BuildContext context,
  String imgLink,
  String postedBy,
  String postedUserAvatar,
  String note,
) async {
  User? user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    String currentUserId = user.uid;

    // Create a map representing the saved post
    Map<String, dynamic> savedPost = {
      'imageLink': imgLink ?? '',
      'postedBy': postedBy ?? '',
      'avatarUrl': postedUserAvatar ?? '',
      'note': note ?? '',
    };

    // Save the post information to the current user's data
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('savedPosts')
        .add(savedPost);

    // Show a confirmation message or perform any other action
    // You can use Flutter's SnackBar to display a message.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Post saved successfully!'),
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
    User? user = FirebaseAuth.instance.currentUser;
    String currentUsername = user?.displayName ?? '';
    String currentUserAvatar = user?.photoURL ?? '';
    String username = user?.displayName ?? '';
    List<dynamic> likedBy = widget.bookData['likedBy'] ?? [];

    _isLiked = likedBy.contains(username);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.all(Radius.circular(20)), // Adjust the radius as needed
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
                  GestureDetector(
                    onTap: ()async{
                      fetchUserDetailsById(widget.bookData['userId']);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(0xFFFEEAD4),
                          backgroundImage: NetworkImage(
                            widget.bookData['avatarUrl'] ?? '',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(widget.bookData['username'] ?? 'Anonymous',style: TextStyle(fontFamily: 'font',),),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 150,
                    width: 100,
                    child: Image.network(
                      widget.bookData['imageLink'] ?? '',
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Row(

                    children: [
                      Text(
                        'Review',
                        style: TextStyle(
                          color: Color(0xFF283E50),fontFamily: 'font',
                        ),
                      ),
                      GestureDetector(
                        onTap: (){
                          _showConfirmationDialogToSave(context);
                        },
                        child: SvgPicture.asset(
                          'assets/save.svg',
                          height: 25,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        '${comments.length} ',
                        style: TextStyle(
                          color: Color(0xFF283E50),fontFamily: 'font',
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => CommentPage(
                                        comments: comments,
                                        docId: widget.documentId,
                                        onPressed: () {
                                          addComment(comment);
                                          saveActivity(
                                              context,
                                              widget.bookData['imageLink'],
                                              currentUsername ,
                                              widget.bookData['avatarUrl'],
                                              'Comment',
                                              widget.bookData['userId'],
                                              currentUserAvatar,
                                            DateTime.now()

                                          );
                                        },
                                        commentCount: comments.length, bookData: widget.bookData,

                                      )));
                        },
                        child: SvgPicture.asset(
                          'assets/comment.svg',
                          height: 30,
                          color: Color(0xff283E50),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      GestureDetector(
                        onTap: () {
                          updateLikes(_isLiked ? likes - 1 : likes + 1,
                              widget.index, username);
                          log(currentUsername+widget.bookData['username']);
                         currentUsername==widget.bookData['username']?'': saveActivity(
                              context,
                              widget.bookData['imageLink'],
                              currentUsername,
                              widget.bookData['avatarUrl'],
                              _isLiked ? 'Unliked' : 'Liked',
                              widget.bookData['userId'],currentUserAvatar, DateTime.now());
                        },
                        child: SvgPicture.asset(
                          'assets/like.svg',
                          height: 25,
                          color: _isLiked ? Colors.red : Color(0xFFFEEAD4),
                        ),
                      ),
                      Text(
                        ' ${likes}',
                        style: TextStyle(
                          color: Color(0xFF283E50),fontFamily: 'font',
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            RatingBar.builder(
                              glow: false,
                              initialRating: widget.bookData['rating']==null?0:widget.bookData['rating'],
                              minRating: 0,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 20,
                              itemBuilder: (context, _) => Icon(
                                Icons.star,
                                color: Color(0xff283E50),
                              ),
                              onRatingUpdate: (value) {

                              },
                            ),
                            Text("${widget.bookData['rating']==null?0:widget.bookData['rating']}/5 stars",style: TextStyle(fontFamily: 'font'),)
                          ],
                        ),
                        SizedBox(height: 10,),
                        Container(
                          height: 120,
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
                                    fontWeight: FontWeight.w500,fontFamily:'font'),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10,),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          Padding(
                            padding: const EdgeInsets.only(top:15.0),
                            child: Row(
                              children: [
                                Icon(Icons.run_circle_outlined,color:Color(0xFF283E50) ,),
                                SizedBox(width: 5,),
                                Text(widget.bookData['pace'] ?? '',style: TextStyle(fontFamily: 'font',color: Color(0xFF283E50),fontWeight: FontWeight.bold),),
                              ],
                            ),
                          ),
                          if (widget.bookData['userId'] == FirebaseAuth.instance.currentUser?.uid)
                            ElevatedButton(
                              onPressed: () {
                                _showDeletePostDialog(widget.documentId);
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
                        ],)

                        // GestureDetector(
                        //     onTap: (){
                        //       _showConfirmationDialogToSave(context);
                        //     },
                        //     child: Icon(Icons.download))
                      ],
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
        FirebaseFirestore.instance.collection('communityBooks');


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
  Future<Map<String, dynamic>> fetchUserDetailsById(String userId) async {
    log(userId.toString());
    try {

          DocumentSnapshot userSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();


            Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
          _showPersistentBottomSheet(context,userData,userId);
            return userData;




    } catch (error) {
      // Handle errors appropriately
      log("Error fetching user details: $error");
      throw Exception("Failed to fetch user details.");
    }
  }
  void _showPersistentBottomSheet(BuildContext context,Map<String, dynamic> userData , String userId) {
    showModalBottomSheet(
      backgroundColor:Color(0xffD9D9D9),
      context: context,

      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xffD9D9D9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(userData['avatar'] ?? ''),
                              backgroundColor:  Color(0xFFFEEAD4),
                            ),
                            SizedBox(width: 10,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${userData['username']}",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 16),),
                                Text("${userData['email']}",style: TextStyle(fontFamily: 'font',color: Color(0xff283E50),fontSize: 14),),
                              ],
                            ),

                          ],
                        ),

                          Row(
                          children: [
                            Image.asset(
                              "assets/strick.png",
                              height: 40,
                              color: Color(0xff283E50),
                            ),
                            Text(userData['strikes'].toString(), style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff283E50),fontFamily: 'font',
                            )),
                          ],
                        ),

                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              recipientUserId: userId,
                              recipientUsername: userData['username'],
                              recipientAvatar: userData['avatar'],
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0), // Adjust the radius as needed
                        ),
                        primary:  Color(0xff283E50),// Set your desired button color
                      ),
                      child: Text("Chat",style: TextStyle(fontFamily: 'font',),),
                    ),

                    Divider(
                      color: Color(0xff283E50),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top:10.0),
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('communityBooks').where('username', isEqualTo: userData['username'])
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

                                return BookCardSheet(
                                  bookData: bookData,
                                  documentId: documentId,
                                  index: index,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  void _showUserDetail(BuildContext context,String email,int strikes) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Swift Pages user detail",
            style: TextStyle(color: Color(0xff283E50),fontFamily: 'font',), // Set title text color
          ),
          actions: <Widget>[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
              ),
              color: Color(0xFFFF997A),
              elevation: 8,
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(

                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(0xFFFEEAD4),
                          backgroundImage: NetworkImage(
                            widget.bookData['avatarUrl'] ?? '',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(widget.bookData['username'] ?? 'Anonymous'),
                        SizedBox(
                          width: 20,
                        ),
                        Image.asset(
                          "assets/strick.png",
                          height: 40,
                          color: Color(0xff283E50)
                        ),
                        Text(strikes.toString(), style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff283E50),fontFamily: 'font',
                        )),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(email),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9),

        );
      },
    );
  }
  void _showConfirmationDialogToSave(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Save post",
            style: TextStyle(fontFamily: 'font',color: Colors.blue), // Set title text color
          ),
          content: Text("Are you sure want to save this post?",style: TextStyle(fontFamily: 'font',),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "No",
                style: TextStyle(fontFamily: 'font',color: Colors.red), // Set cancel text color
              ),
            ),
            TextButton(
              onPressed: () {
                savePost(
                    context,
                    widget.bookData['imageLink'],
                    widget.bookData['username'],
                    widget.bookData['avatarUrl'],
                    widget.bookData['notes']);
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Yes",
                style: TextStyle(fontFamily: 'font',color: Colors.green), // Set save text color
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9), // Set dialog background color
        );
      },
    );
  }
  void saveActivity(BuildContext context, String imgLink, String activityBy,
      String activityUserAvatar, String type, String userId,String userAvatar,DateTime time) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String currentUserId = user.uid;

      // Create a map representing the saved post
      Map<String, dynamic> savedPost = {
        'imageLink': imgLink ?? '',
        'activityBy': activityBy ?? '',
        'activityUserAvatar': activityUserAvatar ?? '',
        'type': type,
        'avatar':userAvatar,
        'time':time
      };

      // Save the post information to the current user's data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activity')
          .add(savedPost);

    }


  }

  void updateLikes(int newLikes, int index, String username) async {
    String currentUsername = widget.bookData['username'] ?? '';
    List<dynamic> likedBy = List<String>.from(widget.bookData['likedBy'] ?? []);

    if (!likedBy.contains(username)) {
      likedBy.add(username);

      // Update Firestore document with newLikes and updated likedBy
      await FirebaseFirestore.instance
          .collection('communityBooks')
          .doc(widget.documentId)
          .update({'likes': newLikes, 'likedBy': likedBy});

      log('Liked on index: $index');
    } else {
      likedBy.remove(username);

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

class BookCardSheet extends StatefulWidget {
  final Map<String, dynamic> bookData;
  final String documentId;
  final int index;

  BookCardSheet(
      {Key? key,
        required this.bookData,
        required this.documentId,
        required this.index})
      : super(key: key);

  @override
  State<BookCardSheet> createState() => _BookCardSheetState();
}

class _BookCardSheetState extends State<BookCardSheet> {
  bool _isLiked = false;
  TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    int likes = widget.bookData['likes'] ?? 0;
    List<Map<String, dynamic>> comments =
    List<Map<String, dynamic>>.from(widget.bookData['comments'] ?? []);
    log(comments.length.toString());
    User? user = FirebaseAuth.instance.currentUser;
    String currentUsername = user?.displayName ?? '';
    String currentUserAvatar = user?.photoURL ?? '';
    String username = user?.displayName ?? '';
    List<dynamic> likedBy = widget.bookData['likedBy'] ?? [];

    _isLiked = likedBy.contains(username);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(20.0), // Adjust the radius as needed
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
                GestureDetector(
                  onTap: ()async{

                    fetchUserDetailsById(widget.bookData['userId']);
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Color(0xFFFEEAD4),
                        backgroundImage: NetworkImage(
                          widget.bookData['avatarUrl'] ?? '',
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(widget.bookData['username'] ?? 'Anonymous',style: TextStyle(fontFamily: 'font',),),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),

                Container(
                  height: 100,
                  width: 100,
                  child: Image.network(
                    widget.bookData['imageLink'] ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
            Column(
              children: [
                Row(
                  children: [

                    GestureDetector(
                      onTap: (){
                        _showConfirmationDialogToSave(context);
                      },
                      child: SvgPicture.asset(
                        'assets/save.svg',
                        height: 25,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      '${comments.length} ',
                      style: TextStyle(
                        color: Color(0xFF283E50),fontFamily: 'font',
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CommentPage(
                                  comments: comments,
                                  docId: widget.documentId,
                                  onPressed: () {
                                    addComment(comment);
                                    saveActivity(
                                        context,
                                        widget.bookData['imageLink'],
                                        currentUsername ,
                                        widget.bookData['avatarUrl'],
                                        'Comment',
                                        widget.bookData['userId'],
                                        currentUserAvatar,
                                        DateTime.now()

                                    );
                                  },
                                  commentCount: comments.length, bookData: widget.bookData,

                                )));
                      },
                      child: SvgPicture.asset(
                        'assets/comment.svg',
                        height: 30,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        updateLikes(_isLiked ? likes - 1 : likes + 1,
                            widget.index, username);
                        log(currentUsername+widget.bookData['username']);
                        currentUsername==widget.bookData['username']?'': saveActivity(
                            context,
                            widget.bookData['imageLink'],
                            currentUsername,
                            widget.bookData['avatarUrl'],
                            _isLiked ? 'Unliked' : 'Liked',
                            widget.bookData['userId'],currentUserAvatar, DateTime.now());
                      },
                      child: SvgPicture.asset(
                        'assets/like.svg',
                        height: 25,
                        color: _isLiked ? Colors.red : Color(0xFFFEEAD4),
                      ),
                    ),
                    Text(
                      ' ${likes}',
                      style: TextStyle(
                        color: Color(0xFF283E50),fontFamily: 'font',
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      Container(
                        height: 100,
                        width: 150,
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
                                  fontWeight: FontWeight.w500,fontFamily:'font'),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10,),


                    ],
                  ),
                ),


              ],
            ),
          ],
        ),
      ),
    );
  }
  Future<Map<String, dynamic>> fetchUserDetailsById(String userId) async {
    LoadingAnimationWidget.discreteCircle(
      color: Color(0xFF283E50),
      size: 100,
      secondRingColor: Color(0xFFFF997A),
      thirdRingColor:Color(0xFF686868),
    );
    log(userId.toString());
    try {

      DocumentSnapshot userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();


      Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
      // _showUserDetail(context, userData['email'], userData['strikes']);
      _showPersistentBottomSheet(context,userData);
      return userData;




    } catch (error) {
      // Handle errors appropriately
      log("Error fetching user details: $error");
      throw Exception("Failed to fetch user details.");
    }
  }
  void _showPersistentBottomSheet(BuildContext context,Map<String, dynamic> userData) {
    showModalBottomSheet(
      backgroundColor: Color(0xFFFEEAD4),
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFFFEEAD4),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
            ),
            child: Container(
              color: Color(0xFFFEEAD4),
              width: MediaQuery.of(context).size.width * 0.9, // Adjust width as needed
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(userData['avatar'] ?? ''),
                              backgroundColor: Color(0xffD9D9D9),
                            ),
                            SizedBox(width: 10,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${userData['username']}",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontFamily:'font',fontSize: 16),),
                                Text("${userData['email']}",style: TextStyle(fontFamily: 'font',color: Color(0xff283E50),fontSize: 14),),
                              ],
                            ),

                          ],
                        ),

                        Row(
                          children: [
                            Image.asset(
                              "assets/strick.png",
                              height: 40,
                              color: Color(0xff283E50)
                            ),
                            Text(userData['strikes'].toString(), style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff283E50),fontFamily: 'font',
                            )),
                          ],
                        ),

                      ],
                    ),

                    Divider(
                      color: Color(0xff283E50),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top:10.0),
                        child: StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('communityBooks').where('username', isEqualTo: userData['username'])
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  void _showUserDetail(BuildContext context,String email,int strikes) {

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Swift Pages user detail",
            style: TextStyle(fontFamily: 'font',color: Color(0xff283E50)), // Set title text color
          ),
          actions: <Widget>[
            Card(
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
              ),
              color: Color(0xFFFF997A),
              elevation: 8,
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(

                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: Color(0xFFFEEAD4),
                          backgroundImage: NetworkImage(
                            widget.bookData['avatarUrl'] ?? '',
                          ),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(widget.bookData['username'] ?? 'Anonymous'),
                        SizedBox(
                          width: 20,
                        ),
                        Image.asset(
                          "assets/strick.png",
                          height: 40,
                          color: Color(0xff283E50)
                        ),
                        Text(strikes.toString(), style: TextStyle(
                          fontSize: 14,
                          color: Color(0xff283E50),fontFamily: 'font',
                        )),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Text(email),
                    SizedBox(
                      height: 10,
                    )
                  ],
                ),
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9),

        );
      },
    );
  }
  void _showConfirmationDialogToSave(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Save post",
            style: TextStyle(fontFamily: 'font',color: Colors.blue), // Set title text color
          ),
          content: Text("Are you sure want to save this post?",style: TextStyle(fontFamily: 'font',),),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "No",
                style: TextStyle(fontFamily: 'font',color: Colors.red), // Set cancel text color
              ),
            ),
            TextButton(
              onPressed: () {
                savePost(
                    context,
                    widget.bookData['imageLink'],
                    widget.bookData['username'],
                    widget.bookData['avatarUrl'],
                    widget.bookData['notes']);
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Yes",
                style: TextStyle(fontFamily: 'font',color: Colors.green), // Set save text color
              ),
            ),
          ],
          backgroundColor: Color(0xFFD9D9D9), // Set dialog background color
        );
      },
    );
  }
  void saveActivity(BuildContext context, String imgLink, String activityBy,
      String activityUserAvatar, String type, String userId,String userAvatar,DateTime time) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      String currentUserId = user.uid;

      // Create a map representing the saved post
      Map<String, dynamic> savedPost = {
        'imageLink': imgLink ?? '',
        'activityBy': activityBy ?? '',
        'activityUserAvatar': activityUserAvatar ?? '',
        'type': type,
        'avatar':userAvatar,
        'time':time
      };

      // Save the post information to the current user's data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('activity')
          .add(savedPost);

    }


  }

  void updateLikes(int newLikes, int index, String username) async {
    String currentUsername = widget.bookData['username'] ?? '';
    List<dynamic> likedBy = List<String>.from(widget.bookData['likedBy'] ?? []);

    if (!likedBy.contains(username)) {
      likedBy.add(username);

      // Update Firestore document with newLikes and updated likedBy
      await FirebaseFirestore.instance
          .collection('communityBooks')
          .doc(widget.documentId)
          .update({'likes': newLikes, 'likedBy': likedBy});

      log('Liked on index: $index');
    } else {
      likedBy.remove(username);

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
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Adjust the radius as needed
      ),
      color: Color(0xffD9D9D9),
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
                      radius: 20,
                      backgroundColor:  Color(0xFFFEEAD4),
                      backgroundImage: NetworkImage(
                        avatarUrl,
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text( username.toUpperCase(),style: TextStyle(fontFamily: 'font',fontSize: 12,fontWeight: FontWeight.bold),),
                        Container(
                            width: 210,
                            child: Text(comment,style: TextStyle(fontFamily: 'font',fontSize: 14),)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommentPage extends StatefulWidget {
  List<Map<String, dynamic>> comments;
  String docId;
  final VoidCallback onPressed;
  int commentCount;
  final Map<String, dynamic> bookData;

  CommentPage(
      {Key? key,
      required this.comments,
      required this.docId,
      required this.onPressed,
      required this.commentCount,
      required this.bookData})
      : super(key: key);

  @override
  _CommentPageState createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  bool isLoading = false;


  @override
  void initState() {
    super.initState();

  }
  Future<void> reloadComments() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('communityBooks')
        .doc(widget.docId)
        .collection('comments')
        .get();

    // Update the comments list
    setState(() {
      widget.comments = snapshot.docs.map<Map<String, dynamic>>((doc) => doc.data()! as Map<String, dynamic>).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
                  fontFamily: "font",
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfffeead4),
                  height: 29 / 22,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 80.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      20.0), // Adjust the radius as needed
                ),
                color: Color(0xFFFF997A),
                elevation: 8,
                margin: EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: widget.commentCount == 0
                      ? Center(
                          child: Column(
                            children: [
                              Expanded(
                                  child:
                                      Center(child: Text("No Comments yet",style: TextStyle(fontFamily: 'font'),))),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xffD9D9D9),
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
                                            // controller: commentController,
                                            onChanged: (value) {
                                              setState(() {
                                                comment = value;
                                              });
                                            },
                                            cursorColor: Color(0xFF283E50),
                                          decoration: InputDecoration(
                                            hintText: 'Add your comment',
                                            hintStyle: TextStyle(color: Colors.grey,fontFamily: 'font')
                                          ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFF283E50),
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(10),
                                            ),
                                          ),
                                          child: TextButton(
                                            onPressed: widget.onPressed,
                                            child: Text(
                                              'Comment',
                                              style: TextStyle(color: Colors.white,fontFamily: 'font'),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
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
                                      backgroundColor: Color(0xFFFEEAD4),
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
                                Container(
                                  height: 150,
                                  width: 100,
                                  child: Image.network(
                                    widget.bookData['imageLink'] ?? '',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                )
                              ],
                            ),
                            Column(
                              children: [

                                Padding(
                                  padding: const EdgeInsets.only(top: 20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [

                                      Container(
                                        height: 120,
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
                                                  fontWeight: FontWeight.w500,fontFamily:'font'),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10,),
                                      // GestureDetector(
                                      //     onTap: (){
                                      //       _showConfirmationDialogToSave(context);
                                      //     },
                                      //     child: Icon(Icons.download))
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ],
                        ),
                        Divider(
                          color: Color(0xff686868),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Comments ${widget.commentCount}',style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold),),
                            Text('${widget.bookData['likes'] } Likes',style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                            SizedBox(height: 5,),
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
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Color(0xffD9D9D9),
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
                                          controller: commentController,
                                          onChanged: (value) {
                                            setState(() {
                                              comment = value;
                                            });
                                          },
                                          cursorColor: Color(0xFF283E50),
                                          decoration: InputDecoration(
                                              hintText: 'Add your comment',
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFF283E50),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                        ),
                                        child: TextButton(
                                          onPressed:(){

                                            setState(() {

                                              widget.onPressed();
                                              commentController.clear();
                                              Navigator.pop(context);
                                            });
                                          },
                                          child: Text(
                                            'Comment',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
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
    reloadComments();
  }
}
