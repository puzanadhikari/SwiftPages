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
  final CountdownController _additionalController = CountdownController(autoStart: false);
  TextEditingController _quoteContoller = TextEditingController();
  TextEditingController _noteContoller = TextEditingController();
  int totalTimeMin=0;
  int totalTimeSec=0;
  String dailyGoal='';
   int _duration = 0;
   int currentTime=0;
  // final CountDownController _controller = CountDownController();
  late bool _isRunning;
  late bool _isPlaying;
  int totalPages = 0;
  Future<void> fetchData() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

      if (userDoc.exists) {


        setState(() {
          totalTimeMin = userDoc.get('totalTimeMin') ?? 0;
          totalTimeSec = userDoc.get('totalTimeSec') ?? 0;
        });
      }
    } catch (error) {
      log('Error fetching data: $error');
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
  String twoDigitMinutes='';
  String twoDigitSeconds='';
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
      log('Error fetching music URLs: $e');
    }

    setState(() {
      musicUrls = urls;
      log(musicUrls[0].path.toString());
    });
  }

  Future<void> playMusic(String path) async {
    if (path.isNotEmpty) {
      try {
        log("play func" + path.toString());
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
      _isPlaying=false;
    });
  }
  void _onTimerTick(Timer timer) {
    if (_stopwatch.isRunning) {
      setState(() {
        // Rebuild the widget tree to update the UI
      });
    }
  }
  late Stopwatch _stopwatch;
  // @override
  // void dispose() {
  //   _timer.cancel();
  //   super.dispose();
  // }

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
    totalPages = widget.book.totalPage==0?200:widget.book.totalPage;
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
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: -30,

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
                  "Reading",
                  style: const TextStyle(
                    fontFamily: "Abhaya Libre ExtraBold",
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xfffeead4),
                    height: 29 / 22,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 100.0),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Stack(
                      alignment: Alignment.topLeft,
                      children: [
                        // Positioned(
                        //   top: 0,
                        //   left: 30,
                        //   child: Container(
                        //     height: 250,
                        //     width: 250,
                        //     padding: const EdgeInsets.all(8),
                        //     decoration: BoxDecoration(
                        //       color: const Color(0xFFD9D9D9),
                        //       borderRadius: BorderRadius.circular(20.0),
                        //     ),
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         const SizedBox(height: 8),
                        //         Container(
                        //           height: 150,
                        //           // Set a fixed height for description
                        //           child: Column(
                        //             crossAxisAlignment: CrossAxisAlignment.start,
                        //             children: [
                        //               Padding(
                        //                 padding: const EdgeInsets.only(top: 10.0),
                        //                 child: Text(
                        //                   "Currently Reading",
                        //                   textAlign: TextAlign.center,
                        //                   style: const TextStyle(
                        //                       color: Color(0xFF283E50),
                        //                       fontWeight: FontWeight.bold,
                        //                       fontSize: 14),
                        //                 ),
                        //               ),
                        //               SingleChildScrollView(
                        //                 child: Padding(
                        //                   padding:
                        //                       const EdgeInsets.only(top: 5.0),
                        //                   child: Text(
                        //                     widget.book.author,
                        //                     textAlign: TextAlign.center,
                        //                     style: const TextStyle(
                        //                         color: Color(0xFF686868),
                        //                         fontSize: 12,
                        //                         fontWeight: FontWeight.w500),
                        //                   ),
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        // Positioned(
                        //   top: 105,
                        //   right: 10,
                        //   child: Column(
                        //     children: [
                        //       Stack(
                        //         children: [
                        //           CircularProgressIndicator(
                        //             value: calculatePercentage() / 100,
                        //             strokeWidth: 5.0,
                        //             backgroundColor: Colors.black12,
                        //             // Adjust the stroke width as needed
                        //             valueColor: AlwaysStoppedAnimation<Color>(
                        //               Color(0xFF283E50),
                        //             ), // Adjust the color as needed
                        //           ),
                        //           Positioned(
                        //             top: 10,
                        //             left: 5,
                        //             child: Text(
                        //               "${calculatePercentage().toStringAsFixed(1)}%",
                        //               style: TextStyle(
                        //                   color: Color(0xFF283E50),
                        //                   fontWeight: FontWeight.bold,
                        //                   fontSize: 11),
                        //             ),
                        //           ),
                        //         ],
                        //       ),
                        //       SizedBox(
                        //         height: 10,
                        //       ),
                        //       Text(
                        //         "Progress",
                        //         style: TextStyle(
                        //             color: Color(0xFF686868), fontSize: 14),
                        //       ),
                        //       SizedBox(
                        //         height: 20,
                        //       ),
                        //
                        //     ],
                        //   ),
                        // ),
                        Padding(
                          padding: const EdgeInsets.only(top:30.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30.0),
                                child: Image.network(
                                  widget.book.imageLink,
                                  height: 200,
                                  width: 150,
                                  loadingBuilder: (BuildContext context, Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) {
                                      // Image is fully loaded, display the actual image
                                      return child;
                                    } else {
                                      // Image is still loading, display a placeholder or loading indicator
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes !=
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
                              SizedBox(height: 10,),
                              Container(
                                height: 40,
                                width: 100,
                                child: ElevatedButton(
                                  onPressed: _startPauseTimer,
                                  style: ElevatedButton.styleFrom(
                                    primary: Color(0xff283E50), // Set your desired button color
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0), // Adjust the radius as needed
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0), // Adjust the padding as needed
                                    child: Text(
                                      _isRunning ? 'Pause' : 'Start',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                  ),
                                ),
                              )

                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.only(top:120),
                      child: Column(
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[

                          SizedBox(
                            width: 200,
                            child: Text(widget.book.author,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff686868),
                                fontWeight: FontWeight.bold
                            ),),
                          ),
                          SizedBox(height: 16,),
                          // Original Countdown Timer
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Adjust the radius as needed
                            ),
                            color: Color(0xFFFF997A),

                            child: Container(
                              width: 200,
                              height: 50,
                              child: Countdown(
                                controller: _controller,
                                seconds: _duration * 60 ,
                                build: (_, double time) {
                                  currentTime = time.toInt();
                                  return Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Daily Goal: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff283E50),
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        Text(
                                         time.floor().toString()+ ' sec',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff686868),
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                interval: Duration(milliseconds: 100),
                                onFinished: () {
                                  print('Countdown finished!');
                                  try {
                                    // Your existing code here
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Timer is done!'),
                                      ),
                                    );
                                    updateStrikeInFirestore();
                                    _storeCurrentTimeOnFinished();
                                    setState(() {
                                      _isRunning = false;
                                    });
                                  } catch (e) {
                                    print('Error in onFinished callback: $e');
                                    log('Error in onFinished callback: $e');
                                  }
                                },

                              ),
                            ),
                          ),
                          // SizedBox(height: 16),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Adjust the radius as needed
                            ),
                            color: Color(0xFFFF997A),

                            child: Container(
                              width: 200,
                              height: 50,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Total Read: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xff283E50),
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_stopwatch.elapsed),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xff686868),
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  20.0), // Adjust the radius as needed
                            ),
                            color: Color(0xFFFF997A),

                            child: Container(
                              width: 200,
                              height: 50,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Pages Read: ',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff283E50),
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      Text(
                                        widget.book.currentPage.toString()+'/'+totalPages.toString(),
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xff686868),
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.0),

                          // Container(
                          //   padding: const EdgeInsets.symmetric(horizontal: 16),
                          //   child: ElevatedButton(
                          //     child: Text(_isRunning ? 'Pause' : 'Start'),
                          //     onPressed: () {
                          //       setState(() {
                          //         _isRunning = !_isRunning;
                          //         if (_isRunning) {
                          //           _controller.start();
                          //           _additionalController.start();
                          //           _startAdditionalTimer();
                          //         } else {
                          //           _storeCurrentTime();
                          //           _controller.pause();
                          //           _additionalController.pause();
                          //           _pauseAdditionalTimer();
                          //         }
                          //       });
                          //     },
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30,),
                  Divider(
                    endIndent: 10,
                    indent: 10,
                    thickness: 1,
                    color: Color(0xff283E50)
                  ),
                  Container(
                    child: Column(
                      children: [
                        
                      ],
                    ),
                  ),
                  
                  Text("Notes",  style: const TextStyle(
                      color: Color(0xFF283E50),
                      fontWeight: FontWeight.bold,
                      fontSize: 20),),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      // height: 250,
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.book!.notes.map((note) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '-'+note,
                                  style: TextStyle(fontSize: 14, color: Color(0xFF283E50)),
                                ),
                              );
                            }).toList(),
                          ),
                          // Padding(
                          //   padding:
                          //       const EdgeInsets.only(top: 5.0),
                          //   child: Text(
                          //     widget.book.description,
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
                          SizedBox(height: 5,),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color:Colors.grey[100],
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left:8.0),
                                    child: TextField(
                                      controller: _noteContoller,
                                      onChanged: (value) {

                                      },
                                      cursorColor: Color(0xFF283E50),
                                      decoration: InputDecoration(
                                        hintText: 'Type your note...',
                                        hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,

                                      ),

                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF283E50),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),

                                      ),

                                    ),
                                    child: TextButton(
                                      onPressed: (){
                                        setState(() {
                                          String newNote = _noteContoller.text.trim();
                                          if (newNote.isNotEmpty) {
                                            addNote(widget.book, newNote);
                                            _noteContoller.clear();
                                            Fluttertoast.showToast(
                                              msg: "Note added successfully!",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              backgroundColor: Color(0xFF283E50),
                                              textColor: Colors.white,
                                            );
                                          }
                                        });
                                      },
                                      child: Text(
                                        'Post',
                                        style: TextStyle(color: Colors.white),
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
                  ),
                  Text("Quotes",  style: const TextStyle(
                      color: Color(0xFF283E50),
                      fontWeight: FontWeight.bold,
                      fontSize: 20),),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Color(0xFFD9D9D9),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: widget.book!.quotes.map((quotes) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  '-'+quotes,
                                  style: TextStyle(fontSize: 14, color: Color(0xFF283E50)),
                                ),
                              );
                            }).toList(),
                          ),
                          Container(
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
                                    padding: const EdgeInsets.only(left:8.0),
                                    child: TextField(
                                      controller: _quoteContoller,
                                      onChanged: (value) {
                                        setState(() {
                                          // comment = value;
                                        });
                                      },
                                      cursorColor: Color(0xFF283E50),
                                      decoration: InputDecoration(
                                          hintText: 'Type your quote...',
                                          hintStyle: TextStyle(color: Colors.grey),
                                        border: InputBorder.none,

                                      ),

                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF283E50),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),

                                      ),

                                    ),
                                    child: TextButton(
                                      onPressed: (){
                                        String newQuote = _quoteContoller.text.trim();
                                        if (newQuote.isNotEmpty) {
                                          addQuote(widget.book, newQuote);
                                          _quoteContoller.clear();
                                          Fluttertoast.showToast(
                                            msg: "Quote added successfully!",
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            backgroundColor: Color(0xFF283E50),
                                            textColor: Colors.white,
                                          );
                                        }
                                      },
                                      child: Text(
                                        'Post',
                                        style: TextStyle(color: Colors.white),
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
                  ),
                ],
              ),

              // Align(
              //   alignment: Alignment.topLeft,
              //   child: Padding(
              //     padding: const EdgeInsets.only(top: 10.0),
              //     child: Column(
              //       children: [
              //         Padding(
              //           padding: const EdgeInsets.all(15.0),
              //           child: CircularCountDownTimer(
              //             duration: (_duration*60),
              //             controller: _controller,
              //             width: MediaQuery.of(context).size.width / 3,
              //             height: MediaQuery.of(context).size.height / 3,
              //             ringColor: Colors.grey[300]!,
              //             fillColor: Color(0xFF283E50)!,
              //             backgroundColor: Color(0xFFFEEAD4),
              //             strokeWidth: 15.0,
              //             strokeCap: StrokeCap.round,
              //             textStyle: const TextStyle(
              //               fontSize: 33.0,
              //               color: Color(0xFF283E50),
              //               fontWeight: FontWeight.bold,
              //             ),
              //             isReverse: false,
              //             isReverseAnimation: false,
              //             isTimerTextShown: true,
              //             autoStart: false,
              //
              //             onStart: () {
              //               debugPrint('Countdown Started');
              //             },
              //             onComplete: () {
              //               log('Countdown Ended');
              //               setState(() {
              //                 _isRunning = false;
              //               });
              //               updateStrikeInFirestore();
              //               _controller.restart(duration: (_duration * 60));
              //             },
              //             onChange: (String timeStamp) {
              //               debugPrint('Countdown Changed $timeStamp');
              //              setState(() {
              //
              //              });
              //
              //             },
              //             timeFormatterFunction:
              //                 (defaultFormatterFunction, duration) {
              //               if (duration.inSeconds == 0) {
              //                 return "Start";
              //               } else {
              //                 return Function.apply(
              //                     defaultFormatterFunction, [duration]);
              //
              //               }
              //             },
              //           ),
              //         ),
              //         Text("Remaining Goal\n${(_duration*60)-currentTime} seconds"),
              //         ElevatedButton(
              //           onPressed: _handleTimerButtonPressed,
              //           child: Text(_isRunning ? 'Pause' : 'Start'),
              //           style: ElevatedButton.styleFrom(
              //             primary: Color(0xFF283E50), // Background color
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(
              //                   8), // Adjust the border radius as needed
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // DraggableScrollableSheet(
              //     initialChildSize: 0.3,
              //     minChildSize: 0.3,
              //     maxChildSize: 1,
              //     snapSizes: [0.5, 1],
              //     snap: true,
              //     builder: (BuildContext context, scrollSheetController) {
              //       return Container(
              //         decoration: BoxDecoration(
              //           color: Colors.white,
              //           borderRadius: BorderRadius.only(
              //             topLeft: Radius.circular(20.0),
              //             topRight: Radius.circular(20.0),
              //           ),
              //         ),
              //         child: Column(
              //           children: [
              //             ListTile(
              //               // leading: Image.asset('assets/logo.png', height: 50),
              //               title: Row(
              //                 children: [
              //                   Expanded(
              //                     child: Divider(
              //                       color: Color(0xFF283E50),
              //                       endIndent: 18,
              //                       thickness: 2,
              //                     ),
              //                   ),
              //                   Text(
              //                     'MUSIC',
              //                     style: TextStyle(
              //                         color: Color(0xFF283E50),
              //                         fontSize: 22,
              //                         fontWeight: FontWeight.bold),
              //                   ),
              //                   Icon(
              //                     Icons.music_note,
              //                     color: Color(0xFF283E50),
              //                   ),
              //                   Expanded(
              //                     child: Divider(
              //                       color: Color(0xFF283E50),
              //                       indent: 14,
              //                       thickness: 2,
              //                     ),
              //                   ),
              //                 ],
              //               ),
              //
              //               // trailing: IconButton(
              //               //       icon: Icon(Icons.play_arrow),
              //               //       onPressed: () {
              //               //         // Handle play button action
              //               //       },
              //               //     ),
              //             ),
              //
              //             Expanded(
              //               child: ListView.builder(
              //                 controller: scrollSheetController,
              //                 itemCount: musicUrls.length,
              //                 itemBuilder: (context, index) {
              //                   return musicUrls.isEmpty?CircularProgressIndicator():ListTile(
              //                     title: Row(
              //                       mainAxisAlignment:
              //                           MainAxisAlignment.spaceBetween,
              //                       crossAxisAlignment: CrossAxisAlignment.start,
              //                       children: [
              //                         Text(musicUrls[index].title),
              //                         GestureDetector(
              //                             onTap: () {
              //                               _isPlaying==true?pauseMusic():playMusic(musicUrls[index].path);
              //                             },
              //                             child: _isPlaying==true?Icon(Icons.pause):Icon(Icons.play_arrow))
              //                       ],
              //                     ),
              //                     onTap: () {},
              //                   );
              //                 },
              //               ),
              //             ),
              //           ],
              //         ),
              //       );
              //     }),
            ],
          ),
        ),
        extendBody: true,
      
      ),
    );
  }
  int? _additionalTimer;

  void _startAdditionalTimer() {


  }

  void _pauseAdditionalTimer() {
      setState(() {

      });
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
          // If 'lastStrikeTimestamp' field does not exist, initialize it
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
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await _firestore.collection('users').doc(_auth.currentUser?.uid).get();

      if (userDoc.exists) {
        // Get the stored time values
        int storedMinutes = userDoc.get('totalTimeMin') ?? 0;
        int storedSeconds = userDoc.get('totalTimeSec') ?? 0;

        // Calculate the difference between the current time and stored time
        int updatedMinutes = storedMinutes + elapsedMinutes;
        int updatedSeconds = storedSeconds + elapsedSeconds;

        // Update the Firestore document with the new values
        await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
          'currentTime': currentTime,
          'totalTimeMin': updatedMinutes,
          'totalTimeSec': updatedSeconds,
        });

        print('Data updated for user with ID: ${_auth.currentUser?.uid}');
      }
    } catch (error) {
      print('Error updating data for user with ID: ${_auth.currentUser?.uid} - $error');
    }
  }

  Future<void> _storeCurrentTimeOnFinished() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'currentTime':0});
      print('Strikes increased for user with ID: ${_auth.currentUser?.uid}');
    } catch (error) {
      print('Error increasing strikes for user with ID: ${_auth.currentUser?.uid} - $error');
      // Handle the error (e.g., show an error message)
    }
  }
  void addNote(DetailBook book, String newNote) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'notes': FieldValue.arrayUnion([newNote]),
        });

        // Update the local state with the new notes
        setState(() {
          book.notes.add(newNote);
        });

        print('Note added successfully!');
      } else {
        print('No user is currently signed in.');
      }
    } catch (e) {
      print('Error adding note: $e');
    }
  }
  void addQuote(DetailBook book, String newQuote) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        CollectionReference myBooksRef =
        FirebaseFirestore.instance.collection('myBooks').doc(uid).collection('books');

        // Update the notes in the Firestore document
        await myBooksRef.doc(book.documentId).update({
          'quotes': FieldValue.arrayUnion([newQuote]),
        });

        // Update the local state with the new notes
        setState(() {
          book.quotes.add(newQuote);
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

  Future<void> _retrieveStoredTime() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc =
      await FirebaseFirestore.instance
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
        });
        // if (_duration > 0) {
        //   _controller.resume();
        // }
      }
    } catch (error) {
      print('Error retrieving stored time: $error');
    }
  }
}
