import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../firebase_auth.dart';

class ChooseAvatars extends StatefulWidget {
  TextEditingController? _email;
  TextEditingController? _username;
  TextEditingController? _password;

  ChooseAvatars(this._email,this._username,this._password);
  @override
  State<ChooseAvatars> createState() => _ChooseAvatarsState();
}

class _ChooseAvatarsState extends State<ChooseAvatars> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  late List<String> avatarUrls;
  String? selectedAvatar;
  final storage = FirebaseStorage.instance;
  Reference get firebaseStorage => FirebaseStorage.instance.ref();

  Future<void> loadAvatars() async {
    List<String> urls = [];

    try {
      ListResult result = await firebaseStorage.child("avatars/").listAll();

      for (Reference ref in result.items) {
        final imageUrl = await ref.getDownloadURL();
        urls.add(imageUrl);
      }
    } catch (e) {
      log('Error fetching avatar URLs: $e');
    }

    setState(() {
      avatarUrls = urls;
    });
  }

  @override
  void initState() {
    super.initState();
    avatarUrls = [];
    selectedAvatar = null;
    loadAvatars();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:  Color(0xFFFF997A),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 200, // Adjust the height as needed
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/EllipseAvatars.png'), // Replace with your image asset
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: Text(
                      "Choose Your Avatar!!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF283E50),
                      ),
                    ),
                  ),
                  SizedBox(height: 50,),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: avatarUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedAvatar = avatarUrls[index];
                            });
                          },
                          child: Container(
                            width: 60.0,
                            height: 60.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedAvatar == avatarUrls[index]
                                  ? Color(0xFF283E50)
                                  : Colors.white,
                            ),
                            child: CachedNetworkImage(
                              imageUrl: avatarUrls[index],
                              fit: BoxFit.scaleDown,
                              width: 100.0,
                              height: 100.0,
                              useOldImageOnUrlChange: false,
                              placeholder: (context, url) => CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedAvatar != null) {
                        // Handle the logic when the "SAVE" button is pressed
                        log('Selected Avatar Path: $selectedAvatar');
                      } else {
                        // Show a message if no avatar is selected
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please select an avatar.'),
                          ),
                        );
                      }
                      await _auth.SignUpWithEmailAndPassword(
                          context, widget._email!.text, widget._password!.text,widget._username!.text,selectedAvatar!);

                    },
                    style: ElevatedButton.styleFrom(
                      primary: selectedAvatar != null ? Color(0xFF283E50) : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width / 1.5,
                      height: 26,
                      child: Center(
                        child: Text(
                          'SAVE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontFamily: 'Abhaya Libre ExtraBold',
                            fontWeight: FontWeight.w800,
                            height: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
