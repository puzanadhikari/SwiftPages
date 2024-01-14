import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String email = ' ';
  String userName = ' ';

  Future<void> fetchUserInfo() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    email  = preferences.getString("email")!;
    userName  = preferences.getString("userName")!;
  }

  @override
  void initState() {
    super.initState();

    fetchUserInfo();
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
              top: -20,
              left: -10,
              child: Image.asset(
                "assets/logo.png",
                height: 120,
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: Image.asset(
                "assets/search.png",
                height: 50,
              ),
            ),

            Positioned(
              top: 20,
              left: MediaQuery.of(context).size.width / 2.5,
              child: Row(
                children: [
                  const Text(
                    "Home",
                    style: TextStyle(
                      fontFamily: "Abhaya Libre ExtraBold",
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xfffeead4),
                      height: 29 / 22,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Image.asset(
                      "assets/strick.png",
                      height: 50,
                    ),
                  ),
                  Text("9",style: TextStyle(
                    fontSize: 14,
                    color: Color(0xfffeead4),
                  ),)
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

