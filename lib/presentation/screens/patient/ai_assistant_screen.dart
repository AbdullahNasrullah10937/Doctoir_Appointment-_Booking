import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../routes/app_router.dart';
import '../../state/app_scope.dart';
import '../../widgets/screen_helpers.dart';

class AiHealthAssistantScreen extends StatefulWidget {
  const AiHealthAssistantScreen({super.key});

  @override
  State<AiHealthAssistantScreen> createState() => _AiHealthAssistantScreenState();
}

class _AiHealthAssistantScreenState extends State<AiHealthAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentStreamedText;

  final List<String> _quickReplies = <String>[
    'I have a headache',
    'Fever for 2 days',
    'Chest pain',
    'Stomach ache',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.of(context).loadAiChatHistory().then((_) {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage([String? text]) {
    final msg = text ?? _inputController.text.trim();
    if (msg.isEmpty) return;

    _inputController.clear();
    final appState = AppScope.of(context);

    setState(() {
      _currentStreamedText = '';
    });
    _scrollToBottom();

    appState.streamAssistantChat(msg).listen(
      (fullText) {
        setState(() {
          _currentStreamedText = fullText;
        });
        _scrollToBottom();
      },
      onError: (e) {
        setState(() {
          _currentStreamedText = null;
        });
      },
      onDone: () {
        setState(() {
          _currentStreamedText = null;
        });
        _scrollToBottom();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final messages = appState.aiChatHistory;
    final showStreamingBubble = _currentStreamedText != null;
    final showTypingIndicator = appState.isAiAssistantTyping && !showStreamingBubble;

    final totalItems = messages.length +
        (showStreamingBubble ? 1 : 0) +
        (showTypingIndicator ? 1 : 0);

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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'AI Health Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text('General guidance only', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                    tooltip: 'New Chat',
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Start New Chat?'),
                          content: const Text('This will archive your current chat session and start a fresh conversation.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentBlue,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Start New'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await appState.startNewChatSession();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fresh chat session started.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space4, vertical: 8),
              color: AppTheme.warningLight,
              child: const Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI provides general guidance, not medical diagnosis.',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppTheme.space4),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  if (index < messages.length) {
                    final msg = messages[index];
                    return _ChatBubble(message: msg);
                  } else if (showStreamingBubble && index == messages.length) {
                    return _ChatBubble(
                      message: ChatMessage(
                        text: _currentStreamedText!,
                        isUser: false,
                      ),
                    );
                  } else {
                    return const _ChatBubbleLoader();
                  }
                },
              ),
            ),
            // Emergency Action Overlays
            if (appState.showEmergencyBanner)
              Container(
                margin: const EdgeInsets.all(AppTheme.space4),
                padding: const EdgeInsets.all(AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppTheme.dangerLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.gpp_bad_rounded, color: AppTheme.danger, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Action Required',
                          style: TextStyle(
                            color: AppTheme.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your query indicates acute high-risk symptoms. Bypassing AI analysis. Please call rescue services or proceed to the nearest emergency ward immediately.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri(scheme: 'tel', path: '1122');
                              try {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch dialer';
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not open phone dialer: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.danger,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                            label: const Text('Call 1122'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final uri = Uri(scheme: 'tel', path: '15');
                              try {
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                } else {
                                  throw 'Could not launch dialer';
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not open phone dialer: $e')),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.danger),
                              foregroundColor: AppTheme.danger,
                            ),
                            icon: const Icon(Icons.local_police_rounded, size: 16),
                            label: const Text('Call 15'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            // Quick replies (only if not typing/streaming/emergency)
            if (!appState.isAiAssistantTyping && !showStreamingBubble && !appState.showEmergencyBanner)
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
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            // Input panel
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
                          enabled: !appState.isAiAssistantTyping && !showStreamingBubble,
                          decoration: const InputDecoration(hintText: 'Ask a health question...'),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: (appState.isAiAssistantTyping || showStreamingBubble)
                              ? AppTheme.border
                              : AppTheme.accentBlue,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: IconButton(
                          onPressed: (appState.isAiAssistantTyping || showStreamingBubble)
                              ? null
                              : _sendMessage,
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
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRouter.doctorSearch,
                        arguments: 'General Physician',
                      ),
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

  String _cleanText(String text) {
    if (message.isUser) return text;
    var cleaned = text;
    // Replace markdown bold/italic asterisks
    cleaned = cleaned.replaceAll('**', '');
    cleaned = cleaned.replaceAll('* ', '• ');
    cleaned = cleaned.replaceAll(RegExp(r'(?<=^|\n)\*\s'), '• ');
    cleaned = cleaned.replaceAll(RegExp(r'(?<=^|\n)-\s'), '• ');
    cleaned = cleaned.replaceAll('*', '');
    // Remove markdown heading hashes
    cleaned = cleaned.replaceAll(RegExp(r'#+\s'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }

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
          _cleanText(message.text),
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

class _ChatBubbleLoader extends StatefulWidget {
  const _ChatBubbleLoader();

  @override
  State<_ChatBubbleLoader> createState() => _ChatBubbleLoaderState();
}

class _ChatBubbleLoaderState extends State<_ChatBubbleLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(14),
          ),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delay = i * 0.2;
                final value = math.sin((_controller.value * 2 * math.pi) - delay);
                final offset = (value + 1.0) / 2.0 * 6.0;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  transform: Matrix4.translationValues(0, -offset, 0),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.textMuted,
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
