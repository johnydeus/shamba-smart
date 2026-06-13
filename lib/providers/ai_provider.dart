import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AiState { idle, loading, success, error }

class AiProvider extends ChangeNotifier {
  AiState _state = AiState.idle;
  String _response = '';

  AiState get state => _state;
  String get response => _response;
  bool get isLoading => _state == AiState.loading;

  static const _model = 'claude-sonnet-4-5';

  Future<void> askQuestion({
    required String question,
    required String userRole,
    required String userRegion,
  }) async {
    if (question.trim().isEmpty) return;

    _state = AiState.loading;
    _response = '';
    notifyListeners();

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'claude-proxy',
        body: {
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
        },
      );

      final data = res.data as Map<String, dynamic>;
      _response = data['content'][0]['text'] as String;
      _state = AiState.success;
    } catch (e) {
      _response = '⚠️ Hitilafu ya mtandao. Jaribu tena.';
      _state = AiState.error;
      debugPrint('AiProvider error: $e');
    }

    notifyListeners();
  }

  void reset() {
    _state = AiState.idle;
    _response = '';
    notifyListeners();
  }
}
