import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swiftpages/ui/profilePage.dart';

import 'chats/chatUiListing.dart';
import 'community/myPosts.dart';
import 'community/savedPosts.dart';
import 'community/searchPage.dart';
import 'community/ui.dart';
import 'notificationPage.dart';

class TopNavigation extends StatefulWidget {
  bool isNotification ;
  TopNavigation(this.isNotification);
  @override
  State<TopNavigation> createState() => _TopNavigationState();
}

class _TopNavigationState extends State<TopNavigation> {
  late Stream<List<Map<String, dynamic>>> _usersStream;
  late TextEditingController _searchController;
  List<Map<String, dynamic>> _users = [];
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
  void initState() {
    // TODO: implement initState
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
  }
  @override
  Widget build(BuildContext context) {
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
              child: const Text(
                "Community",
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
              top:-20,
              left: -10,
              child: Image.asset(
                "assets/logo.png",
                height: 150,
              ),
            ),
            Positioned(
              top: 100, // Adjust the top position based on your design
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: TopNavigationBar(widget.isNotification),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ActivityList()));
                },
                child: Stack(
                  children: [
                    Icon(Icons.notifications,size: 35,),
                    Positioned(
                      left: 15,
                      child:StreamBuilder<int>(
                        stream: getActivityCountStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Container(); // Return an empty container while loading
                          } else if (snapshot.hasError) {
                            return Container(); // Handle the error case
                          } else {
                            int activityCount = snapshot.data ?? 0;
                            return activityCount > 0
                                ? CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.red,
                              child: Text(
                                activityCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                                : Container();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 40,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SearchPage()));
                },
                child: Image.asset(
                  "assets/search.png",
                  height: 50,
                ),
              ),
            ),




          ],
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


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class TopNavigationBar extends StatelessWidget {
  bool isNotification;

  TopNavigationBar(this.isNotification);
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex:isNotification==true?3:0,
      child: Scaffold(
        backgroundColor: Colors.transparent,

        body:  Container(
          decoration: BoxDecoration(
            color: Color(0xffD9D9D9),
            borderRadius: BorderRadius.all(
              Radius.circular(50),
            ),
          ),

          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(text: 'Activity'),
                    Tab(text: 'My Post'),
                    Tab(text: 'Saved'),
                    Tab(text: 'Chats'),
                  ],
                  labelColor: Color(0xFF283E50),
                  indicatorPadding: EdgeInsets.all(2),
                  indicatorColor: Color(0xFF283E50),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Community(),
                      MyPosts(),
                      SavedPosts(),
                      ChatList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}


