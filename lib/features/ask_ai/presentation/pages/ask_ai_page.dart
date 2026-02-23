import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/coming_soon.dart';

class AskAiPage extends StatefulWidget {
  const AskAiPage({super.key});

  @override
  State<AskAiPage> createState() => AskAiPageState();
}

class AskAiPageState extends State<AskAiPage> {
  final Room room = Room();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  bool isConnecting = false;
  bool isMicOn = false;
  bool isSpeakerOn = false;
  String? errorMessage;
  late final VoidCallback roomListener;

  @override
  void initState() {
    super.initState();
    roomListener = () {
      if (!mounted) return;
      setState(() {});
    };
    room.addListener(roomListener);
  }

  @override
  void dispose() {
    room.removeListener(roomListener);
    urlController.dispose();
    tokenController.dispose();
    room.dispose();
    super.dispose();
  }

  bool get isConnected => room.connectionState == ConnectionState.done;

  Future<void> connectRoom() async {
    final url = urlController.text.trim();
    final token = tokenController.text.trim();
    if (url.isEmpty || token.isEmpty) {
      context.showSnackBar(SnackBar(content: Text('Provide server url and token'.tr())));
      return;
    }
    setState(() {
      isConnecting = true;
      errorMessage = null;
    });
    try {
      await room.connect(url, token,
          roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
      await room.localParticipant?.setMicrophoneEnabled(true);
      isMicOn = true;
      isSpeakerOn = false;
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      if (!mounted) return;
      setState(() => isConnecting = false);
    }
  }

  Future<void> disconnectRoom() async {
    await room.disconnect();
    if (!mounted) return;
    setState(() {
      isMicOn = false;
      isSpeakerOn = false;
    });
  }

  Future<void> toggleMic() async {
    final next = !isMicOn;
    await room.localParticipant?.setMicrophoneEnabled(next);
    if (!mounted) return;
    setState(() => isMicOn = next);
  }

  Future<void> toggleSpeaker() async {
    final next = !isSpeakerOn;
    await room.setSpeakerOn(next, forceSpeakerOutput: true);
    if (!mounted) return;
    setState(() => isSpeakerOn = next);
  }

  Widget headerStatus() => Column(children: [
        Text('Ask AI'.tr(), style: Style.body2w6(context)),
        const SizedBox(height: 6),
        Text('Status: {status}'.tr(namedArgs: {'status': room.connectionState.name}),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget connectionForm() => Column(children: [
        TextField(
            controller: urlController,
            decoration: InputDecoration(labelText: 'LiveKit server url'.tr())),
        const SizedBox(height: 12),
        TextField(
            controller: tokenController,
            decoration: InputDecoration(labelText: 'Access token'.tr()),
            maxLines: 3),
        const SizedBox(height: 16),
        Button.primary(
            onTap: connectRoom,
            text: 'Connect'.tr(),
            isLoading: isConnecting,
            isAvialable: !isConnected)
      ]);

  Widget connectedControls() => Column(children: [
        const SizedBox(height: 8),
        Button.primary(onTap: toggleMic, text: isMicOn ? 'Mute mic'.tr() : 'Unmute mic'.tr()),
        const SizedBox(height: 8),
        Button.border(
            onTap: toggleSpeaker, text: isSpeakerOn ? 'Speaker off'.tr() : 'Speaker on'.tr()),
        const SizedBox(height: 8),
        Button.border(onTap: disconnectRoom, text: 'Disconnect'.tr())
      ]);

  Widget participantsList() {
    final participants = room.remoteParticipants.values.toList();
    if (participants.isEmpty) {
      return Text('No participants'.tr(),
          style: Style.small3w4(context, color: TextColorRole.greyColor));
    }
    return Column(
        children: participants
            .map((p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(p.identity, style: Style.bodyw5(context))))
            .toList());
  }

  Widget content() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        headerStatus(),
        const SizedBox(height: 24),
        if (!isConnected) connectionForm() else connectedControls(),
        const SizedBox(height: 24),
        Text('Participants'.tr(), style: Style.body2w6(context)),
        const SizedBox(height: 8),
        participantsList(),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(errorMessage!, style: Style.small3w4(context).copyWith(color: AppColors.error))
        ],
        const SizedBox(height: 80)
      ]);

  @override
  Widget build(BuildContext context) => PrimaryBackground(

      backgroundColor: context.cs.surface,
      child: Padding(padding: Style.paddingPrimary, child: ComingSoonPage()));
}
