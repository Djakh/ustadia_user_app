import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ustadia_user_app/core/network/api_url_resolver.dart';

abstract class AudioRepository {
  Future<String> downloadAudio(String audioUrl);
}

class AudioRepositoryImpl implements AudioRepository {
  final Dio dio;

  AudioRepositoryImpl({required this.dio});

  @override
  Future<String> downloadAudio(String audioUrl) async {
    final localAudioUrl =
        resolveApiAssetUrl(audioUrl, baseUrl: dio.options.baseUrl);
    final directory = await getTemporaryDirectory();
    final fileName = Uri.parse(localAudioUrl).pathSegments.last;
    final safeFileName =
        fileName.isNotEmpty ? fileName : 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final filePath = '${directory.path}/$safeFileName';
    final file = File(filePath);
    if (file.existsSync()) return filePath;
    await dio.download(localAudioUrl, filePath);
    return filePath;
  }
}
