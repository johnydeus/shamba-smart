import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Three possible states for the AI response box
enum AiState { idle, loading, success, error }

class AiProvider extends ChangeNotifier {
  AiState _state = AiState.idle;
  String _response = '';

  AiState get state => _state;
  String get response => _response;
  bool get isLoading => _state == AiState.loading;

  static const _url = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-5';
  static String get _key => dotenv.env['CLAUDE_API_KEY'] ?? '';

  // Ask Claude a question as a Tanzania farming advisor
  Future<void> askQuestion({
    required String question,
    required String userRole,   // e.g. "Mkulima"
    required String userRegion, // e.g. "Morogoro"
  }) async {
    if (question.trim().isEmpty) return;

    _state = AiState.loading;
    _response = '';
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _key,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 800,
          'system':
              'Wewe ni mshauri wa kilimo Tanzania. '
              'Mtumiaji ni $userRole kutoka $userRegion. '
              'Jibu kwa Kiswahili fupi, vitendo, emoji. '
              'Rahisi kusoma kwenye simu. '
              'Toa ushauri wa vitendo unaofaa Tanzania.',
          'messages': [
            {'role': 'user', 'content': question}
          ],
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _response = data['content'][0]['text'] as String;
        _state = AiState.success;
      } else {
        _response = '⚠️ Hitilafu ya mtandao. Jaribu tena.';
        _state = AiState.error;
      }
    } catch (e) {
      _response = '⚠️ Hitilafu ya mtandao. Jaribu tena.';
      _state = AiState.error;
      debugPrint('AiProvider error: $e');
    }

    notifyListeners();
  }

  // Reset back to idle (clear response)
  void reset() {
    _state = AiState.idle;
    _response = '';
    notifyListeners();
  }
}
