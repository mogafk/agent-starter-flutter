import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import '../controllers/app_ctrl.dart';

/// Call controls in two rows: large microphone and camera toggles on top,
/// speaker, camera flip and leave below. Needs a [components.MediaDeviceContext] above it.
class CallControls extends StatelessWidget {
  const CallControls({super.key});

  @override
  Widget build(BuildContext ctx) {
    final deviceCtx = ctx.watch<components.MediaDeviceContext>();
    final isSpeakerOn = deviceCtx.isSpeakerOn ?? false;
    final cameraPosition = deviceCtx.currentPosition;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundButton(
                size: 76,
                iconSize: 36,
                icon: deviceCtx.microphoneOpened ? Icons.mic : Icons.mic_off,
                isActive: deviceCtx.microphoneOpened,
                tooltip: 'Microphone',
                onPressed: () =>
                    deviceCtx.microphoneOpened ? deviceCtx.disableMicrophone() : deviceCtx.enableMicrophone(),
              ),
              const SizedBox(width: 32),
              _RoundButton(
                size: 76,
                iconSize: 36,
                icon: deviceCtx.cameraOpened ? Icons.videocam : Icons.videocam_off,
                isActive: deviceCtx.cameraOpened,
                tooltip: 'Camera',
                onPressed: () => deviceCtx.cameraOpened ? deviceCtx.disableCamera() : deviceCtx.enableCamera(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (deviceCtx.canSwitchSpeakerphone) ...[
                _RoundButton(
                  icon: isSpeakerOn ? Icons.volume_up : Icons.phone_in_talk,
                  isActive: isSpeakerOn,
                  tooltip: 'Speaker',
                  onPressed: () => deviceCtx.setSpeakerphoneOn(!isSpeakerOn),
                ),
                const SizedBox(width: 24),
              ],
              _RoundButton(
                icon: Icons.flip_camera_android,
                tooltip: 'Switch camera',
                // Only meaningful while the camera is on.
                onPressed: deviceCtx.cameraOpened && cameraPosition != null
                    ? () => deviceCtx.switchCameraPosition(
                        cameraPosition == sdk.CameraPosition.front ? sdk.CameraPosition.back : sdk.CameraPosition.front,
                      )
                    : null,
              ),
              const SizedBox(width: 24),
              _RoundButton(
                icon: Icons.call_end,
                color: Colors.red,
                tooltip: 'Leave',
                onPressed: () => ctx.read<AppCtrl>().leave(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.color,
    this.size = 56,
    this.iconSize = 26,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isActive;
  final Color? color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext ctx) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: iconSize,
    icon: Icon(icon),
    style: IconButton.styleFrom(
      fixedSize: Size.square(size),
      backgroundColor: color ?? (isActive ? components.LKColors.lkBlue : Colors.grey.shade800),
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade900,
      disabledForegroundColor: Colors.grey.shade600,
    ),
  );
}
