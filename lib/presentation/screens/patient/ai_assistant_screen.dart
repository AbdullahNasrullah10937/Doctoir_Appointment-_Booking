import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../widgets/screen_helpers.dart';

class AiHealthAssistantScreen extends StatefulWidget {
  const AiHealthAssistantScreen({super.key});

  @override
  State<AiHealthAssistantScreen> createState() => _AiHealthAssistantScreenState();
}

class _AiHealthAssistantScreenState extends State<AiHealthAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = <ChatMessage>[
    const ChatMessage(
      text: 'Hello! I\'m your MediQ AI Health Assistant. Ask me anything about your symptoms or health concerns.',
      isUser: false,
    ),
  ];

  final List<String> _quickReplies = <String>[
    'I have a headache',
    'Fever for 2 days',
    'Chest pain',
    'Stomach ache',
  ];

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _inputController.text.trim();
    if (msg.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: msg, isUser: true));
      _messages.add(const ChatMessage(
        text: 'Based on your symptoms, possible causes include stress, dehydration, or infection. If symptoms persist beyond 48 hours, please consult a doctor immediately. I can help you find a specialist.',
        isUser: false,
      ));
      _inputController.clear();
    });
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // AppBar
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('AI Health Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text('General guidance only', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            // Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: 8),
              color: AppTheme.warningLight,
              child: Row(
                children: <Widget>[
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI provides general guidance, not medical diagnosis.',
                      style: TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppTheme.space4),
                itemCount: _messages.length,
                itemBuilder: (_, index) {
                  final msg = _messages[index];
                  return _ChatBubble(message: msg);
                },
              ),
            ),
            // Quick replies
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4),
                children: _quickReplies.map((reply) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendMessage(reply),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        reply,
                        style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(AppTheme.space4, 8, AppTheme.space4, AppTheme.space4),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: const InputDecoration(hintText: 'Ask a health question...'),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(AppRouter.doctorSearch, arguments: 'General Physician'),
                      icon: const Icon(Icons.search_rounded, size: 16),
                      label: const Text('Find Related Doctors'),
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

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? AppTheme.accentBlue : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(message.isUser ? 14 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 14),
          ),
          border: message.isUser ? null : Border.all(color: AppTheme.border),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : AppTheme.textPrimary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
