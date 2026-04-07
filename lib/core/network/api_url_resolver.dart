String resolveApiAssetUrl(
  String? url, {
  required String baseUrl,
}) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return Uri.parse(baseUrl).resolve(url).toString();
}
