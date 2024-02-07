import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:swiftpages/ui/homePage.dart';
import 'package:swiftpages/ui/myBooks.dart';
import 'package:swiftpages/ui/profilePage.dart';

import '../firebase_auth.dart';
import 'chart/ui.dart';
import 'community/ui.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User ? _user;


  void updateStrikeIfNeeded() async {
    User? user = FirebaseAuth.instance.currentUser;
    // Replace 'your_users_collection' with the actual name of your collection
    final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

    // Get the user document
    DocumentSnapshot userDoc = await usersCollection.doc(user?.uid).get();

    if (userDoc.exists) {
      // Get the login timestamp and last strike timestamp from the document
      Timestamp loginTimestamp = userDoc['lastLoginTimestamp'];
      Timestamp lastStrikeTimestamp = userDoc['lastStrikeTimestamp'];

      // Calculate the time difference in hours
      // int timeDifferenceInHours = loginTimestamp.seconds - lastStrikeTimestamp.seconds ~/ 3600;
      // Calculate the time difference in hours
      int timeDifferenceInSeconds = (loginTimestamp.seconds) - lastStrikeTimestamp.seconds;
      int timeDifferenceInHours = (timeDifferenceInSeconds / 3600).floor();
      //log("time diff: " + timeDifferenceInHours.toString() + " hours");

      //log("//logintime"+//loginTimestamp.seconds.toString());
      //   log("striktime"+lastStrikeTimestamp.seconds.toString());
      //   log("time diff"+timeDifferenceInHours.toString());

      if (timeDifferenceInHours > 24||timeDifferenceInHours ==24) {
        // Update the strike to 0
      setState(() {
         usersCollection.doc(user?.uid).update({'lastStrike': userDoc['strikes'],'strikes':0});
      });

        // Update the last strike timestamp to the current time
        await usersCollection.doc(user?.uid).update({'lastStrikeTimestamp': Timestamp.now()});
      }
    }
  }
  String home = '';
  String myBooks = '';
  String graph = '';
  String profile = '';
  // Future<void> loadIcons() async {
  //   try {
  //     Reference homeIcon = FirebaseStorage.instance.ref().child('assets/home.png');
  //     Reference myBooksIcon = FirebaseStorage.instance.ref().child('assets/myBooks.png');
  //     Reference graphIcon = FirebaseStorage.instance.ref().child('assets/graph.png');
  //     Reference profileIcon = FirebaseStorage.instance.ref().child('assets/profile.png');
  //     home = await homeIcon.getDownloadURL();
  //     myBooks = await myBooksIcon.getDownloadURL();
  //     graph = await graphIcon.getDownloadURL();
  //     profile = await profileIcon.getDownloadURL();
  //
  //     setState(() {
  //
  //     });
  //     //log('Download URL: $avatarUrls');
  //   } catch (e) {
  //     //log('Error fetching QR image: $e');
  //   }
  // }
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // loadIcons();
    updateStrikeIfNeeded();
    _auth.authStateChanges().listen((event) {
      setState(() {
       _user = event;
      });
    });

  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEEAD4),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          HomePage(),
          MyBooks(),
          GraphPage(),

          ProfilePage(),

        ],
      ),
      extendBody: false,
      bottomNavigationBar: Stack(
        children: [
          FloatingNavbar(
            borderRadius: 40.0,
            selectedBackgroundColor: Colors.transparent,
            selectedItemColor: Color(0xffFF997A),
            unselectedItemColor: Color(0xffFF997A),
            backgroundColor: Color(0xFF283E50),
            onTap: _onTabTapped,
            currentIndex: _currentIndex,
            items: [
              FloatingNavbarItem(icon: Icons.home, title: '',customWidget: SvgPicture.asset('assets/home.svg',
        height: 30,
        color: Color(0xffFF997A),
      ),),
              FloatingNavbarItem(icon: Icons.book, title: '',customWidget: SvgPicture.asset('assets/myBooks.svg',
                height: 30,
                color: Color(0xffFF997A),
              ),),
              FloatingNavbarItem(icon: Icons.auto_graph, title: '',customWidget: SvgPicture.asset('assets/graph.svg',
                height: 30,
                color: Color(0xffFF997A),
              ),),
              FloatingNavbarItem(icon: Icons.person_2_outlined, title: '',customWidget: SvgPicture.asset('assets/person.svg',
                height: 30,
                color: Color(0xffFF997A),
              ),),
            ],
          ),
          // AnimatedPositioned(
          //   duration: Duration(milliseconds: 300),
          //   top: 15,
          //   left: 20.0 + MediaQuery.of(context).size.width/2.2 * 0.5 * _currentIndex,
          //   child: Container(
          //     height: 40,
          //     width: MediaQuery.of(context).size.width * 0.2,
          //     decoration: BoxDecoration(
          //       shape: BoxShape.circle,
          //       color: Colors.white24,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
