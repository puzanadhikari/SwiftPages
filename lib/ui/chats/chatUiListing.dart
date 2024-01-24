import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((querySnapshot) {

      return querySnapshot.docs
          .map((doc) => {

        'userId': doc.id,
        'username': doc['username'] ?? 'Unknown User',

        // Add any other properties you need
      })
          .toList();
    });

    currentUserId = _auth.currentUser?.uid ?? '';

  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('chats')
          .where('users', arrayContains: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No chats available'),
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
                      return Center(
                        child: Text('No users available'),
                      );
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

            SizedBox(height: 20,),
            Expanded(
              child: ListView.builder(
                itemCount: chatDocs.length,
                itemBuilder: (context, index) {
                  var chatDoc = chatDocs[index];
                  var participants = chatDoc['users'] as List<dynamic>;

                  // Exclude the current user from the participants
                  participants.remove(currentUserId);

                  return ChatListItem(
                    participantId: participants[0],
                    currentUserId: currentUserId,
                  );
                },
              ),
            ),
          ],
        );
      },
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
                      log('Selected User: $userId');
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
            // value: selectedUserId,
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

  ChatListItem({required this.participantId, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(participantId)
          .get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return CircularProgressIndicator();
        }

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
              return CircularProgressIndicator();
            }

            var lastMessage = chatSnapshot.data!['messages'].last;
            var lastMessageText = lastMessage['text'] ?? 'No messages yet';
            var lastMessageTimestamp = lastMessage['timestamp'];

            return Padding(
              padding: const EdgeInsets.all(5.0),
              child: Card(

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      20.0), // Adjust the radius as needed
                ),
                color: Color(0xFFFF997A),
                child: ListTile(
                  title: Row(
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lastMessageText.length > 20
                                    ? '${lastMessageText.substring(0, 20)}...'
                                    : lastMessageText,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),

                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                _formatTimestamp(lastMessageTimestamp),
                                style: TextStyle( fontSize: 12),
                              ),
                            ],
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
