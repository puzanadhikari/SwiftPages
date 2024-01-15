import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Timer extends StatefulWidget {
  const Timer({Key? key}) : super(key: key);

  @override
  State<Timer> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  final int _duration = 10;
  final CountDownController _controller = CountDownController();
  late bool _isRunning;

  @override
  void initState() {
    super.initState();
    _isRunning = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFEEAD4),
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
              left: MediaQuery.of(context).size.width / 3,
              child: Text(
                "My Books",
                style: const TextStyle(
                  fontFamily: "Abhaya Libre ExtraBold",
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xfffeead4),
                  height: 29 / 22,
                ),
              ),
            ),
            Center(
              child: Column(
                children: [
                  CircularCountDownTimer(
                    duration: _duration,
                    controller: _controller,
                    width: MediaQuery.of(context).size.width / 2,
                    height: MediaQuery.of(context).size.height / 2,
                    ringColor: Colors.grey[300]!,
                    fillColor: Colors.purpleAccent[100]!,
                    backgroundColor: Colors.purple[500],
                    strokeWidth: 20.0,
                    strokeCap: StrokeCap.round,
                    textStyle: const TextStyle(
                      fontSize: 33.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    isReverse: false,
                    isReverseAnimation: false,
                    isTimerTextShown: true,
                    autoStart: false,
                    onStart: () {
                      debugPrint('Countdown Started');
                    },
                    onComplete: () {
                      debugPrint('Countdown Ended');
                      setState(() {
                        _isRunning = false;
                      });
                      updateStrikeInFirestore();
                      // Reset the timer when completed
                      _controller.restart(duration: _duration);
                    },
                    onChange: (String timeStamp) {
                      debugPrint('Countdown Changed $timeStamp');
                    },
                    timeFormatterFunction: (defaultFormatterFunction, duration) {
                      if (duration.inSeconds == 0) {
                        return "Start";
                      } else {
                        return Function.apply(defaultFormatterFunction, [duration]);
                      }
                    },
                  ),

                  ElevatedButton(
                    onPressed: _handleTimerButtonPressed,
                    child: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                ],
              ),
            ),
          ],
        ),
        extendBody: true,
      ),
    );
  }
  Future<void> updateStrikeInFirestore() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      // Check if the user is authenticated
      if (user != null) {
        String uid = user.uid;

        // Get the current strikes count from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

        // Check if 'strikes' field exists, otherwise set it to 0
        int currentStrikes = userDoc.data()?.containsKey('strikes') ?? false
            ? userDoc.get('strikes')
            : 0;

        // Update the strikes count in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'strikes': currentStrikes + 1});
      }
    } catch (e) {
      print('Error updating strike in Firestore: $e');
    }
  }

  void _handleTimerButtonPressed() {
    setState(() {
      if (_isRunning) {
        _controller.pause();
      } else {
        _controller.resume();
      }
      _isRunning = !_isRunning;
    });
  }
}
