import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:swiftpages/ui/chats/ui.dart';

class ChatList extends StatefulWidget {
  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
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

        //log(users[0]);
        counts[users[0]] = unreadCount;
      }

      setState(() {
        unreadCounts = counts;
        //log(unreadCounts.toString());
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                        hintStyle: TextStyle(fontFamily: 'font',),
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
                            return Text('No users available',style: TextStyle(fontFamily: 'font',),);
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
                                        Text(username,style: TextStyle(fontFamily: 'font',),),
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
                                      //log('Selected User: $userId');
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
                    hintStyle: TextStyle(fontFamily: 'font',),
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
                        return Text('No users available',style: TextStyle(fontFamily: 'font',),);
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
                                  //log('Selected User: $userId');
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

              SizedBox(height: 20,),
              Expanded(
                child: ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    var chatDoc = chatDocs[index];
                    var participants = chatDoc['users'] as List<dynamic>;
                    // log(participants[0].toString());

                    // Exclude the current user from the participants
                    participants.remove(currentUserId);

                    return ChatListItem(
                      participantId: participants[0],
                      currentUserId: currentUserId,
                      unreadCount: unreadCounts[participants[0]] ?? 0,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }



  Widget _buildUserSearch() {
    return  Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No users available'),
                );
              }

              _users = snapshot.data!;

              return ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  var user = _users[index];
                  var userId = user['userId'];
                  var username = user['username'];

                  return ListTile(
                    title: Text(username),
                    onTap: () {
                      // Handle user selection
                      //log('Selected User: $userId');
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
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


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Widget _buildUserDropdown() {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return Container();
        }
        var users = userSnapshot.data!.docs;
        return Container(
          // width: 2,
          height: 20,
          child: DropdownButton<String>(
            hint: Text('Select a user'),
            onChanged: (String? userId) {
              setState(() {
                selectedUserId = userId ?? '';
              });
            },
            items: users.map<DropdownMenuItem<String>>((user) {
              var userData = user.data();
              var userId = user.id;
              var username = userData?['username'] ?? 'Unknown User';

              // Ensure each value is unique
              return DropdownMenuItem<String>(
                value: userId, // Use a unique identifier, e.g., userId
                child: Text(username),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class ChatListItem extends StatelessWidget {
  final String participantId;
  final String currentUserId;
  final int unreadCount;

  ChatListItem({required this.participantId, required this.currentUserId,required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(participantId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return Center(
              child:   Text(""));
        }
        FirebaseAuth _auth = FirebaseAuth.instance;

        var userData = userSnapshot.data!.data();
        var participantUsername = userData?['username'] ?? 'Unknown User';
        var participantAvatar = userData?['avatar'] ?? 'default_avatar.png';

        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('chats')
              .doc(getChatId())
              .get(),
          builder: (context, chatSnapshot) {
            if (!chatSnapshot.hasData || !chatSnapshot.data!.exists) {
              return Text("");
            }

            var lastMessage = chatSnapshot.data!['messages'].last;
            var sender = chatSnapshot.data!['messages'].first;
            var lastSenderName = chatSnapshot.data!['messages'].last;
            var lastMessageText = lastMessage['text'] ?? 'No messages yet';
            var lastMessageTimestamp = lastMessage['timestamp'];

            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: GestureDetector(
                onLongPress: (){
                      //log(sender['sender']);
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Delete Message',style: TextStyle(fontFamily: 'font',),),
                        content: Text("Are you sure you want to delete this message and the entire chat?",style: TextStyle(fontFamily: 'font',),),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close the dialog
                            },
                            child: Text('Cancel',style: TextStyle(fontFamily: 'font',),),
                          ),
                          TextButton(
                            onPressed: () async {
                              FirebaseFirestore _firestore = FirebaseFirestore.instance;
                              //log(currentUserId+'_'+participantId);

                              Navigator.pop(context);
                              await _firestore.collection('chats').doc('${currentUserId+'_'+participantId}').delete();
                              await _firestore.collection('chats').doc('${participantId+'_'+currentUserId}').delete();
                            },
                            child: Text('Delete',style: TextStyle(fontFamily: 'font',),),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Card(

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        20.0), // Adjust the radius as needed
                  ),
                  color: Color(0xFFFF997A),
                  child: ListTile(
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(participantAvatar),
                              radius: 20,
                              backgroundColor: Color(0xFF283E50),
                            ),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  participantUsername,
                                  style: TextStyle(color:  Color(0xff283E50),
                                      fontSize: 16, fontWeight: FontWeight.bold,fontFamily: 'font',),
                                ),
                                SizedBox(height: 2,),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      lastMessageText.length > 20
                                          ? '${lastMessageText.substring(0, 20)}...'
                                          : lastMessageText,
                                      style: TextStyle(
                                        color: Color(0xffFEEAD4).withOpacity(0.8),
                                        fontSize: 12.0,fontFamily: 'font',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),






                                  ],
                                ),

                              ],
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              _formatTimestamp(lastMessageTimestamp),
                              textAlign: TextAlign.end,
                              style: TextStyle( fontSize: 12,fontFamily: 'font',color:  Color(0xff283E50)),
                            ),
                            if (lastSenderName['sender'] != _auth.currentUser?.displayName&&unreadCount!=0)

                              Container(
                                padding: EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: unreadCount > 0 ? Color(0xFF283E50) : Colors.transparent,
                                ),
                                child: Text(
                                  unreadCount > 9 ?'9+' :unreadCount.toString() ,
                                  style: TextStyle(fontSize: 12, color: Colors.white,fontFamily: 'font',),
                                ),
                              ),
                          ],
                        ),

                      ],
                    ),
                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            recipientUserId: participantId,
                            recipientUsername: participantUsername,
                            recipientAvatar: participantAvatar,

                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  String getChatId() {
    List<String?> sortedIds = [currentUserId, participantId]..sort();

    return "${sortedIds[0]}_${sortedIds[1]}";
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime); // Adjust the format as needed
  }
}
