import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String _cleanResponse(String response) {
    response = response
        .replaceAll(RegExp(r'<\|begin_of_solution\|>'), '')
        .replaceAll(RegExp(r'<\|end_of_solution\|>'), '')
        .replaceAll(RegExp(r'\*{1,2}'), '')
        .replaceAll(RegExp(r'#+'), '')
        .replaceAll(RegExp(r'\d+\.'), '•')
        .replaceAll(RegExp(r'\- '), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return _decodeUnicode(response);
  }

  String _decodeUnicode(String text) {
    return text.replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }

  Future<void> _sendMessage() async {
    final message = _controller.text;
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'message': message,
      });
      _isLoading = true;
      _controller.clear();
    });

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );

    setState(() {
      _messages.add({
        'sender': 'bot',
        'message': 'speedobot_response'.tr,
      });
    });

    final url = Uri.parse('https://chat.speedobot.com/chat');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'message': message}),
          )
          .timeout(const Duration(seconds: 120));

      setState(() => _messages.removeLast());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String reply = data['response'] ?? 'error_no_reply'.tr;
        reply = _cleanResponse(reply);

        setState(() {
          _messages.add({
            'sender': 'bot',
            'message': reply,
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'message': 'http_error'.tr.replaceAll(
                '{{statusCode}}', response.statusCode.toString()),
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add({
          'sender': 'bot',
          'message': 'connection_error'.tr.replaceAll('{{error}}', e.toString()),
        });
        _isLoading = false;
      });
    }
  }

  Widget _buildMessageInputField() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _controller,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        hintText: 'enter_your_question'.tr,
        hintStyle: TextStyle(
          color: Color(0xFF3ECAA7),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(
            color: Colors.grey.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        suffixIcon: IconButton(
          icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
          onPressed: _isLoading ? null : _sendMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        const Color(0xFF0a0e17),
                        const Color(0xFF02111a),
                      ]
                    : [
                        const Color(0xFFffffff),
                        const Color(0xFFf1f1f1),
                      ],
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message['sender'] == 'user';
                    return _MessageBubble(
                      message: message['message']!,
                      isUser: isUser,
                      senderName: isUser ? 'sender_you'.tr : 'speedobot'.tr,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildMessageInputField(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String senderName;

  const _MessageBubble({
    required this.message,
    required this.isUser,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    Color messageColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: TextStyle(
                  color: isUser ? const Color(0xFF3ECAA7) : const Color(0xFF17c9ef),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (!isUser)
                IconButton(
                  icon: Icon(Icons.copy, size: 16),
                  color: const Color(0xFF17c9ef),
                  padding: EdgeInsets.only(left: 8.0),
                  constraints: BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: message));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('response_copied'.tr),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          isUser
              ? Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7),
                  padding: const EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3ECAA7).withOpacity(0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: const Radius.circular(12),
                      bottomRight: const Radius.circular(0),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: messageColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textDirection: Get.locale?.languageCode == 'ar'
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                  ),
                )
              : Text(
                  message,
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: Get.locale?.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                ),
          const SizedBox(height: 8),
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF17c9ef).withOpacity(0.3),
                  const Color(0xFF17c9ef).withOpacity(0.8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}