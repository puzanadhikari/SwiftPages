
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';


class ActivityList extends StatefulWidget {


  @override
  _ActivityListState createState() => _ActivityListState();
}

class _ActivityListState extends State<ActivityList> {
  late Future<List<Map<String, dynamic>>> activities;
  Future<List<Map<String, dynamic>>> getActivities() async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('activity')
        .get();

    List<Map<String, dynamic>> activities = [];

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      activities.add(doc.data() as Map<String, dynamic>);
    }

    return activities;
  }

  @override
  void initState() {
    super.initState();
    activities = getActivities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Activities'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: activities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            List<Map<String, dynamic>> activityList = snapshot.data ?? [];

            return ListView.builder(
              itemCount: activityList.length,
              itemBuilder: (context, index) {
                var activity = activityList[index];

                // Create a widget to display the activity
                // You can customize this based on your data structure
                return ListTile(
                  title: Text(activity['type'] ?? ''),
                  subtitle: Text(activity['activityBy'] ?? ''),
                  // Add other fields as needed
                );
              },
            );
          }
        },
      ),
    );
  }
}
