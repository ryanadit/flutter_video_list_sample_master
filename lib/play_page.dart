import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

class PlayPage extends StatefulWidget {
  PlayPage({Key key}) : super(key: key);

  @override
  _PlayPageState createState() => _PlayPageState();
}

class Clip {
  final String fileName;
  final String title;
  final int runningTime;
  Clip(this.fileName, this.title, this.runningTime);

  String videoPath() {
    return "embed/$fileName.mp4";
  }

  String thumbPath() {
    return "embed/$fileName.png";
  }
}

class _PlayPageState extends State<PlayPage> {
  VideoPlayerController _controller;

  // List<Clip> _clips = [
  //   new Clip("small", "small", 6),
  //   // new Clip("earth", "earth", 13),
  //   // new Clip("giraffe", "giraffe", 18),
  //   // new Clip("particle", "particle", 11),
  //   // new Clip("summer", "summer", 8)
  // ];

  //var _playingIndex = -1;
  var _disposed = false;
  var _isFullScreen = false;
  var _isEndOfClip = false;
  var _progress = 0.0;
  //var _showingDialog = false;
  Timer _timerVisibleControl;
  double _controlAlpha = 1.0;

  var _playing = false;
  bool get _isPlaying {
    return _playing;
  }

  set _isPlaying(bool value) {
    _playing = value;
    _timerVisibleControl?.cancel();
    if (value) {
      _timerVisibleControl = Timer(Duration(seconds: 2), () {
        setState(() {
          _controlAlpha = 0.0;
        });
      });
    } else {
      _timerVisibleControl = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _controlAlpha = 1.0;
        });
      });
    }
  }

  void _onTapVideo() {
    debugPrint("_onTapVideo $_controlAlpha");
    setState(() {
      _controlAlpha = _controlAlpha > 0 ? 0 : 1;
    });
    _timerVisibleControl?.cancel();
    _timerVisibleControl = Timer(Duration(seconds: 2), () {
      if (_isPlaying) {
        setState(() {
          _controlAlpha = 0.0;
        });
      }
    });
  }

  @override
  void initState() {
    Screen.keepOn(true);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    _initializeAndPlay();
    super.initState();
  }

  @override
  void dispose() {
    _disposed = true;
    _timerVisibleControl?.cancel();
    Screen.keepOn(false);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    _exitFullScreen();
    _controller?.pause(); // mute instantly
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _toggleFullscreen() async {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _enterFullScreen() async {
    debugPrint("enterFullScreen");
    await SystemChrome.setEnabledSystemUIOverlays([]);
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    if (_disposed) return;
    setState(() {
      _isFullScreen = true;
    });
  }

  void _exitFullScreen() async {
    debugPrint("exitFullScreen");
    await SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (_disposed) return;
    setState(() {
      _isFullScreen = false;
    });
  }

  void _initializeAndPlay() async {
    print("_initializeAndPlay --------->");
    //final clip = _clips[index];
    //final controller = VideoPlayerController.asset(clip.videoPath());
    final controller = VideoPlayerController.network('https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4');
    //final old = _controller;
    _controller = controller;
    //print(old);
    // if (old != null) {
    //   debugPrint('sini');
    //   old.removeListener(_onControllerUpdated);
    //   await old.pause();
    // }
    setState(() {
      debugPrint("---- controller changed");
    });

    controller
      ..initialize().then((_) {
        debugPrint("---- controller initialized");
        //old?.dispose();
        //_playingIndex = index;
        controller.addListener(_onControllerUpdated);
        controller.play();
        setState(() {});
      });
  }

  var _updateProgressInterval = 0.0;

  Future<void> _onControllerUpdated() async {
    if (_disposed) return;
    final controller = _controller;
    if (controller == null) return;
    if (!controller.value.initialized) return;
    final position = await controller.position;
    final duration = controller.value.duration;
    if (position == null || duration == null) return;

    final playing = controller.value.isPlaying;
    final isEndOfClip =
        position.inMilliseconds > 0 && position.inSeconds == duration.inSeconds;

    // blocking too many updation
    final interval = position.inMilliseconds / 250.0;
    if (playing && _updateProgressInterval != interval) {
      // handle progress indicator
      _updateProgressInterval = interval;
      if (_disposed) return;
      setState(() {
        _progress = position.inMilliseconds.ceilToDouble() /
            duration.inMilliseconds.ceilToDouble();
      });
    }

    // handle clip end
    if (_isPlaying != playing || _isEndOfClip != isEndOfClip) {
      _isPlaying = playing;
      _isEndOfClip = isEndOfClip;
      debugPrint(
          "updated -----> isPlaying=$playing / isEndPlaying=$isEndOfClip");
      if (isEndOfClip && !playing) {
        _controller.pause();
        debugPrint(
            "========================== End of Clip / Handle NEXT ========================== ");
        //final isComplete = _playingIndex == _clips.length - 1;
        // if (isComplete) {
        //   print("played all!!");
        //   if (!_showingDialog) {
        //     _showingDialog = true;
        //     _showPlayedAllDialog().then((value) {
        //       _exitFullScreen();
        //       _showingDialog = false;
        //     });
        //   }
        // } else {
        //   _initializeAndPlay(_playingIndex);
        // }
      }
    }
  }

  // Future<bool> _showPlayedAllDialog() async {
  //   return showDialog<bool>(
  //       context: context,
  //       barrierDismissible: true,
  //       builder: (BuildContext context) {
  //         return AlertDialog(
  //           content: SingleChildScrollView(child: Text("Player")),
  //           actions: <Widget>[
  //             FlatButton(
  //               child: Text("Play"),
  //               onPressed: () => Navigator.pop(context, true),
  //             )
  //           ],
  //         );
  //       });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isFullScreen
          ? null
          : AppBar(
              title: Text("Play View"),
            ),
      body: _isFullScreen
          ? Container(
              child: Center(child: _playView(context)),
              decoration: BoxDecoration(color: Colors.black),
            )
          : Column(children: <Widget>[
              Container(
                child: Center(child: _playView(context)),
                decoration: BoxDecoration(color: Colors.black),
              ),
              // Expanded(
              //   child: _listView(),
              // ),
            ]),
    );
  }

  // void _onTapCard() {
  //   _initializeAndPlay();
  // }


  static showProgressDialog(BuildContext context, String title) {
    try {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              content: Flex(
                direction: Axis.horizontal,
                children: <Widget>[
                  CircularProgressIndicator(),
                  Padding(padding: EdgeInsets.only(left: 15),),
                  Flexible(
                      flex: 8,
                      child: Text(
                        title,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )),
                ],
              ),
            );
          });
    } catch (e) {
      print(e.toString());
    }
  }

  Widget _playView(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.initialized) {
      return AspectRatio(
        //aspectRatio: controller.value.aspectRatio,
        aspectRatio: 16.0 / 9.0,
        child: Stack(
          children: <Widget>[
            GestureDetector(
              child: VideoPlayer(controller),
              onTap: _onTapVideo,
            ),
            _controlAlpha > 0
                ? AnimatedOpacity(
                    opacity: _controlAlpha,
                    duration: Duration(milliseconds: 250),
                    child: _controlView(context),
                  )
                : Container(),
          ],
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16.0 / 9.0,
        child: Center(
            child: CircularProgressIndicator()
        //     Text(
        //   "Loading...",
        //   style: TextStyle(
        //       color: Colors.white70,
        //       fontWeight: FontWeight.bold,
        //       fontSize: 18.0),
        // )
        ),
      );
    }
  }

  // Widget _listView() {
  //   return ListView.builder(
  //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //     itemCount: _clips.length,
  //     itemBuilder: (BuildContext context, int index) {
  //       return InkWell(
  //         borderRadius: BorderRadius.all(Radius.circular(6)),
  //         splashColor: Colors.blue[100],
  //         onTap: () {
  //           _onTapCard();
  //         },
  //         child: _buildCard(index),
  //       );
  //     },
  //   ).build(context);
  // }

  Widget _controlView(BuildContext context) {
    return Column(
      children: <Widget>[
        //_topUI(),
        Expanded(
          child: _centerUI(),
        ),
        _bottomUI()
      ],
    );
  }

  Widget _centerUI() {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // FlatButton(
        //   onPressed: () async {
        //     final index = _playingIndex - 1;
        //     if (index > 0 && _clips.length > 0) {
        //       _initializeAndPlay(index);
        //     }
        //   },
        //   child: Icon(
        //     Icons.fast_rewind,
        //     size: 36.0,
        //     color: Colors.white,
        //   ),
        // ),
        FlatButton(
          onPressed: () async {
            if (_isPlaying) {
              _controller?.pause();
              _isPlaying = false;
            } else {
              print('object');
              final controller = _controller;
              if (controller != null) {
                final position = await controller.position;
                final isEnd =
                    controller.value.duration.inSeconds == position.inSeconds;
                if (isEnd) {
                  print(isEnd);
                  _initializeAndPlay();
                  //controller.play();
                } else {
                  controller.play();
                }
              }
            }
            setState(() {});
          },
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 56.0,
            color: Colors.white,
          ),
        ),
        // FlatButton(
        //   onPressed: () async {
        //     final index = _playingIndex + 1;
        //     if (index < _clips.length - 1) {
        //       _initializeAndPlay(index);
        //     }
        //   },
        //   child: Icon(
        //     Icons.fast_forward,
        //     size: 36.0,
        //     color: Colors.white,
        //   ),
        // ),
      ],
    ));
  }

  String convertTwo(int value) {
    return value < 10 ? "0$value" : "$value";
  }

  // Widget _topUI() {
  //   final noMute = (_controller?.value?.volume ?? 0) > 0;
  //   final duration =
  //       _controller == null ? 0 : _controller.value.duration.inSeconds;
  //   final head = _controller == null ? 0 : _controller.value.position.inSeconds;
  //   final remained = max(0, duration - head);
  //   final min = convertTwo(remained ~/ 60.0);
  //   final sec = convertTwo(remained % 60);
  //   return Row(
  //     children: <Widget>[
  //       InkWell(
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //           child: Container(
  //               decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
  //                 BoxShadow(
  //                     offset: const Offset(0.0, 0.0),
  //                     blurRadius: 4.0,
  //                     color: Color.fromARGB(50, 0, 0, 0)),
  //               ]),
  //               child: Icon(
  //                 noMute ? Icons.volume_up : Icons.volume_off,
  //                 color: Colors.white,
  //               )),
  //         ),
  //         onTap: () {
  //           if (noMute) {
  //             _controller?.setVolume(0);
  //           } else {
  //             _controller?.setVolume(1.0);
  //           }
  //           setState(() {});
  //         },
  //       ),
  //       Expanded(
  //         child: Container(),
  //       ),
  //       Text(
  //         "$min:$sec",
  //         style: TextStyle(
  //           color: Colors.white,
  //           shadows: <Shadow>[
  //             Shadow(
  //               offset: Offset(0.0, 1.0),
  //               blurRadius: 4.0,
  //               color: Color.fromARGB(150, 0, 0, 0),
  //             ),
  //           ],
  //         ),
  //       ),
  //       SizedBox(width: 10)
  //     ],
  //   );
  // }

  Widget _bottomUI() {
    final noMute = (_controller?.value?.volume ?? 0) > 0;
    // final duration =
    //     _controller == null ? 0 : _controller.value.duration.inSeconds;
    final head = _controller == null ? 0 : _controller.value.position.inSeconds;
    final remained = max(head,0);
    final minute = convertTwo(remained ~/ 60.0);
    final sec = convertTwo(remained % 60);
    return Row(
      children: <Widget>[
        FlatButton(
          onPressed: () async {
            if (_isPlaying) {
              _controller?.pause();
              _isPlaying = false;
            } else {
              final controller = _controller;
              if (controller != null) {
                final position = await controller.position;
                final isEnd =
                    controller.value.duration.inSeconds == position.inSeconds;
                if (isEnd) {
                  _initializeAndPlay();
                } else {
                  controller.play();
                }
              }
            }
            setState(() {});
          },
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            size: 25.0,
            color: Colors.white,
          ),
        ),
        //SizedBox(width: 0),
        InkWell(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
                // decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                //   BoxShadow(
                //       offset: const Offset(0.0, 0.0),
                //       blurRadius: 4.0,
                //       color: Color.fromARGB(50, 0, 0, 0)),
                // ]),
                child: Icon(
                  noMute ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 25.0,
                )),
          ),
          onTap: () {
            if (noMute) {
              _controller?.setVolume(0);
            } else {
              _controller?.setVolume(1.0);
            }
            setState(() {});
          },
        ),
        Text(
          "$minute:$sec",
          style: TextStyle(
            color: Colors.white,
            shadows: <Shadow>[
              Shadow(
                offset: Offset(0.0, 1.0),
                blurRadius: 4.0,
                color: Color.fromARGB(150, 0, 0, 0),
              ),
            ],
          ),
        ),
        Expanded(
          child: Slider(
            value: max(0, min(_progress * 100, 100)),
            min: 0,
            max: 100,
            onChanged: (value) {
              setState(() {
                _progress = value * 0.01;
              });
            },
            onChangeStart: (value) {
              debugPrint("-- onChangeStart $value");
              _controller?.pause();
            },
            onChangeEnd: (value) {
              debugPrint("-- onChangeEnd $value");
              final duration = _controller?.value?.duration;
              if (duration != null) {
                var newValue = max(0, min(value, 99)) * 0.01;
                var millis = (duration.inMilliseconds * newValue).toInt();
                _controller?.seekTo(Duration(milliseconds: millis));
                _controller?.play();
              }
            },
          ),
        ),
        IconButton(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.yellow,
          icon: Icon(
            Icons.fullscreen,
            color: Colors.white,
          ),
          onPressed: _toggleFullscreen,
        ),
      ],
    );
  }

