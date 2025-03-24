import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../app_state.dart'; // Import AppState for dynamic state handling
import '../vtt/audio_processor.dart' as audioProcessor;
import '../vtt/audio_recorder.dart' as audioRecorder;

class VoiceStateWidget extends AppState {
  final VoidCallback onBackToNova;

  const VoiceStateWidget({super.key, required this.onBackToNova});

  @override
  Widget build(BuildContext context) {
    return _VoiceState(onBackToNova: onBackToNova);
  }
}

class _VoiceState extends StatefulWidget {
  final VoidCallback onBackToNova;

  const _VoiceState({required this.onBackToNova});

  @override
  _VoiceStateState createState() => _VoiceStateState();
}

class _VoiceStateState extends State<_VoiceState> {
  bool isTalking = false; // Indicates whether the system is in talking mode
  bool isListening = true; // Indicates whether the system is in listening mode
  final List<String> chat = []; // Chat list for AI responses
  late audioRecorder.AudioRecorder _audioRecorder; // Use the alias for AudioRecorder
  late audioProcessor.AudioProcessor _audioProcessor; // Use the alias for AudioProcessor
  StreamSubscription? _audioStreamSubscription;

  @override
  void initState() {
    super.initState();
    _audioRecorder = audioRecorder.AudioRecorder(); // Use the alias for AudioRecorder
    _audioProcessor = audioProcessor.AudioProcessor(); // Use the alias for AudioProcessor

    _initRecorder();
    if (isListening) {
      _startVoiceChat();
    }
  }

  Future<void> _initRecorder() async {
    await _audioRecorder.initRecorder();
  }

  void _startVoiceChat() {
    _audioRecorder.voiceChat(
      onSpeechDetected: () {
        if (isListening) {
          setState(() {
            chat.add("Speech detected.");
            isListening = false;
          });
          _startRecording();
        }
      },
      onEOSDetected: () {
        setState(() {
          isTalking = false;
          isListening = true;
        });
        chat.add("End of speech detected.");
        print("EOS detected, switching to listening mode.");
      },
      onAudioFrame: (audioFrame) {
        if (isListening || isTalking) {
          final isSpeechDetected = _audioProcessor.isSpeech(audioFrame);
          print("Is speech detected: $isSpeechDetected");

          if (isListening && isSpeechDetected) {
            _startRecording();
          } else if (isTalking && _audioProcessor.detectEOS()) {
            print("EOS detected, stopping recording.");
            _stopRecording();
          }
        }
      },
    );
  }

  Future<void> _startRecording() async {
    await _audioRecorder.startRecording(
      onSpeechDetected: () {
        setState(() {
          chat.add("Speech detected, recording started.");
        });
      },
      onEOSDetected: () {
        _stopRecording();
      },
    );
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stopRecording();
    setState(() {
      chat.add("Recording stopped and processed.");
    });
    print("Recording stopped.");
  }

  void _toggleTalkingMode() {
    setState(() {
      isTalking = true;
      isListening = false;
    });
  }

  void _toggleListeningMode() {
    setState(() {
      isListening = true;
      isTalking = false;
    });
  }

  void _handleTalkingInterrupt() {
    if (isTalking) {
      setState(() {
        chat.add("Talking interrupted, switching to listening mode.");
        isTalking = false;
        isListening = true;
      });
    }
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _audioRecorder.disposeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: chat.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(chat[chat.length - 1 - index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 100), // Leave space for the button
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isTalking ? _handleTalkingInterrupt : null,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Lottie.asset('assets/animations/ai_speech.json'),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _toggleListeningMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isListening ? Colors.blue : Colors.grey,
                      ),
                      child: const Text("Listening Mode"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _toggleTalkingMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTalking ? Colors.blue : Colors.grey,
                      ),
                      child: const Text("Talking Mode"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 30,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBackToNova,
            ),
          ),
        ],
      ),
    );
  }
}
