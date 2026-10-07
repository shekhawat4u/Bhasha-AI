import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/translation_result.dart';

class GpuStreamService {
  WebSocketChannel? _channel;
  final StreamController<TranslationResult> _streamController = StreamController<TranslationResult>.broadcast();
  bool _isConnected = false;

  Stream<TranslationResult> get stream => _streamController.stream;
  bool get isConnected => _isConnected;

  Future<bool> connect(
    String host,
    int port, {
    String sourceLang = 'auto',
    String targetLang = 'en',
    bool useIndic = false,
  }) async {
    try {
      disconnect();
      final queryParams = {
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'use_indic': useIndic.toString(),
      };
      final wsUri = Uri(
        scheme: 'ws',
        host: host,
        port: port,
        path: '/ws/audio/stream',
        queryParameters: queryParams,
      );

      _channel = WebSocketChannel.connect(wsUri);
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message.toString());
            final result = TranslationResult.fromJson(
              data,
              sourceLang: sourceLang,
              targetLang: targetLang,
            );
            _streamController.add(result);
          } catch (_) {}
        },
        onError: (e) {
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
      return true;
    } catch (_) {
      _isConnected = false;
      return false;
    }
  }

  void sendAudioChunk(Uint8List bytes) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(bytes);
      } catch (_) {}
    }
  }

  void flush() {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'action': 'flush'}));
      } catch (_) {}
    }
  }

  void disconnect() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _streamController.close();
  }
}