//   Widget _buildCard(int index) {
//     final clip = _clips[index];
//     final playing = index == _playingIndex;
//     String runtime;
//     if (clip.runningTime > 60) {
//       runtime = "${clip.runningTime ~/ 60}menit ${clip.runningTime % 60}detik";
//     } else {
//       runtime = "${clip.runningTime % 60}detik";
//     }
//     return Card(
//       child: Container(
//         padding: EdgeInsets.all(4),
//         child: Row(
//           mainAxisSize: MainAxisSize.max,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: <Widget>[
//             Padding(
//               padding: EdgeInsets.only(right: 8),
//               child: Image.asset(
//                 clip.thumbPath(),
//                 width: 70,
//                 height: 50,
//                 fit: BoxFit.fill,
//               ),
//             ),
//             Expanded(
//               child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: <Widget>[
//                     Text(clip.title,
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.bold)),
//                     Padding(
//                       child: Text("$runtime",
//                           style: TextStyle(color: Colors.grey[500])),
//                       padding: EdgeInsets.only(top: 3),
//                     )
//                   ]),
//             ),
//             Padding(
//               padding: EdgeInsets.all(8.0),
//               child: playing
//                   ? Icon(Icons.play_arrow)
//                   : Icon(
//                       Icons.play_arrow,
//                       color: Colors.grey.shade300,
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
 }
