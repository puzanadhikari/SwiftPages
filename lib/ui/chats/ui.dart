import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String recipientUserId;
  final String recipientUsername;
  final String recipientAvatar;


  const ChatPage({Key? key, required this.recipientUserId, required this.recipientUsername,required this.recipientAvatar}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
   String? currentUserAvatar ;
  late String roomId; // Add this line
  late int unreadMessagesCount;
  @override
  void initState() {
    super.initState();
    currentUserAvatar = _auth.currentUser!.photoURL;
    log(widget.recipientUserId+widget.recipientAvatar);
    roomId = _getRoomId(_auth.currentUser?.uid, widget.recipientUserId);
    _markMessagesAsRead();
  }

  String _getRoomId(String? userId1, String? userId2) {
    List<String?> sortedIds = [userId1, userId2]..sort();
    return "${sortedIds[0]}_${sortedIds[1]}";
  }
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime); // Format the timestamp as per your requirement
  }

  void _markMessagesAsRead() async {
    // Get the chat document
    DocumentSnapshot<Map<String, dynamic>> chatDocument =
    await _firestore.collection('chats').doc(roomId).get();

    // Check if the chat document exists
    if (chatDocument.exists) {
      // Update unread messages to false
      List<dynamic> messages = chatDocument['messages'] ?? [];

      List<Map<String, dynamic>> updatedMessages = (messages as List<dynamic>)
          .map((message) => Map<String, dynamic>.from(message)
        ..['unread'] = false)
          .toList();

      await _firestore.collection('chats').doc(roomId).update({
        'messages': updatedMessages,
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    String currentUserId = _auth.currentUser?.uid ?? '';

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFFEEAD4),
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
              top: 20,
              left: MediaQuery.of(context).size.width / 2.5,
              child:  Text(
                'Chat Box',
                style: TextStyle(
                  fontFamily: "Abhaya Libre ExtraBold",
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfffeead4),
                  height: 29 / 20,
                ),
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
              top:110,
              left: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white, // Customize as needed
                    backgroundImage: NetworkImage(widget.recipientAvatar),
                  ),
                  SizedBox(width: 10,),
                  Text(widget.recipientUsername,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20,color: Colors.white),)
                ],
              ),
            ),
        Padding(
          padding: const EdgeInsets.only(top:200.0),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xffD9D9D9),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(50),
                topLeft: Radius.circular(50),
              ),
            ),
            child: Column(
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(vertical: 10.0),
                      //   child: Text(
                      //     'Unread Messages: $unreadMessagesCount',
                      //     style: TextStyle(
                      //       fontSize: 16.0,
                      //       fontWeight: FontWeight.bold,
                      //       color: Colors.black,
                      //     ),
                      //   ),
                      // ),
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
                            var messages = chatDocument['messages'].reversed.toList() as List<dynamic>? ?? [];
                            return Padding(
                              padding: const EdgeInsets.all(15.0),
                              child:  ListView.builder(
                                itemCount: messages.length,
                                reverse: true,
                                itemBuilder: (context, index) {
                                  var message = messages[index];
                                  bool isCurrentUser = message['sender'] == _auth.currentUser?.displayName;

                                  return Align(
                                    alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                                    child: GestureDetector(
                                      onLongPress: (){
                                        // _showDeleteMessageDialog(index); // Pass messageId or any identifier
                                      },
                                      child: Container(
                                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                        padding: EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: isCurrentUser ? Color(0xFF283E50) : Colors.grey[300],
                                          borderRadius: BorderRadius.circular(20.0),
                                        ),
                                        child: Stack(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message['text'],
                                                  style: TextStyle(
                                                    color: isCurrentUser ? Colors.white : Colors.black,
                                                    fontSize: 14.0,
                                                  ),
                                                ),
                                                SizedBox(height: 5,),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.end,
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      _formatTimestamp(message['timestamp']),
                                                      style: TextStyle(
                                                        color: isCurrentUser ? Colors.white : Colors.black,
                                                        fontSize: 8.0,
                                                      ),
                                                    ),
                                                    SizedBox(width: 5,),
                                                    // if (isCurrentUser)
                                                    //   SvgPicture.asset(
                                                    //     'assets/tick.svg', // Replace with the correct path to your tick.svg image
                                                    //     height: 8,
                                                    //     width: 8,
                                                    //     color:message['unread']==true?Colors.white:Color(0xFFFEEAD4), // Customize the color as needed
                                                    //   ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )



                            );

                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color:Color(0xffFEEAD4),
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
                                    controller: _messageController,
                                    onChanged: (value) {
                                      setState(() {
                                        // comment = value;
                                      });
                                    },
                                    cursorColor: Color(0xFF283E50),
                                    decoration: InputDecoration(
                                        hintText: 'Type your message...',
                                        hintStyle: TextStyle(color: Colors.grey)
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
                                    onPressed: (){
                                      _sendMessage(currentUserId);
                                    },
                                    child: Text(
                                      'Send',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(8.0),
                      //   child: Row(
                      //     children: [
                      //       Expanded(
                      //         child: TextField(
                      //           controller: _messageController,
                      //           decoration: InputDecoration(
                      //             border: OutlineInputBorder(
                      //                 borderSide: BorderSide(color: Color(0xFF283E50)),
                      //               borderRadius: BorderRadius.all(Radius.circular(10.0))
                      //             ),
                      //             hintText: 'Type your message...',
                      //           ),
                      //         ),
                      //       ),
                      //       IconButton(
                      //         icon: Icon(Icons.send),
                      //         onPressed: () {
                      //           _sendMessage(currentUserId);
                      //         },
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
          ),
        ),
          ],
        ),
      ),
    );
  }
  // void _showDeleteMessageDialog(int index) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text('Delete Message'),
  //         content: Text("Are you sure you want to delete this message?"),
  //         actions: <Widget>[
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context); // Close the dialog
  //             },
  //             child: Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               setState(() {
  //                 deleteMessage(index);
  //               });
  //               Navigator.pop(context);
  //             },
  //             child: Text('Delete'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }
  // void deleteMessage(int index) {
  //   DocumentReference<Map<String, dynamic>> roomDocument =
  //   _firestore.collection('chats').doc(roomId);
  //
  //   roomDocument.get().then((documentSnapshot) {
  //     if (documentSnapshot.exists) {
  //       Map<String, dynamic>? roomData = documentSnapshot.data();
  //
  //       if (roomData != null) {
  //         List<dynamic> messages = roomData['messages'] ?? [];
  //
  //         if (index >= 0 && index < messages.length) {
  //           messages.removeAt(index);
  //
  //           // Update the 'messages' field with the modified array
  //           roomDocument.update({'messages': messages});
  //         }
  //       }
  //     }
  //   });
  // }




  void _sendMessage(String currentUserId) async {
    String messageText = _messageController.text.trim();

    if (messageText.isNotEmpty) {
      String currentUserUsername = _auth.currentUser?.displayName ?? '';

      // Create a new message map
      Map<String, dynamic> message = {
        'text': messageText,
        'sender': _auth.currentUser?.displayName,
        'timestamp': DateTime.now(),
        'unread': true,
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
