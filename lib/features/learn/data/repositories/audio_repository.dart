import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

abstract class AudioRepository {
  Future<String> downloadAudio(String audioUrl);
}

class AudioRepositoryImpl implements AudioRepository {
  final Dio dio;

  AudioRepositoryImpl({required this.dio});

  @override
  Future<String> downloadAudio(String audioUrl) async {
    final localAudioUrl = audioUrl.startsWith('http')
        ? audioUrl
        : 'https://backend.ustadia.findecor.io$audioUrl';
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
