import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import '../controllers/app_ctrl.dart';
import '../widgets/button.dart' as buttons;

class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Material(
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Consumer<AppCtrl>(
            builder: (ctx, appCtrl, child) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                const _CameraPreview(),
                const _DeviceToggles(),
                TextField(
                  controller: appCtrl.roomLinkCtrl,
                  enabled: !appCtrl.isJoining,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Room link',
                    hintText: 'https://englishmans.duckdns.org/rooms/…',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextField(
                  controller: appCtrl.nameCtrl,
                  enabled: !appCtrl.isJoining,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (appCtrl.errorMessage != null)
                  Text(
                    appCtrl.errorMessage!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                Center(
                  child: buttons.Button(
                    text: appCtrl.isJoining ? 'Joining' : 'Join',
                    isProgressing: appCtrl.isJoining,
                    onPressed: appCtrl.canJoin ? () => appCtrl.join() : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview();

  @override
  Widget build(BuildContext ctx) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: AspectRatio(
      aspectRatio: 4 / 3,
      child: components.CameraPreview(
        builder: (ctx, videoTrack) => Container(
          color: Theme.of(ctx).cardColor,
          child: videoTrack != null
              ? sdk.VideoTrackRenderer(videoTrack, fit: sdk.VideoViewFit.cover)
              : const Center(child: Icon(Icons.videocam_off_outlined, size: 48)),
        ),
      ),
    ),
  );
}

class _DeviceToggles extends StatelessWidget {
  const _DeviceToggles();

  @override
  Widget build(BuildContext ctx) => components.MediaDeviceContextBuilder(
    builder: (ctx, roomCtx, deviceCtx) {
      final style = IconButton.styleFrom(
        backgroundColor: Theme.of(ctx).cardColor,
        foregroundColor: Theme.of(ctx).colorScheme.primary,
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 16,
        children: [
          IconButton(
            style: style,
            iconSize: 28,
            tooltip: deviceCtx.microphoneOpened ? 'Turn microphone off' : 'Turn microphone on',
            icon: Icon(deviceCtx.microphoneOpened ? Icons.mic : Icons.mic_off),
            onPressed: () => deviceCtx.microphoneOpened ? deviceCtx.disableMicrophone() : deviceCtx.enableMicrophone(),
          ),
          IconButton(
            style: style,
            iconSize: 28,
            tooltip: deviceCtx.cameraOpened ? 'Turn camera off' : 'Turn camera on',
            icon: Icon(deviceCtx.cameraOpened ? Icons.videocam : Icons.videocam_off),
            onPressed: () => deviceCtx.cameraOpened ? deviceCtx.disableCamera() : deviceCtx.enableCamera(),
          ),
        ],
      );
    },
  );
}
