import 'dart:developer';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

// import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timer_count_down/timer_count_down.dart';
import '../homePage.dart';
import '../myBooks.dart';
import 'package:timer_count_down/timer_controller.dart';

import '../reviewPage.dart';

class Music {
  final String title;
  final String path; // Add this field for storing the path

  Music({required this.title, required this.path});
}

class TimerPage extends StatefulWidget {
  DetailBook book;

  TimerPage({Key? key, required this.book}) : super(key: key);

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late Timer _timer;
  int additionalTimerValue = 0;

  Future<void> fetchUserInfo() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    int time = preferences.getInt('currentTime')!;
  }

  final CountdownController _controller = CountdownController(autoStart: false);
  final CountdownController _additionalController =
      CountdownController(autoStart: false);
  TextEditingController _quoteContoller = TextEditingController();
  TextEditingController _noteContoller = TextEditingController();
  TextEditingController _currentPage = TextEditingController();
  int totalTimeMin = 0;
  int totalTimeSec = 0;
  String dailyGoal = '';
  int _duration = 0;
  int currentTime = 0;
  List<int> year = [2015, 2016, 2017, 2018, 2019, 2020, 2021, 2022, 2023, 2024];
  List<int> days = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31
  ];

  List<String> month = [
    'Jan',
    'Feb',
    'March',
    'April',
    'May',
    'June',
    'July',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec'
  ];

  // final CountDownController _controller = CountDownController();
  late bool _isRunning;
  late bool _isPlaying;
  int totalPages = 0;

  Future<void> fetchData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          totalTimeMin = userDoc.get('totalTimeMin') ?? 0;
          totalTimeSec = userDoc.get('totalTimeSec') ?? 0;
        });
      }
    } catch (error) {
      //log('Error fetching data: $error');
    }
  }

  final AudioPlayer audioPlayer = AudioPlayer();

  double calculatePercentage() {
    if (widget.book == null) {
      return 0.0;
    }

    return (widget.book.currentPage / totalPages) * 100;
  }

  Reference get firebaseStorage => FirebaseStorage.instance.ref();
  String twoDigitMinutes = '';
  String twoDigitSeconds = '';

  Future<void> loadMusic() async {
    List<Music> urls = []; // Update the type to List<Music>

    try {
      ListResult result = await firebaseStorage.child("music/").listAll();

      for (Reference ref in result.items) {
        final musicUrl = await ref.getDownloadURL();
        String fileName = ref.name
            .split('.')
            .first; // Extracting the file name without extension
        urls.add(Music(
            title: fileName,
            path: musicUrl)); // Include the path in Music object
      }
    } catch (e) {
      //log('Error fetching music URLs: $e');
    }

    setState(() {
      musicUrls = urls;
      //log(musicUrls[0].path.toString());
    });
  }

  Future<void> playMusic(String path) async {
    if (path.isNotEmpty) {
      try {
        //log("play func" + path.toString());
        await audioPlayer.setUrl(path);

        await audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        log('Error playing music: $e');
      }
    } else {
      log('Error: Empty file path.');
    }
  }

  Future<void> pauseMusic() async {
    await audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  void _onTimerTick(Timer timer) {
    if (_stopwatch.isRunning) {
      setState(() {
        // Rebuild the widget tree to update the UI
      });
    }
  }

  int selectedNumber = 0;

  late Stopwatch _stopwatch;

  // @override
  // void dispose() {
  //   _timer.cancel();
  //   super.dispose();
  // }
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    String minutesStr = minutes < 10 ? '0$minutes' : '$minutes';
    String secondsStr =
        remainingSeconds < 10 ? '0$remainingSeconds' : '$remainingSeconds';

    return '$minutesStr:$secondsStr';
  }

  void _startPauseTimer() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        // _isRunning = false;
      } else {
        _stopwatch.start();

        // _isRunning = true;
      }
      _isRunning = !_isRunning;
      if (_isRunning) {
        _controller.start();
        _additionalController.start();
        _startAdditionalTimer();
      } else {
        _storeCurrentTime();
        // _showInvitationCodePopupToEnterCurrentPage(context);
        _controller.pause();
        _additionalController.pause();
        _pauseAdditionalTimer();
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _stopwatch.reset();
      _isRunning = false;
    });
  }

  void handlePlaybackResult(int result) {
    if (result == 1) {
      // Success
      log('Music started playing');
    } else {
      // Error
      log('Error playing music');
    }
  }

  List<Music> musicUrls = [
    // Add more music items as needed
  ];

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    loadMusic();
    fetchData();
    totalPages = widget.book.totalPage == 0 ? 200 : widget.book.totalPage;
    _isRunning = false;
    _isPlaying = false;
    _stopwatch = Stopwatch();
    _timer = Timer.periodic(Duration(seconds: 1), _onTimerTick);

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _retrieveStoredTime(); // Retrieve stored time when the widget is loaded
    });

    // WidgetsBinding.instance!.addPostFrameCallback((_) {
    //   _showPersistentMusicBottomSheet(context);
    // });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFFFEEAD4),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20),
            child: Container(
              color: Color(0xffD9D9D9),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        color: Color(0xFF283E50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(15),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          int? result = await showDialog<int>(
                            context: context,
                            builder: (BuildContext context) {
                              return CustomAlertDialog(
                                book: widget.book,
                                totalPage: widget.book.totalPage,
                                currentPage: widget.book.currentPage,
                              );
                            },
                          );

                          if (result != null) {
                            // Do something with the selected number
                            print('Selected Number: $result');
                          }
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                        child: Text(
                      widget.book.currentPage.toString() +
                          '/' +
                          totalPages.toString(),
                      style: TextStyle(
                          color: Color(0xff686868),
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    )),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 30.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 30.0),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(30.0),
                                        child: Image.network(
                                          widget.book.imageLink,
                                          height: 200,
                                          width: 150,
                                          loadingBuilder: (BuildContext context,
                                              Widget child,
                                              ImageChunkEvent?
                                                  loadingProgress) {
                                            if (loadingProgress == null) {
                                              // Image is fully loaded, display the actual image
                                              return child;
                                            } else {
                                              // Image is still loading, display a placeholder or loading indicator
                                              return Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          (loadingProgress
                                                                  .expectedTotalBytes ??
                                                              1)
                                                      : null,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),

                                      // Container(
                                      //   height: 40,
                                      //   width: 100,
                                      //   child: ElevatedButton(
                                      //     onPressed: _startPauseTimer,
                                      //     style: ElevatedButton.styleFrom(
                                      //       primary: Color(0xff283E50), // Set your desired button color
                                      //       shape: RoundedRectangleBorder(
                                      //         borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
                                      //       ),
                                      //     ),
                                      //     child: Padding(
                                      //       padding: const EdgeInsets.all(10.0), // Adjust the padding as needed
                                      //       child:Text(
                                      //         _isRunning ? 'Pause' : 'Start',
                                      //         style: TextStyle(fontSize: 16.0),
                                      //       ),
                                      //     ),
                                      //   ),
                                      // )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  children: [
                                    GestureDetector(
                                        onTap: ()async {
                                          int? result = await showDialog<int>(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return
                                              CustomAlertForStartDateDialog(
                                                book: widget.book,
                                                year: year,
                                                days: days,
                                                month: month,
                                              );
                                            },
                                          );

                                          if (result != null) {
                                            // Do something with the selected number
                                            print('Selected Number: $result');
                                          }
                                        },


                                        child: Text(
                                          "Started",
                                          style: TextStyle(
                                              color: Color(0xff686868)),
                                        )),
                                    Text(
                                      widget.book.startingDate==null?'-':widget.book.startingDate,
                                      style:
                                          TextStyle(color: Color(0xff686868),fontSize: 12),
                                    ),
                                  ],
                                ),
                                Container(
                                    width: 120,
                                    child: Text(
                                      widget.book.author,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                      color: Color(0xff686868),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                    )),
                                Text(
                                  widget.book.status == 'CURRENTLY READING'
                                      ? 'Reading'
                                      : widget.book.status == 'TO BE READ'
                                          ? 'Pending'
                                          : 'Finished',
                                  style: TextStyle(color: Color(0xff686868),fontSize: 12),
                                ),
                              ],
                            ),
                            Divider(
                              color: Color(0xffFEEAD4),
                              thickness: 1,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                      onTap: () {
                                        _showAddNotesDialog(widget.book);
                                      },
                                      child: Text(
                                        "Notes",
                                        style: TextStyle(
                                            color: Color(0xff283E50),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      )),
                                  GestureDetector(
                                      onTap: () {
                                        _showAddQuotesDialog(widget.book);
                                      },
                                      child: Text(
                                        "Quotes",
                                        style: TextStyle(
                                            color: Color(0xff283E50),
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      )),
                                  Text(
                                    'Page',
                                    style: TextStyle(
                                        color: Color(0xff283E50),
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: Color(0xffFEEAD4),
                              thickness: 1,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Countdown(
                                        controller: _controller,
                                        seconds: finalTime,
                                        build: (_, double time) {
                                          currentTime = time.toInt();
                                          return Text(
                                            formatTime(time.toInt()),
                                            style: TextStyle(
                                              fontSize: 30,
                                              color: Color(0xff686868),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                        interval: Duration(milliseconds: 100),
                                        onFinished: () {
                                          print('Countdown finished!');
                                          try {
                                            // Your existing code here
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('Timer is done!'),
                                              ),
                                            );
                                            updateStrikeInFirestore();
                                            _storeCurrentTimeOnFinished();
                                            _controller.pause();
                                            setState(() {
                                              // _isRunning = false;
                                            });
                                          } catch (e) {
                                            print(
                                                'Error in onFinished callback: $e');
                                            log('Error in onFinished callback: $e');
                                          }
                                        },
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "Daily Goal",
                                        style: TextStyle(
                                          color: Color(0xff283E50),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        _formatDuration(_stopwatch.elapsed),
                                        style: TextStyle(
                                            color: Color(0xff686868),
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Text(
                                        "Total Time",
                                        style: TextStyle(
                                            color: Color(0xff283E50),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _startPauseTimer,
                                style: ElevatedButton.styleFrom(
                                  primary: Color(0xff283E50),
                                  // Set your desired button color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        15.0), // Adjust the radius as needed
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  // Adjust the padding as needed
                                  child: Text(
                                    _isRunning ? 'Pause' : 'Start',
                                    style: TextStyle(fontSize: 16.0),
                                  ),
                                ),
                              ),
                            ),
                            Divider(
                              color: Color(0xffFEEAD4),
                              thickness: 1,
                            ),
                            Text(
                              "Notes",
                              style: const TextStyle(
                                  color: Color(0xFF283E50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Container(
                              // height: 250,
                              width: MediaQuery.of(context).size.width,
                              // padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    // crossAxisAlignment: CrossAxisAlignment.start,
                                    children: widget.book.notes.map((note) {
                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        color:
                                            Color(0xFFFEEAD4).withOpacity(0.9),
                                        child: Padding(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    flex: 5,
                                                    child: Text(
                                                      note['note'],
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xff686868),
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 20),
                                                      child: Text(
                                                        'Page -' +
                                                            note['pageNumber'],
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: Color(
                                                                0xff686868),
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  // Padding(
                                  //   padding:
                                  //       const EdgeInsets.only(top: 5.0),
                                  //   child: Text(
                                  //     myBooks[index].description,
                                  //     textAlign: TextAlign.center,
                                  //     maxLines: 12, // Adjust the number of lines as needed
                                  //     overflow: TextOverflow.ellipsis,
                                  //     style: const TextStyle(
                                  //       color: Color(0xFF686868),
                                  //       fontSize: 12,
                                  //       fontWeight: FontWeight.w500,
                                  //     ),
                                  //   )
                                  //
                                  // ),
                                ],
                              ),
                            ),
                            Divider(
                              color: Color(0xffFEEAD4),
                              thickness: 1,
                            ),
                            Text(
                              "Quotes",
                              style: const TextStyle(
                                  color: Color(0xFF283E50),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Container(
                              // height: 250,
                              width: MediaQuery.of(context).size.width,

                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    // crossAxisAlignment: CrossAxisAlignment.start,
                                    children: widget.book.quotes.map((quotes) {
                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        color: const Color(0xFFFEEAD4)
                                            .withOpacity(0.9),
                                        child: Padding(
                                          padding:
                                              EdgeInsets.symmetric(vertical: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    flex: 5,
                                                    child: Text(
                                                      quotes['quote'],
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xff686868),
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 20),
                                                      child: Text(
                                                        'Page -' +
                                                            quotes[
                                                                'pageNumber'],
                                                        style: TextStyle(
                                                            fontSize: 10,
                                                            color: Color(
                                                                0xff686868),
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),



                                  // Padding(
                                  //   padding:
                                  //       const EdgeInsets.only(top: 5.0),
                                  //   child: Text(
                                  //     myBooks[index].description,
                                  //     textAlign: TextAlign.center,
                                  //     maxLines: 12, // Adjust the number of lines as needed
                                  //     overflow: TextOverflow.ellipsis,
                                  //     style: const TextStyle(
                                  //       color: Color(0xFF686868),
                                  //       fontSize: 12,
                                  //       fontWeight: FontWeight.w500,
                                  //     ),
                                  //   )
                                  //
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        extendBody: true,
      ),
    );
  }

  void _showDoneDialog(DetailBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
          ),
          title: Text('Done Reading?'),
          content: Container(
            height: 50,
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.book.totalPage,
                        itemBuilder: (BuildContext context, int index) {
                          int number = index + 1;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedNumber = number;
                              });
                            },
                            child: Container(
                              width: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: number == selectedNumber
                                      ? Colors.blue
                                      : Colors.transparent,
                                  width: 2.0,
                                ),
                              ),
                              child: Text(
                                '$number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int? _additionalTimer;

  void _startAdditionalTimer() {}

  void _pauseAdditionalTimer() {
    setState(() {});
  }

  void _showPersistentMusicBottomSheet(BuildContext context) {
    double sheetTopPosition = 0.3; // Initial position (30% from the top)

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            // Update the sheet position based on the drag gestures
            double delta =
                details.primaryDelta! / MediaQuery.of(context).size.height;
            sheetTopPosition = (sheetTopPosition - delta).clamp(0.1, 0.8);
          },
          child: DraggableScrollableSheet(
            initialChildSize: sheetTopPosition,
            minChildSize: 0.1,
            maxChildSize: 0.8,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.asset('assets/logo.png', height: 50),
                      title: Text('Now Playing'),
                      trailing: IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () {
                          // Handle play button action
                        },
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: musicUrls.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(musicUrls[index].title),
                                GestureDetector(
                                    onTap: () {
                                      playMusic(musicUrls[index].path);
                                    },
                                    child: Icon(Icons.play_arrow))
                              ],
                            ),
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showInvitationCodePopupToEnterCurrentPage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Color(0xffD9D9D9),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Which page currently are you in?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF283E50),
                  ),
                ),
                Divider(
                  color: Color(0xFF283E50),
                  thickness: 1,
                ),
                SizedBox(height: 16.0),
                Container(
                  height: 50,
                  padding: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50.0),
                    color: Colors.grey[200], // Change the color as needed
                  ),
                  child: TextField(
                    controller: _currentPage,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter the current page number',
                      prefixIcon: Icon(Icons.pages),
                      border: InputBorder.none, // Remove the default border
                    ),
                    // onChanged: _onSearchChanged,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (int.parse(_currentPage.text) > widget.book.totalPage) {
                      _currentPage.clear();
                      Fluttertoast.showToast(
                          msg:
                              "The number is greater than the total page of the book!");
                    } else {
                      updatePageNumber(
                          widget.book, int.parse(_currentPage.text));
                      _currentPage.clear();
                    }

                    Navigator.pop(context);
                  },
                  child: Container(
                      width: 120,
                      child: Center(
                          child: Text(
                        "Update",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ))),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Color(0xFF283E50)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void updatePageNumber(DetailBook book, int newPageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        // Reference to the 'myBooks' collection with the UID as the document ID
        CollectionReference myBooksRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books');

        // Update the page number in the Firestore document
        await myBooksRef
            .doc(book.documentId)
            .update({'currentPage': newPageNumber});

        // Update the local state with the new page number
        setState(() {
          book.currentPage = newPageNumber;
        });

        print('Page number updated successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error updating page number: $e');
    }
  }

  Future<void> updateStrikeInFirestore() async {
    try {
      // Get the current user
      User? user = FirebaseAuth.instance.currentUser;

      // Check if the user is authenticated
      if (user != null) {
        String uid = user.uid;

        // Get the current user document from Firestore
        DocumentSnapshot<Map<String, dynamic>> userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        // Check if 'lastStrikeTimestamp' field exists
        if (userDoc.data()?.containsKey('lastStrikeTimestamp') ?? false) {
          // Get the 'lastStrikeTimestamp' field
          DateTime lastStrikeTimestamp =
              (userDoc.get('lastStrikeTimestamp') as Timestamp).toDate();
          if (DateTime.now().difference(lastStrikeTimestamp).inHours >= 12) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'lastStrikeTimestamp': FieldValue.serverTimestamp()});

            int currentStrikes = userDoc.data()?.containsKey('strikes') ?? false
                ? userDoc.get('strikes')
                : 0;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .update({'strikes': currentStrikes + 1});
          } else {
            print('Cannot add a new strike within 24 hours.');
          }
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'lastStrikeTimestamp': FieldValue.serverTimestamp()});

          // Increment the strikes count
          int currentStrikes = userDoc.data()?.containsKey('strikes') ?? false
              ? userDoc.get('strikes')
              : 0;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .update({'strikes': currentStrikes + 1});
        }
      }
    } catch (e) {
      print('Error updating strike in Firestore: $e');
    }
  }

  void _handleTimerButtonPressed() {
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  // void _handleTimerButtonPressed() {
  //   setState(() {
  //     if (_isRunning) {
  //       _controller.pause();
  //       currentTime = int.parse(_controller.getTime().toString());
  //       _storeCurrentTime();
  //     } else {
  //       // Only start the timer if it's not already running
  //       if (!_controller.isStarted) {
  //         _controller.start();
  //       }
  //     }
  //     _isRunning = !_isRunning;
  //   });
  // }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _storeCurrentTime() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    // Get the current elapsed time in minutes and seconds
    int elapsedMinutes = _stopwatch.elapsed.inMinutes;
    int elapsedSeconds = _stopwatch.elapsed.inSeconds % 60;

    try {
      // Retrieve the stored time from Firestore
      DocumentSnapshot<Map<String, dynamic>> userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        // Get the stored time values
        int storedMinutes = userDoc.get('totalTimeMin') ?? 0;
        int storedSeconds = userDoc.get('totalTimeSec') ?? 0;

        // Calculate the difference between the current time and stored time
        int updatedMinutes = storedMinutes + elapsedMinutes;
        int updatedSeconds = storedSeconds + elapsedSeconds;

        // Update the Firestore document with the new values
        await _firestore
            .collection('users')
            .doc(_auth.currentUser?.uid)
            .update({
          'currentTime': currentTime,
          'totalTimeMin': updatedMinutes,
          'totalTimeSec': updatedSeconds,
        });

        print('Data updated for user with ID: ${_auth.currentUser?.uid}');
      }
    } catch (error) {
      print(
          'Error updating data for user with ID: ${_auth.currentUser?.uid} - $error');
    }
  }

  Future<void> _storeCurrentTimeOnFinished() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .update({'currentTime': 0});
      print('Strikes increased for user with ID: ${_auth.currentUser?.uid}');
    } catch (error) {
      print(
          'Error increasing strikes for user with ID: ${_auth.currentUser?.uid} - $error');
      // Handle the error (e.g., show an error message)
    }
  }

  void addNote(DetailBook book, String newNote, String pageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'notes': FieldValue.arrayUnion([
            {'note': newNote, 'pageNumber': pageNumber}
          ]),
        });

        // Update the local state with the new notes
        setState(() {
          book.notes.add({'note': newNote, 'pageNumber': pageNumber});
        });

        print('Note added successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  void addQuote(DetailBook book, String newQuote, String pageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'quotes': FieldValue.arrayUnion([
            {'quote': newQuote, 'pageNumber': pageNumber}
          ]),
        });

        // Update the local state with the new notes
        setState(() {
          book.quotes.add({'quote': newQuote, 'pageNumber': pageNumber});
        });

        print('Quotes added successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding note: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    // log(twoDigitMinutes.toString()+twoDigitSeconds);
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  int finalTime = 0;

  Future<void> _retrieveStoredTime() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();

      if (userDoc.exists) {
        int storedTime = userDoc.get('currentTime') ?? 0;
        String storedTime2 = userDoc.get('dailyGoal') ?? 0;
        setState(() {
          // _duration = storedTime;
          currentTime = storedTime;
          _duration = int.parse(storedTime2);
          finalTime = currentTime == 0 ? _duration * 60 : currentTime;
        });
        // if (_duration > 0) {
        //   _controller.resume();
        // }
      }
    } catch (error) {
      print('Error retrieving stored time: $error');
    }
  }

  void _showAddNotesDialog(DetailBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController notesController = TextEditingController();
        TextEditingController pageNumberController = TextEditingController();

        return AlertDialog(
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
          ),
          title: Text('Notes'),
          content: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextField(
                      controller: notesController,
                      onChanged: (value) {},
                      cursorColor: Color(0xFFD9D9D9),
                      decoration: InputDecoration(
                        hintText: 'Write your note',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF283E50),
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            String newNote = notesController.text.trim();
                            if (newNote.isNotEmpty) {
                              addNote(book, newNote, pageNumberController.text);
                              notesController.clear();
                              Fluttertoast.showToast(
                                msg: "Note added successfully!",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Color(0xFF283E50),
                                textColor: Colors.white,
                              );
                              Navigator.pop(context);
                            }
                          });
                        },
                        child: Text(
                          'Done',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextField(
                        controller: pageNumberController,
                        onChanged: (value) {},
                        cursorColor: Color(0xFFD9D9D9),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddQuotesDialog(DetailBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController quotesController = TextEditingController();
        TextEditingController pageNumberController = TextEditingController();

        return AlertDialog(
          backgroundColor: Color(0xffFEEAD4),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20.0), // Adjust the radius as needed
          ),
          title: Text('Quotes'),
          content: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextField(
                      controller: quotesController,
                      onChanged: (value) {},
                      cursorColor: Color(0xFFD9D9D9),
                      decoration: InputDecoration(
                        hintText: 'Write your Quote',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        String newQuote = quotesController.text.trim();
                        if (newQuote.isNotEmpty) {
                          addQuote(book, newQuote, pageNumberController.text);
                          quotesController.clear();
                          Fluttertoast.showToast(
                            msg: "Quote added successfully!",
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor: Color(0xFF283E50),
                            textColor: Colors.white,
                          );
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextField(
                        controller: pageNumberController,
                        onChanged: (value) {},
                        cursorColor: Color(0xFFD9D9D9),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CustomAlertDialog extends StatefulWidget {
  DetailBook book;
  final int totalPage;
  final int currentPage;

  CustomAlertDialog(
      {required this.book, required this.totalPage, required this.currentPage});

  @override
  _CustomAlertDialogState createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> {
  int selectedNumber = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    selectedNumber = widget.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          Text(
            'Done Reading?',
            style: TextStyle(color: Color(0xff283E50)),
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),
          Text(
            'Update your Progress',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff686868),
            ),
          ),
        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: BoxDecoration(

          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.totalPage,
                itemBuilder: (BuildContext context, int index) {
                  int number = index + 1;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedNumber = number;
                      });
                    },
                    child: Container(
                      width: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: number == selectedNumber
                            ? Color(0xffD9D9D9)
                            : Colors.transparent,
                        border: Border.all(
                          color: number == selectedNumber
                              ? Color(0xffD9D9D9)
                              : Colors.transparent,
                          width: 2.0,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  // Add your action widgets here
                  child: TextButton(
                    onPressed: () {
                      updateStatusOfBook('COMPLETED');
                      addFinishedDate(widget.book.documentId);
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ReviewPage(
                                    book: widget.book,
                                  )));
                      // Navigator.pop(context);
                    },
                    child: Text(
                      'Finish',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 100,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Color(0xFF283E50),
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      updatePageNumber(widget.book, selectedNumber);
                      Navigator.pop(context);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> addFinishedDate(String docId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Sample user data (customize based on your requirements)
        Map<String, dynamic> contactFormData = {
          "finishedDate": DateTime.now(),
        };

        DocumentReference contactFormRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books')
            .doc(docId);

        await contactFormRef.set(contactFormData, SetOptions(merge: true));

        print('Starting date added successfully!');
      }
    } catch (e) {
      print('Error adding starting date: $e');
    }
  }
  void updateStatusOfBook(String status) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

// Reference to the 'myBooks' collection with the UID as the document ID
    CollectionReference myBooksRef = FirebaseFirestore.instance
        .collection('myBooks')
        .doc(uid)
        .collection('books');

// Specify the ID of the book you want to update
    String bookIdToUpdate =
        widget.book.documentId; // Replace with the actual ID

// Fetch the specific book document
    DocumentSnapshot bookSnapshot = await myBooksRef.doc(bookIdToUpdate).get();

    if (bookSnapshot.exists) {
      // Access the document data
      Map<String, dynamic> bookData =
          bookSnapshot.data() as Map<String, dynamic>;

      // Print the current status for reference
      print('Current Status: ${bookData['status']}');

      // Update the status to 'CURRENTLY READING'
      await myBooksRef.doc(bookIdToUpdate).update({'status': status});

      print('Status updated successfully');
    } else {
      // Handle the case where the specified book does not exist
      print('Book with ID $bookIdToUpdate does not exist.');
    }
  }

  void updatePageNumber(DetailBook book, int newPageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books');

        // Update the page number in the Firestore document
        await myBooksRef
            .doc(book.documentId)
            .update({'currentPage': newPageNumber});

        // Update the local state with the new page number
        setState(() {
          book.currentPage = newPageNumber;
        });

        print('Page number updated successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error updating page number: $e');
    }
  }
}

class CustomAlertForStartDateDialog extends StatefulWidget {
  DetailBook book;
  List<int> year;
  List<int> days;
  List<String> month;

  CustomAlertForStartDateDialog(
      {required this.book,
      required this.year,
      required this.days,
      required this.month});

  @override
  _CustomAlertForStartDateDialogState createState() =>
      _CustomAlertForStartDateDialogState();
}

class _CustomAlertForStartDateDialogState
    extends State<CustomAlertForStartDateDialog> {
  int selectedYear = 0;
  int selectedDays = 0;
  String selectedMonth = '';
  String startingDate = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xffFEEAD4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Column(
        children: [
          Text(
            'Started Date',
            style: TextStyle(color: Color(0xff283E50)),
          ),
          Divider(
            color: Colors.grey,
            thickness: 1,
          ),

        ],
      ),
      content: Container(
        height: 50,
        width: 100,
        decoration: BoxDecoration(
          color: Color(0xffFEEAD4),
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 50,

                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.year.length,
                    itemBuilder: (BuildContext context, int index) {
                      int number = widget.year[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedYear = number;
                          });
                        },
                        child: Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: number == selectedYear
                                ? Color(0xffD9D9D9)
                                : Colors.transparent,
                            border: Border.all(
                              color: number == selectedYear
                                  ? Color(0xffD9D9D9)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff686868),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.month.length,
                    itemBuilder: (BuildContext context, int index) {
                      String number = widget.month[index];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedMonth = number;
                          });
                        },
                        child: Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: number == selectedMonth
                                ? Color(0xffD9D9D9)
                                : Colors.transparent,
                            border: Border.all(
                              color: number == selectedMonth
                                  ? Color(0xffD9D9D9)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff686868),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: widget.days.length,
                    itemBuilder: (BuildContext context, int index) {
                      int number = index + 1;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            selectedDays = number;
                          });
                        },
                        child: Container(
                          width: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: number == selectedDays
                                ? Color(0xffD9D9D9)
                                : Colors.transparent,
                            border: Border.all(
                              color: number == selectedDays
                                  ? Color(0xffD9D9D9)
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff686868),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 115,
              height: 45,
              decoration: BoxDecoration(
                color: Color(0xFF283E50),
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    startingDate = selectedYear.toString()+'/'+selectedMonth.toString()+'/'+selectedDays.toString();
                    log(startingDate);
                  });
                  addStartingDate(widget.book.documentId);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text(
                  'Update',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Future<void> addStartingDate(String docId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // Sample user data (customize based on your requirements)
        Map<String, dynamic> contactFormData = {
          "startingDate": startingDate,
        };

        DocumentReference contactFormRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books')
            .doc(docId);

        await contactFormRef.set(contactFormData, SetOptions(merge: true));

        print('Starting date added successfully!');
      }
    } catch (e) {
      print('Error adding starting date: $e');
    }
  }



  void updateStatusOfBook(String status) async {
    FirebaseAuth auth = FirebaseAuth.instance;
    String uid = auth.currentUser!.uid;

// Reference to the 'myBooks' collection with the UID as the document ID
    CollectionReference myBooksRef = FirebaseFirestore.instance
        .collection('myBooks')
        .doc(uid)
        .collection('books');

// Specify the ID of the book you want to update
    String bookIdToUpdate =
        widget.book.documentId; // Replace with the actual ID

// Fetch the specific book document
    DocumentSnapshot bookSnapshot = await myBooksRef.doc(bookIdToUpdate).get();

    if (bookSnapshot.exists) {
      // Access the document data
      Map<String, dynamic> bookData =
          bookSnapshot.data() as Map<String, dynamic>;

      // Print the current status for reference
      print('Current Status: ${bookData['status']}');

      // Update the status to 'CURRENTLY READING'
      await myBooksRef.doc(bookIdToUpdate).update({'status': status});

      print('Status updated successfully');
    } else {
      // Handle the case where the specified book does not exist
      print('Book with ID $bookIdToUpdate does not exist.');
    }
  }

  void updatePageNumber(DetailBook book, int newPageNumber) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef = FirebaseFirestore.instance
            .collection('myBooks')
            .doc(uid)
            .collection('books');

        // Update the page number in the Firestore document
        await myBooksRef
            .doc(book.documentId)
            .update({'currentPage': newPageNumber});

        // Update the local state with the new page number
        setState(() {
          book.currentPage = newPageNumber;
        });

        print('Page number updated successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error updating page number: $e');
    }
  }

}
