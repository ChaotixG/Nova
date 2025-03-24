import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'custom_button.dart' as button; // Import your custom button
//import '../color_reference.dart';
import 'dart:async';
import '../states/voice_state.dart'; // Import the VoiceStateWidget

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  ChatWidgetState createState() => ChatWidgetState();
}

class ChatWidgetState extends State<ChatWidget> {
  final List<Message> messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addAIMessage("Hello! I'm Nova. How can I assist you?");
  }

  /// Adds an AI message to the chat with a typing effect.
  Future<void> _addAIMessage(String fullMessage) async {
    if (!mounted) return; // Check if the widget is still mounted

    setState(() {
      _isTyping = false;
      messages.add(Message(text: "", isSender: false)); // Adds blank message initially
    });

    String currentMessage = "";
    for (int i = 0; i < fullMessage.length; i++) {
      await Future.delayed(const Duration(milliseconds: 40));

      currentMessage += fullMessage[i];
      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        messages[messages.length - 1] = Message(text: currentMessage, isSender: false); // Updates the message one character at a time
      });
    }
  }

  /// Handles sending a user message.
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        messages.add(Message(text: text, isSender: true)); // User message
        _isTyping = false; // Hide typing indicator when user sends a message
      });
      _controller.clear();
      _isTyping = true;
      Future.delayed(const Duration(seconds: 4), () => _addAIMessage("I received: \"$text\""));
    }
  }

  /// Displays options to copy or delete a message when it's long-pressed.
  void _onMessageLongPress(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text("Copy"),
            onTap: () {
              Navigator.pop(context);
              Clipboard.setData(ClipboardData(text: message.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Message copied to clipboard.")),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Delete"),
            onTap: () {
              setState(() => messages.remove(message));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildMessageList(),
          _buildInputField(),
        ],
      ),
    );
  }

  /// Builds the chat message list.
  Widget _buildMessageList() {
    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (_isTyping && index == 0) {
            return _buildTypingIndicator(); // Displays typing indicator for AI
          }

          final message = messages[messages.length - 1 - (_isTyping ? index - 1 : index)];
          return GestureDetector(
            onLongPress: () => _onMessageLongPress(context, message),
            child: Align(
              alignment: message.isSender ? Alignment.centerRight : Alignment.centerLeft,
              child: _buildMessageBubble(message),
            ),
          );
        },
      ),
    );
  }

  /// Builds a message bubble (sent or received message).
  Widget _buildMessageBubble(Message message) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: message.isSender
            ? Colors.blueAccent.withAlpha(51)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  /// Builds the typing indicator.
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: _buildMessageBubble(
        Message(text: "Nova is typing...", isSender: false),
      ),
    );
  }

  /// Builds the message input field and custom button with microphone icon.
  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              minLines: 1,
              maxLines: 4,
            ),
          ),
          const SizedBox(width: 8),
          // Use the CustomButton with microphone icon or animation
          button.CustomButton(
            text: "", // Keep the text empty
            onPressed: () {
              // Ensure widget is still mounted before navigating
              if (mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VoiceStateWidget(
                      onBackToNova: () {
                        if (mounted) {
                          Navigator.pop(context); // Go back to the previous screen
                        }
                      },
                    ),
                  ),
                );
              }
            },
            animationOrGif: Lottie.asset(
              'assets/animations/ai_speech.json',
              width: MediaQuery.of(context).size.width * 0.05, // 5% of the screen width
            ),
          )
        ],
      ),
    );
  }
}

/// Represents a message in the chat.
class Message {
  final String text;
  final bool isSender;

  Message({required this.text, this.isSender = false});
}
