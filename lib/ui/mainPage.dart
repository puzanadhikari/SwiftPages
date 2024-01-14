import 'package:firebase_auth/firebase_auth.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:swiftpages/ui/homePage.dart';
import 'package:swiftpages/ui/myBooks.dart';
import 'package:swiftpages/ui/profilePage.dart';

import '../firebase_auth.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User ? _user;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
          ProfilePage()
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
              FloatingNavbarItem(icon: Icons.home, title: ''),
              FloatingNavbarItem(icon: Icons.book, title: ''),
              FloatingNavbarItem(icon: Icons.explore, title: ''),
              FloatingNavbarItem(icon: Icons.person, title: ''),
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
