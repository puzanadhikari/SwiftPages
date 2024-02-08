import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:swiftpages/ui/spashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize local notifications
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Configure the initialization settings for Android and iOS
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);


  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Map<String, dynamic>? latestActivity;
  Map<String, dynamic>? latestMessage;

  bool initialDataRetrieved = false;

  Stream<List<Map<String, dynamic>>> activitiesStream =
  FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('activity')
      .snapshots()
      .map((querySnapshot) {
    List<Map<String, dynamic>> activities = [];
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      activities.add(doc.data() as Map<String, dynamic>);
    }
    return activities;
  });

  activitiesStream.listen((List<Map<String, dynamic>> activities) {
    if (activities.isNotEmpty) {
      activities.sort((a, b) =>
          (b['time'] as Timestamp).compareTo(a['time'] as Timestamp));

      Map<String, dynamic> newLatestActivity = activities.first;

      // Check if it's the initial data retrieval
      if (!initialDataRetrieved) {
        // Update the latest activity without showing a notification
        latestActivity = newLatestActivity;
        initialDataRetrieved = true;
      } else {
        // Check if the new activity is different from the latest one
        if (latestActivity == null || latestActivity != newLatestActivity) {
          // Show the latest notification
          showNotification(
            flutterLocalNotificationsPlugin,
            newLatestActivity['type'],
            newLatestActivity['activityBy'],
          );

          // Update the latest activity
          latestActivity = newLatestActivity;
        }
      }
    }
  });

  runApp(MyApp(
    flutterLocalNotificationsPlugin: flutterLocalNotificationsPlugin,
  ));
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const MyApp({Key? key, required this.flutterLocalNotificationsPlugin})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

Future<void> showNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    String type,
    String activityBy,
    ) async {
  //log("here" + type + activityBy);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'notification_swift_pages',
    'Swift Pages',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    showWhen: false,
  );

  var platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    '$activityBy $type',
    'Tap to view',
    platformChannelSpecifics,
    payload: 'activity_notification',
  );
}
// Future<void> showNotificationChat(
//     FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
//     String sender,
//     String text,
//     ) async {
//   log("New message Received");
//   var androidPlatformChannelSpecifics = AndroidNotificationDetails(
//     'notification_chat',
//     'Chat Notifications',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//     showWhen: false,
//
//   );
//
//   var platformChannelSpecifics = NotificationDetails(
//     android: androidPlatformChannelSpecifics,
//   );
//
//   await flutterLocalNotificationsPlugin.show(
//     0,
//     'Message',
//     'You have new message!',
//     platformChannelSpecifics,
//     payload: 'chat_notification',
//   );
// }