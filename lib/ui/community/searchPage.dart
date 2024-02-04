import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:swiftpages/ui/chats/ui.dart';

import 'myPosts.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String currentUserId;
  String selectedUserId = '';
  String selectedUserName = '';
  late TextEditingController _searchController;
  late Stream<List<Map<String, dynamic>>> _usersStream;
  List<Map<String, dynamic>> _users = [];
  String avatar='';
  Map<String, int> unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) =>
      {

        'userId': doc.id,
        'username': doc['username'] ?? 'Unknown User',

        // Add any other properties you need
      })
          .toList();
    });

    currentUserId = _auth.currentUser?.uid ?? '';
    _firestore
        .collection('chats')
        .where('users', arrayContains: currentUserId)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      // Update unread counts whenever the chat data changes
      Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        List<dynamic> users = doc['users'];
        users.remove(currentUserId);

        int unreadCount = 0;

        if (doc['messages'] != null) {
          for (var message in doc['messages']) {
            if ( message['unread'] == true) {
              unreadCount++;
            }
          }
        }

        log(users[0]);
        counts[users[0]] = unreadCount;
      }

      setState(() {
        unreadCounts = counts;
        log(unreadCounts.toString());
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('chats')
              .where('users', arrayContains: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  // _buildUserDropdown(),
                  // _buildUserSearch(),
                  SizedBox(height: 10,),
                  Container(
                    height: 50,
                    padding: EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: Colors.grey[200], // Change the color as needed
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none, // Remove the default border
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),

                  Visibility(
                    visible: _searchController.text.isEmpty?false:true,
                    child: Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _usersStream,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Text('No users available');
                          }

                          _users = snapshot.data!;

                          return Visibility(
                            visible: _searchController.text.isEmpty?false:true,
                            child: Card(
                              color: Colors.white,
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0), // Set the border radius
                              ),
                              child: ListView.builder(
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  var user = _users[index];
                                  var userId = user['userId'];
                                  var username = user['username'];
                                  var avatar = user['avatar'];

                                  return ListTile(
                                    title: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: NetworkImage(avatar),
                                          radius: 20,
                                          backgroundColor: Color(0xFF283E50),
                                        ),
                                        Text(username),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatPage(
                                            recipientUserId: userId,
                                            recipientUsername: username,
                                            recipientAvatar: avatar,
                                          ),
                                        ),
                                      );
                                      setState(() {
                                        _searchController.clear();
                                      });
                                      log('Selected User: $userId');
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                ],
              );
            }

            var chatDocs = snapshot.data!.docs;

            return Column(
              children: [
                // _buildUserDropdown(),
                // _buildUserSearch(),
                SizedBox(height: 10,),
                Container(
                  height: 50,
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.0),
                    color: Colors.grey[200], // Change the color as needed
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none, // Remove the default border
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),

                Visibility(
                  visible: _searchController.text.isEmpty?false:true,
                  child: Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _usersStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Text('No users available');
                        }
                        _users = snapshot.data!;
                        return Visibility(
                          visible: _searchController.text.isEmpty?false:true,
                          child: Card(
                            color: Colors.white,
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0), // Set the border radius
                            ),
                            child: ListView.builder(
                              itemCount: _users.length,
                              itemBuilder: (context, index) {
                                var user = _users[index];
                                var userId = user['userId'];
                                var username = user['username'];
                                var avatar = user['avatar'];

                                return ListTile(
                                  title: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(avatar),
                                        radius: 20,
                                        backgroundColor: Color(0xFF283E50),
                                      ),
                                      Text(username),
                                    ],
                                  ),
                                  onTap: () {
                                    fetchUserDetailsById(userId);
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),


              ],
            );
          },
        ),
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _usersStream = FirebaseFirestore.instance
          .collection('users')
          .orderBy('username', descending: false)
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .snapshots()
          .map((querySnapshot) {
        return querySnapshot.docs
            .map((doc) => {
          'userId': doc.id,
          'username': (doc['username'] as String?) ?? 'Unknown User',
          'avatar' : doc['avatar']
          // Add any other properties you need
        })
            .toList();
      });
    });
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
                                Text("${userData['username']}",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontSize: 16),),
                                Text("${userData['email']}",style: TextStyle(color: Color(0xff283E50),fontSize: 14),),
                              ],
                            ),

                          ],
                        ),

                        Row(
                          children: [
                            Image.asset(
                              "assets/strick.png",
                              height: 40,
                              color: Colors.black,
                            ),
                            Text(userData['strikes'].toString(), style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            )),
                          ],
                        ),

                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
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
                      child: Text("Chat"),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      Text(widget.bookData['username'] ?? 'Anonymous'),
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
                        color: Color(0xFF283E50),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) => CommentPage(
                        //           comments: comments,
                        //           docId: widget.documentId,
                        //           onPressed: () {
                        //             addComment(comment);
                        //             saveActivity(
                        //                 context,
                        //                 widget.bookData['imageLink'],
                        //                 currentUsername ,
                        //                 widget.bookData['avatarUrl'],
                        //                 'Comment',
                        //                 widget.bookData['userId'],
                        //                 currentUserAvatar,
                        //                 DateTime.now()
                        //
                        //             );
                        //           },
                        //           commentCount: comments.length, bookData: widget.bookData,
                        //
                        //         )));
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
                        color: Color(0xFF283E50),
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
                                  fontWeight: FontWeight.w500),
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
                                Text("${userData['username']}",style: TextStyle(color: Color(0xff283E50),fontWeight: FontWeight.bold,fontSize: 16),),
                                Text("${userData['email']}",style: TextStyle(color: Color(0xff283E50),fontSize: 14),),
                              ],
                            ),

                          ],
                        ),

                        Row(
                          children: [
                            Image.asset(
                              "assets/strick.png",
                              height: 40,
                              color: Colors.black,
                            ),
                            Text(userData['strikes'].toString(), style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
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
            style: TextStyle(color: Colors.black), // Set title text color
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
                          color: Colors.black,
                        ),
                        Text(strikes.toString(), style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
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
            style: TextStyle(color: Colors.blue), // Set title text color
          ),
          content: Text("Are you sure want to save this post?"),
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
                // savePost(
                //     context,
                //     widget.bookData['imageLink'],
                //     widget.bookData['username'],
                //     widget.bookData['avatarUrl'],
                //     widget.bookData['notes']);
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