import 'package:flutter/material.dart';
import '../../../core/widgets/app_widgets.dart';

class DraggableChatBox extends StatefulWidget {
  const DraggableChatBox({super.key});

  @override
  State<DraggableChatBox> createState() => _DraggableChatBoxState();
}

class _DraggableChatBoxState extends State<DraggableChatBox> {
  Offset _offset = const Offset(-20, -20);
  bool _isInitialized = false;
  bool _isExpanded = false;

  final Color vgMidnight = const Color(0xFF0F1E36);
  final Color vgCyanSky = const Color(0xFF1C528B);
  final Color vgStarGold = const Color(0xFFF3C63F);

  // Simulated list of messages
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Xin chào! Tôi là trợ lý AI của BigSize Shop. Tôi có thể giúp gì cho bạn hôm nay?',
      'isMe': false,
    }
  ];

  final _textController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      // Start near bottom-right
      _offset = Offset(size.width - 80, size.height - 150);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _textController.text.trim(),
        'isMe': true,
      });
      final input = _textController.text.trim();
      _textController.clear();
      
      // Simulate a quick automatic friendly AI response after 800ms
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'text': 'Cảm ơn bạn đã nhắn tin! Tính năng trợ lý AI trả lời cho câu hỏi "$input" đang được hoàn thiện và sẽ sớm ra mắt.',
              'isMe': false,
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const SizedBox.shrink();

    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: _isExpanded ? _buildExpandedChat() : _buildChatBubble(),
    );
  }

  Widget _buildChatBubble() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final size = MediaQuery.of(context).size;
          double newX = _offset.dx + details.delta.dx;
          double newY = _offset.dy + details.delta.dy;

          // Clamping to stay inside screen bounds
          newX = newX.clamp(10.0, size.width - 70.0);
          newY = newY.clamp(kToolbarHeight, size.height - 80.0);

          _offset = Offset(newX, newY);
        });
      },
      onTap: () {
        setState(() {
          _isExpanded = true;
          final size = MediaQuery.of(context).size;
          // Shift offset so the chat window's bottom-right aligns with the bubble's bottom-right
          double newX = _offset.dx - 240;
          double newY = _offset.dy - 340;

          newX = newX.clamp(10.0, size.width - 320.0);
          newY = newY.clamp(kToolbarHeight, size.height - 430.0);
          _offset = Offset(newX, newY);
        });
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: vgStarGold,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Icon(
          Icons.support_agent,
          color: vgMidnight,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildExpandedChat() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final size = MediaQuery.of(context).size;
          double newX = _offset.dx + details.delta.dx;
          double newY = _offset.dy + details.delta.dy;

          newX = newX.clamp(10.0, size.width - 320.0);
          newY = newY.clamp(kToolbarHeight, size.height - 430.0);

          _offset = Offset(newX, newY);
        });
      },
      child: Container(
        width: 300,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: vgStarGold, width: 2),
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: vgMidnight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: vgStarGold, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = false;
                        final size = MediaQuery.of(context).size;
                        // Shift offset back so the bubble's bottom-right aligns with the chat window's bottom-right
                        double newX = _offset.dx + 240;
                        double newY = _offset.dy + 340;

                        newX = newX.clamp(10.0, size.width - 70.0);
                        newY = newY.clamp(kToolbarHeight, size.height - 80.0);
                        _offset = Offset(newX, newY);
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            // Chat messages body
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'] as bool;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isMe ? vgCyanSky.withOpacity(0.15) : Colors.grey.shade100,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                          bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                        ),
                        border: Border.all(
                          color: isMe ? vgCyanSky.withOpacity(0.3) : Colors.grey.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: vgMidnight,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Chat footer input
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFAF9F6),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(color: vgMidnight, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Type your question...',
                        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: vgStarGold,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.send, color: vgMidnight, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
