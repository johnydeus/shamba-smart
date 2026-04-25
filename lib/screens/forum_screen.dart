import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/claude_service.dart';
import '../theme/app_colors.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _loading = false;

  @override
  void dispose() {
    _questionController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Send a question to Claude and add the response to the chat
  Future<void> _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _loading = true;
      _questionController.clear();
    });
    _scrollToBottom();

    final answer = await ClaudeService.askFarmingQuestion(
      question: question,
      cropContext: 'mazao mbalimbali',
      regionContext: 'Tanzania',
    );

    setState(() {
      _messages.add({'role': 'claude', 'text': answer});
      _loading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      appBar: AppBar(
        title: Text(
          'Uliza Mtaalamu wa Kilimo',
          style: GoogleFonts.playfairDisplay(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.leaf.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'Claude AI — Mshauri wa Kilimo Tanzania',
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AppColors.leaf),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.leaf.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🌿',
                              style: TextStyle(fontSize: 40)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Uliza swali lolote la kilimo',
                          style: GoogleFonts.playfairDisplay(
                            color: AppColors.soil,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Jibu litakuja kwa Kiswahili',
                          style: GoogleFonts.dmSans(
                              color: AppColors.mid, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        // Quick suggestion chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            'Jinsi ya kupigana na viwavi?',
                            'Bei ya mbolea DAP?',
                            'Mbegu bora za nyanya?',
                            'Dalili za ugonjwa wa mahindi?',
                          ]
                              .map((q) => ActionChip(
                                    label: Text(q,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: AppColors.leaf)),
                                    backgroundColor: AppColors.mint,
                                    onPressed: () {
                                      _questionController.text = q;
                                      _sendQuestion();
                                    },
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.80,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? AppColors.harvest
                                : AppColors.cream,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.soil.withValues(alpha: 0.06),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Text(
                            msg['text'] ?? '',
                            style: GoogleFonts.dmSans(
                              color: isUser
                                  ? Colors.white
                                  : AppColors.ink,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_loading)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Claude anafikiri...',
                    style: GoogleFonts.dmSans(
                        color: AppColors.mid, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.leaf),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border(
                  top: BorderSide(
                      color: AppColors.mid.withValues(alpha: 0.15))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppColors.mid.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _questionController,
                        maxLines: 3,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendQuestion(),
                        style: GoogleFonts.dmSans(
                            fontSize: 14, color: AppColors.ink),
                        decoration: InputDecoration(
                          hintText: 'Andika swali lako hapa...',
                          hintStyle: GoogleFonts.dmSans(
                              color: AppColors.mid, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _loading ? null : _sendQuestion,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _loading ? AppColors.mid : AppColors.leaf,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
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
