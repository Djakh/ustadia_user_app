import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VoiceAgentAudioRouteService {
  static const MethodChannel channel = MethodChannel('uz.ustadia.user/audio_route');

  const VoiceAgentAudioRouteService();

  static const VoiceAgentAudioRouteService instance = VoiceAgentAudioRouteService();

  Future<void> startSession({required String reason}) async {
    await invokeMethod('startVoiceAgentSession', reason: reason);
  }

  Future<void> enterPlaybackMode({required String reason}) async {
    await invokeMethod('enterVoiceAgentPlaybackMode', reason: reason);
  }

  Future<void> enterCaptureMode({required String reason}) async {
    await invokeMethod('enterVoiceAgentCaptureMode', reason: reason);
  }

  Future<void> stopSession({required String reason}) async {
    await invokeMethod('stopVoiceAgentSession', reason: reason);
  }

  Future<void> invokeMethod(String method, {required String reason}) async {
    try {
      final response = await channel.invokeMapMethod<dynamic, dynamic>(method, {'reason': reason});
      if (response == null) return;
      debugPrint('[AudioRoute][$method] ${Map<String, dynamic>.from(response)}');
    } on MissingPluginException {
      debugPrint('[AudioRoute][$method] missing native implementation');
    } catch (error, stackTrace) {
      debugPrint('[AudioRoute][$method] failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
