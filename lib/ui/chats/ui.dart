import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  final String recipientUserId;
  final String recipientUsername;

  const ChatPage({Key? key, required this.recipientUserId, required this.recipientUsername}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  late String roomId; // Add this line

  @override
  void initState() {
    super.initState();
    roomId = _getRoomId(_auth.currentUser?.uid, widget.recipientUserId);
  }

  String _getRoomId(String? userId1, String? userId2) {
    List<String?> sortedIds = [userId1, userId2]..sort();
    return "${sortedIds[0]}_${sortedIds[1]}";
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.recipientUsername}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('chats').doc(roomId).snapshots(),
              builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                var chatDocument = snapshot.data!;
                var messages = chatDocument['messages'] as List<dynamic>? ?? [];
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
                    _sendMessage(currentUserId);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String currentUserId) async {
    String messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      String currentUserUsername = _auth.currentUser?.displayName ?? '';

      // Create a new message map
      Map<String, dynamic> message = {
        'text': messageText,
        'sender': currentUserUsername,
        'timestamp': DateTime.now(),
      };

      // Get the chat document
      DocumentSnapshot<Map<String, dynamic>> chatDocument =
      await _firestore.collection('chats').doc(roomId).get();

      // Check if the chat document exists
      if (chatDocument.exists) {
        // Update the chat document with the new message
        await _firestore.collection('chats').doc(roomId).update({
          'messages': FieldValue.arrayUnion([message]),
        });
      } else {
        // Create the chat document if it doesn't exist
        await _firestore.collection('chats').doc(roomId).set({
          'users': [currentUserId, widget.recipientUserId],
          'messages': [message],
        });
      }

      // Clear the message input field
      _messageController.clear();
    }
  }
}
