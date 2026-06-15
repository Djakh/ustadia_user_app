import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class VoiceAgentAudioRouteService {
  static const MethodChannel channel = MethodChannel('uz.ustadia.user/audio_route');
  static final StreamController<Map<String, dynamic>> _routeChangesController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _isListeningToNativeRouteChanges = false;

  const VoiceAgentAudioRouteService();

  static const VoiceAgentAudioRouteService instance = VoiceAgentAudioRouteService();

  Stream<Map<String, dynamic>> get routeChanges {
    _ensureNativeRouteChangeHandler();
    return _routeChangesController.stream;
  }

  Future<Map<String, dynamic>?> applyOutputMode(
      {required String outputMode, required String reason}) async {
    return invokeMethod('applyVoiceAgentOutputMode', outputMode: outputMode, reason: reason);
  }

  Future<Map<String, dynamic>?> stopSession({required String reason}) async {
    return invokeMethod('stopVoiceAgentSession', reason: reason);
  }

  Future<Map<String, dynamic>?> invokeMethod(String method,
      {String? outputMode, required String reason}) async {
    _ensureNativeRouteChangeHandler();
    try {
      final response = await channel.invokeMapMethod<dynamic, dynamic>(
          method, {'reason': reason, if (outputMode != null) 'outputMode': outputMode});
      if (response == null) return null;
      final snapshot = Map<String, dynamic>.from(response);
      debugPrint('[AudioRoute][$method] $snapshot');
      return snapshot;
    } on MissingPluginException {
      debugPrint('[AudioRoute][$method] missing native implementation');
      return null;
    } catch (error, stackTrace) {
      debugPrint('[AudioRoute][$method] failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static void _ensureNativeRouteChangeHandler() {
    if (_isListeningToNativeRouteChanges) return;
    _isListeningToNativeRouteChanges = true;
    channel.setMethodCallHandler((call) async {
      if (call.method != 'voiceAgentAudioRouteChanged') return null;
      final arguments = call.arguments;
      if (arguments is Map) {
        final snapshot = Map<String, dynamic>.from(arguments);
        debugPrint('[AudioRoute][route_changed] $snapshot');
        _routeChangesController.add(snapshot);
      }
      return null;
    });
  }
}
