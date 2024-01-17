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

          // Process the data and build the UI
          List<QueryDocumentSnapshot> bookDocuments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookDocuments.length,
            itemBuilder: (context, index) {
              var bookData = bookDocuments[index].data() as Map<String, dynamic>;
              return BookCard(bookData: bookData);
            },
          );
        },
      ),
    );
  }

}
class BookCard extends StatelessWidget {
  final Map<String, dynamic> bookData;

  const BookCard({Key? key, required this.bookData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(bookData['avatarUrl'] ?? ''),
            ),
            title: Text(bookData['username'] ?? 'Anonymous'),
          ),
          Container(
            height: 150, // Set a fixed height for the image
            width: double.infinity,
            child: Image.network(
              bookData['imageLink'] ?? '',
              fit: BoxFit.contain, // Ensure the image covers the container
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookData['title'] ?? '',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '${bookData['notes'] ?? ''}',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


