// ignore_for_file: sort_child_properties_last, sized_box_for_whitespace, prefer_const_constructors, must_be_immutable, prefer_typing_uninitialized_variables

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// 5d999d1f624049f682f7436f0161c6e2
import '../config.dart';

class CallAttend extends StatefulWidget {
  var channelId;
  CallAttend({Key? key, required this.channelId}) : super(key: key);

  @override
  State<CallAttend> createState() => _CallAttendState();
}

class _CallAttendState extends State<CallAttend> {
  bool isMuted = false;
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  AgoraRtmClient? _client;
  AgoraRtmChannel? _channel;

  Future<AgoraRtmChannel?> createChannel(String name) async {
    AgoraRtmChannel? channel = await _client?.createChannel(name);
    if (channel != null) {
      channel.onMemberJoined = (AgoraRtmMember member) {
        print('Member joined: ${member.userId}, channel: ${member.channelId}');
      };
      channel.onMemberLeft = (AgoraRtmMember member) {
        print('Member left: ${member.userId}, channel: ${member.channelId}');
      };
      channel.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) {
        print("Channel msg: ${member.userId}, msg: ${message.text}");
      };
    } else {
      print("Channel creation failed $channel");
    }
    print("xxxxxxxxxxxxxxxxx");
    return channel;
  }

  @override
  void initState() {
    super.initState();
    createChannel(widget.channelId);
    initAgora();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    //create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: widget.channelId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 224, 237, 243),
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(widget.channelId),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: SizedBox(
              width: 100,
              height: 150,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          Positioned(
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          isMuted = !isMuted;
                        });
                        _engine.muteLocalAudioStream(isMuted);
                      },
                      icon: Icon(
                        isMuted ? Icons.mic_off : Icons.mic,
                        color: isMuted ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.red,
                    radius: 30,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.call_end,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: IconButton(
                      onPressed: () {
                        _engine.switchCamera();
                      },
                      icon: Icon(
                        Icons.camera_rear_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  )
                ],
              ),
            ),
            bottom: 50,
            left: 0,
          ),
        ],
      ),
    );
  }

  // Display remote user's video
  Widget _remoteVideo(channelId) {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channelId),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
}
