import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tailor_app/constants.dart';

class ChatScreen extends StatefulWidget {
  final String orderId;
  final String senderEmail;
  final String receiverTitle;

  const ChatScreen({
    Key? key,
    required this.orderId,
    required this.senderEmail,
    required this.receiverTitle,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isRecording = false;
  bool _isLocked = false;
  double _dragOffset = 0.0;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final GlobalKey _micKey = GlobalKey();
  File? _selectedImage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchMessages();
    _timer = Timer.periodic(Duration(seconds: 3), (_) => _fetchMessages(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent && _messages.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await http.get(Uri.parse('$apiUrl/chat/${widget.orderId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _messages = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching chat messages: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Colors.red),
                title: Text('Choose Photo from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.red),
                title: Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _cancelVoiceRecording() async {
    _recordTimer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (e) {
      print('Error cancelling audio recording: $e');
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isLocked = false;
        _dragOffset = 0.0;
        _recordSeconds = 0;
      });
    }
  }

  void _startVoiceRecording() async {
    if (_isRecording) return;
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Microphone permission denied. Please allow microphone access in Settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final recordPath = '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(),
        path: recordPath,
      );
      print('[AudioRecorder] Recording started at: $recordPath');

      setState(() {
        _isRecording = true;
        _isLocked = false;
        _dragOffset = 0.0;
        _recordSeconds = 0;
      });

      _recordTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
    } catch (e) {
      print('Error starting audio recorder: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start microphone: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _stopAndSendVoiceRecording() async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    final duration = _recordSeconds;

    try {
      final path = await _audioRecorder.stop();
      print('[AudioRecorder] Stopped recording. Output path: $path');
      setState(() {
        _isRecording = false;
        _isLocked = false;
        _dragOffset = 0.0;
        _recordSeconds = 0;
      });

      if (path != null && File(path).existsSync()) {
        final bytes = await File(path).readAsBytes();
        print('[AudioRecorder] Recorded audio bytes size: ${bytes.length}');
        if (bytes.isNotEmpty) {
          final base64Audio = 'data:audio/m4a;base64,${base64Encode(bytes)}';
          _sendVoiceNoteMessage(duration, base64Audio);
        } else {
          _sendVoiceNoteMessage(duration, null);
        }
      } else {
        _sendVoiceNoteMessage(duration, null);
      }
    } catch (e) {
      print('Error stopping audio recorder: $e');
      setState(() {
        _isRecording = false;
        _isLocked = false;
        _dragOffset = 0.0;
        _recordSeconds = 0;
      });
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_isLocked) return;

    final dy = details.offsetFromOrigin.dy;
    final dx = details.offsetFromOrigin.dx;

    setState(() {
      _dragOffset = dx;
    });

    if (dy < -40) {
      setState(() {
        _isLocked = true;
        _dragOffset = 0.0;
      });
    } else if (dx.abs() > 60) {
      _cancelVoiceRecording();
    }
  }

  Future<void> _sendVoiceNoteMessage(int seconds, String? base64Audio) async {
    final noteText = '🎤 Voice Note (${seconds > 0 ? seconds : 1}s)';
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/chat/${widget.orderId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': widget.senderEmail,
          'text': noteText,
          'audio': base64Audio,
          'is_voice': true,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchMessages(silent: true);
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending voice note: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    String? imageBase64;
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/chat/${widget.orderId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': widget.senderEmail,
          'text': text,
          'image': imageBase64,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _textController.clear();
        setState(() {
          _selectedImage = null;
        });
        await _fetchMessages(silent: true);
        _scrollToBottom();
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message.')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _deleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Message'),
        content: Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final response = await http.delete(Uri.parse('$apiUrl/chat/${widget.orderId}/$messageId'));
                if (response.statusCode == 200) {
                  _fetchMessages(silent: true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete message')));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting message')));
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showFullScreenImageDialog(BuildContext context, String imageData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.95),
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: imageData.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(imageData.split(',').last),
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          imageData,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: Colors.white, size: 80),
                        ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String imageData) {
    Widget imageContent;
    if (imageData.startsWith('data:image')) {
      final base64String = imageData.split(',').last;
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          base64Decode(base64String),
          fit: BoxFit.cover,
          width: 220,
          height: 220,
        ),
      );
    } else {
      imageContent = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageData,
          fit: BoxFit.cover,
          width: 220,
          height: 220,
          errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 50),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImageDialog(context, imageData),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          imageContent,
          Container(
            margin: EdgeInsets.all(6),
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.fullscreen, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${widget.orderId} Chat', style: TextStyle(fontSize: 18)),
            Text('Talking to ${widget.receiverTitle}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.\nSend a message, photo, or voice note to chat!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMe = (msg['sender'] ?? '').toString().toLowerCase() == widget.senderEmail.toLowerCase();
                          final isVoice = (msg['is_voice'] == true) ||
                              (msg['is_voice'].toString() == 'true') ||
                              (msg['text'] ?? '').toString().toLowerCase().contains('voice note') ||
                              (msg['text'] ?? '').toString().contains('🎤');

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: GestureDetector(
                              onLongPress: () {
                                if (msg['id'] != null) {
                                  _deleteMessage(msg['id'].toString());
                                }
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                padding: EdgeInsets.all(12),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.red[400] : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                    bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
                                    bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isMe ? 'You' : (msg['sender'] ?? 'Other'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isMe ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  if (msg['image'] != null && msg['image'].toString().isNotEmpty) ...[
                                    _buildImageWidget(msg['image']),
                                    SizedBox(height: 6),
                                  ],
                                  if (isVoice) ...[
                                    VoiceNotePlayerWidget(
                                      text: msg['text'] ?? 'Voice Note (5s)',
                                      audioData: msg['audio'],
                                      isMe: isMe,
                                    ),
                                  ] else if (msg['text'] != null && msg['text'].toString().isNotEmpty) ...[
                                    Text(
                                      msg['text'],
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isMe ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 4),
                                  Text(
                                    msg['timestamp'] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe ? Colors.white60 : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      ),
          ),
          if (_selectedImage != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!, width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  SizedBox(width: 12),
                  Text('Photo attached', style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedImage = null),
                  ),
                ],
              ),
            ),

          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Visibility(
                    visible: !_isRecording,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add_circle, color: Colors.red, size: 28),
                          tooltip: 'Attach Photo',
                          onPressed: _showAttachmentOptions,
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isRecording
                        ? Row(
                            children: [
                              if (_isLocked)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: _cancelVoiceRecording,
                                ),
                              Expanded(
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.mic, color: Colors.red, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        '${(_recordSeconds ~/ 60).toString().padLeft(2, '0')}:${(_recordSeconds % 60).toString().padLeft(2, '0')}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      if (!_isLocked) ...[
                                        SizedBox(width: 16),
                                        Text(
                                          '< Slide to cancel',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          ),
                  ),
                  SizedBox(width: 8),
                  _isSending
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : (!_isRecording && _textController.text.isNotEmpty)
                          ? IconButton(
                              icon: Icon(Icons.send, color: Colors.red),
                              onPressed: _sendMessage,
                            )
                          : (_isRecording && _isLocked)
                              ? IconButton(
                                  icon: Icon(Icons.send, color: Colors.red),
                                  onPressed: _stopAndSendVoiceRecording,
                                )
                              : Transform.translate(
                                  offset: Offset(_dragOffset, 0),
                                  child: GestureDetector(
                                    key: _micKey,
                                    onLongPressStart: (_) => _startVoiceRecording(),
                                    onLongPressEnd: (details) {
                                      if (!_isLocked && _isRecording) _stopAndSendVoiceRecording();
                                    },
                                    onLongPressMoveUpdate: _onLongPressMoveUpdate,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (_isRecording)
                                          Icon(Icons.lock_open, color: Colors.grey[400], size: 16),
                                        if (_isRecording) SizedBox(height: 4),
                                        Material(
                                          color: Colors.red,
                                          shape: CircleBorder(),
                                          child: Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Icon(Icons.mic, color: Colors.white, size: 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class VoiceNotePlayerWidget extends StatefulWidget {
  final String text;
  final String? audioData;
  final bool isMe;

  const VoiceNotePlayerWidget({
    Key? key,
    required this.text,
    this.audioData,
    required this.isMe,
  }) : super(key: key);

  @override
  _VoiceNotePlayerWidgetState createState() => _VoiceNotePlayerWidgetState();
}

class _VoiceNotePlayerWidgetState extends State<VoiceNotePlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _progress = 0.0;
  Timer? _playTimer;
  int _currentSecond = 0;
  int _totalSeconds = 5;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  @override
  void initState() {
    super.initState();
    final regExp = RegExp(r'\((\d+)s\)');
    final match = regExp.firstMatch(widget.text);
    if (match != null) {
      _totalSeconds = int.tryParse(match.group(1)!) ?? 5;
    }

    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _progress = 0.0;
            _currentSecond = 0;
            _isPlaying = false;
          }
        });
      }
    });

    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted && _totalSeconds > 0) {
        setState(() {
          _currentSecond = pos.inSeconds;
          _progress = (pos.inMilliseconds / (_totalSeconds * 1000)).clamp(0.0, 1.0);
        });
      }
    });

    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) {
        setState(() {
          _totalSeconds = dur.inSeconds;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      try {
        await _audioPlayer.pause();
      } catch (_) {}
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (widget.audioData != null && widget.audioData!.startsWith('data:audio')) {
        try {
          final base64String = widget.audioData!.split(',').last;
          final bytes = base64Decode(base64String);
          print('[AudioPlayer] Decoded audio bytes: ${bytes.length}');

          if (bytes.isNotEmpty) {
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/play_${DateTime.now().millisecondsSinceEpoch}.m4a');
            await tempFile.writeAsBytes(bytes, flush: true);

            await _audioPlayer.setVolume(1.0);

            try {
              // Method 1: BytesSource
              await _audioPlayer.play(BytesSource(bytes));
              print('[AudioPlayer] Playing via BytesSource success');
            } catch (e1) {
              print('[AudioPlayer] BytesSource failed: $e1. Trying UrlSource file://...');
              try {
                // Method 2: UrlSource file://
                await _audioPlayer.play(UrlSource('file://${tempFile.path}'));
                print('[AudioPlayer] Playing via UrlSource file:// success');
              } catch (e2) {
                print('[AudioPlayer] UrlSource failed: $e2. Trying DeviceFileSource...');
                // Method 3: DeviceFileSource
                await _audioPlayer.play(DeviceFileSource(tempFile.path));
                print('[AudioPlayer] Playing via DeviceFileSource success');
              }
            }
          } else {
            _startSimulatedPlay();
          }
        } catch (e) {
          print('[AudioPlayer Exception] $e');
          _startSimulatedPlay();
        }
      } else {
        _startSimulatedPlay();
      }
    }
  }

  void _startSimulatedPlay() {
    _playTimer?.cancel();
    setState(() {
      _isPlaying = true;
      _currentSecond = 0;
      _progress = 0.0;
    });

    _playTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.2 / _totalSeconds;
        _currentSecond = (_progress * _totalSeconds).floor();
        if (_currentSecond > _totalSeconds) _currentSecond = _totalSeconds;
        if (_progress >= 1.0) {
          _playTimer?.cancel();
          _isPlaying = false;
          _progress = 0.0;
          _currentSecond = 0;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final btnBgColor = widget.isMe ? Colors.white : Colors.red;
    final btnIconColor = widget.isMe ? Colors.red : Colors.white;

    String formatTime(int sec) {
      final m = (sec ~/ 60).toString().padLeft(1, '0');
      final s = (sec % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      width: 260,
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.red.shade400 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play Button
          Material(
            color: btnBgColor,
            shape: CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: CircleBorder(),
              onTap: _togglePlay,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: btnIconColor,
                  size: 26,
                ),
              ),
            ),
          ),
          SizedBox(width: 14),
          // Progress Bar and Timer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform / Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: widget.isMe ? Colors.white38 : Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.isMe ? Colors.white : Colors.red),
                    minHeight: 8,
                  ),
                ),
                SizedBox(height: 8),
                // Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPlaying ? formatTime(_currentSecond) : '0:00',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      formatTime(_totalSeconds),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

