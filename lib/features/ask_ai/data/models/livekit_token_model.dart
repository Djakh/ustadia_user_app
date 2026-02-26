class LivekitTokenModel {
  final String url;
  final String token;
  final String roomName;
  final String participantIdentity;
  final bool sttEnabled;
  final bool ttsEnabled;
  final String metadata;

  const LivekitTokenModel(
      {required this.url,
      required this.token,
      required this.roomName,
      required this.participantIdentity,
      required this.sttEnabled,
      required this.ttsEnabled,
      required this.metadata});

  factory LivekitTokenModel.fromJson(Map<String, dynamic> json) => LivekitTokenModel(
      url: json['url']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? '',
      participantIdentity: json['participantIdentity']?.toString() ?? '',
      sttEnabled: json['sttEnabled'] == true,
      ttsEnabled: json['ttsEnabled'] == true,
      metadata: json['metadata']?.toString() ?? '');
}
