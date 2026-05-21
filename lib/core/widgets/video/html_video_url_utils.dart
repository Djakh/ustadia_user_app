class HtmlVideoUrlUtils {
  static const List<String> directVideoExtensions = ['.mp4', '.mov', '.m3u8', '.webm'];

  const HtmlVideoUrlUtils._();

  static String? youtubeVideoId(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return null;
    if (!trimmedUrl.contains('http') && trimmedUrl.length == 11) return trimmedUrl;

    final uri = _parseUri(trimmedUrl);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    final pathSegments = uri.pathSegments;

    if (_isYoutubeShortHost(host) && pathSegments.isNotEmpty) {
      return _normalizedYoutubeId(pathSegments.first);
    }
    if (!_isYoutubeHost(host)) return null;

    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return _normalizedYoutubeId(queryId);

    if (pathSegments.length >= 2 &&
        (pathSegments.first == 'shorts' ||
            pathSegments.first == 'embed' ||
            pathSegments.first == 'live')) {
      return _normalizedYoutubeId(pathSegments[1]);
    }
    return null;
  }

  static bool isYoutubeUrl(String url) => youtubeVideoId(url) != null;

  static bool isDirectVideoUrl(String url) {
    final uri = _parseUri(url.trim());
    if (uri == null) return false;
    final path = uri.path.toLowerCase();
    return directVideoExtensions.any(path.endsWith);
  }

  static bool isPlayableVideoUrl(String url) => isYoutubeUrl(url) || isDirectVideoUrl(url);

  static String _normalizedYoutubeId(String value) {
    final id = value.trim();
    return id.length > 11 ? id.substring(0, 11) : id;
  }

  static Uri? _parseUri(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.hasScheme || !url.contains('.')) return uri;
    return Uri.tryParse('https://$url');
  }

  static bool _isYoutubeHost(String host) =>
      host == 'youtube.com' ||
      host.endsWith('.youtube.com') ||
      host == 'youtube-nocookie.com' ||
      host.endsWith('.youtube-nocookie.com');

  static bool _isYoutubeShortHost(String host) => host == 'youtu.be' || host.endsWith('.youtu.be');
}
