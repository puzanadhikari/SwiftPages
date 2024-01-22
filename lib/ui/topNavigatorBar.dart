import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:swiftpages/ui/profilePage.dart';

import 'community/myPosts.dart';
import 'community/savedPosts.dart';
import 'community/ui.dart';
import 'notificationPage.dart';

class TopNavigation extends StatefulWidget {
  @override
  State<TopNavigation> createState() => _TopNavigationState();
}

class _TopNavigationState extends State<TopNavigation> {
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
              top: -20,
              left: -10,
              child: Image.asset(
                "assets/logo.png",
                height: 120,
              ),
            ),
            Positioned(
              top: 100, // Adjust the top position based on your design
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: TopNavigationBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TopNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
                    Tab(text: 'Notify'),
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
                      ActivityList(),
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


