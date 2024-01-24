import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class GroupChat extends StatefulWidget {
  final String userId;
  final String username;

  const GroupChat({Key? key, required this.userId, required this.username}) : super(key: key);

  @override
  _GroupChatState createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.username}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _firestore
                  .collection('chats')
                  .where('users', arrayContains: _auth.currentUser?.uid)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                var messages = snapshot.data!.docs
                    .where((doc) =>
                doc['users'].contains(widget.userId) &&
                    doc['users'].contains(_auth.currentUser?.uid))
                    .expand((doc) => doc['messages'])
                    .toList();


                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    return ListTile(
                      title: Text(message['text']),
                      subtitle: Text(message['sender']),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    String messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      String currentUserId = _auth.currentUser?.uid ?? '';
      String currentUserUsername = _auth.currentUser?.displayName ?? '';

      // Create a new message map
      Map<String, dynamic> message = {
        'text': messageText,
        'sender': currentUserUsername,
        'timestamp': DateTime.now,
      };

      // Add the message to the chats collection
      await _firestore.collection('chats').add({
        'users': [currentUserId, widget.userId],
        'messages': [message],
      });

      // Clear the message input field
      _messageController.clear();
    }
  }
}
