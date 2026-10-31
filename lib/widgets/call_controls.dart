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
              _DeviceToggle(
                icon: deviceCtx.microphoneOpened ? Icons.mic : Icons.mic_off,
                isActive: deviceCtx.microphoneOpened,
                tooltip: 'Microphone',
                onPressed: () =>
                    deviceCtx.microphoneOpened ? deviceCtx.disableMicrophone() : deviceCtx.enableMicrophone(),
                devices: deviceCtx.audioInputs ?? const [],
                selectedDeviceId: deviceCtx.selectedAudioInputDeviceId,
                onSelectDevice: deviceCtx.selectAudioInput,
              ),
              const SizedBox(width: 32),
              _DeviceToggle(
                icon: deviceCtx.cameraOpened ? Icons.videocam : Icons.videocam_off,
                isActive: deviceCtx.cameraOpened,
                tooltip: 'Camera',
                onPressed: () => deviceCtx.cameraOpened ? deviceCtx.disableCamera() : deviceCtx.enableCamera(),
                devices: deviceCtx.videoInputs ?? const [],
                selectedDeviceId: deviceCtx.selectedVideoInputDeviceId,
                onSelectDevice: deviceCtx.selectVideoInput,
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
                    ? () {
                        // Flipping picks a camera by facing, not by id, so the camera list can't mark one anymore.
                        deviceCtx.selectedVideoInputDeviceId = null;
                        deviceCtx.switchCameraPosition(
                          cameraPosition == sdk.CameraPosition.front ? sdk.CameraPosition.back : sdk.CameraPosition.front,
                        );
                      }
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

/// A large on/off toggle for a media device. When there is more than one device, a small
/// arrow badge (or a long press on the button) opens a menu to pick which one to use.
class _DeviceToggle extends StatelessWidget {
  const _DeviceToggle({
    required this.icon,
    required this.isActive,
    required this.tooltip,
    required this.onPressed,
    required this.devices,
    required this.selectedDeviceId,
    required this.onSelectDevice,
  });

  final IconData icon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onPressed;
  final List<sdk.MediaDevice> devices;
  final String? selectedDeviceId;
  final void Function(sdk.MediaDevice device) onSelectDevice;

  /// Android names cameras like "Camera 1, Facing back, Orientation 90"; show just the facing.
  String _deviceLabel(sdk.MediaDevice device) {
    final facing = RegExp(r'Facing (front|back|external)', caseSensitive: false).firstMatch(device.label);
    final sameFacing = facing == null
        ? 0
        : devices.where((d) => d.label.toLowerCase().contains(facing[0]!.toLowerCase())).length;
    return switch (facing?[1]?.toLowerCase()) {
      // Phones with several back lenses list several "back" cameras; keep the number to tell them apart.
      final side? when sameFacing > 1 => '${_capitalize(side)} camera ${device.deviceId}',
      final side? => '${_capitalize(side)} camera',
      _ => device.label.isNotEmpty ? device.label : 'Device ${device.deviceId}',
    };
  }

  static String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  Future<void> _showDeviceMenu(BuildContext ctx) async {
    final box = ctx.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(ctx).context.findRenderObject()! as RenderBox;
    final device = await showMenu<sdk.MediaDevice>(
      context: ctx,
      position: RelativeRect.fromRect(
        box.localToGlobal(Offset.zero, ancestor: overlay) & box.size,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final device in devices)
          CheckedPopupMenuItem(
            value: device,
            checked: device.deviceId == selectedDeviceId,
            child: Text(_deviceLabel(device)),
          ),
      ],
    );
    if (device != null) onSelectDevice(device);
  }

  @override
  Widget build(BuildContext ctx) {
    final canSelect = devices.length > 1;
    final button = _RoundButton(
      size: 76,
      iconSize: 36,
      icon: icon,
      isActive: isActive,
      // A tooltip would take over the long press that opens the device menu.
      tooltip: canSelect ? null : tooltip,
      onPressed: onPressed,
    );
    if (!canSelect) return button;

    return Semantics(
      label: tooltip,
      child: GestureDetector(
        onLongPress: () => _showDeviceMenu(ctx),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            button,
            Positioned(
              right: -2,
              bottom: -2,
              child: Material(
                color: Colors.grey.shade700,
                shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 2)),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _showDeviceMenu(ctx),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.expand_more, size: 20, color: Colors.white, semanticLabel: 'Choose $tooltip'),
                  ),
                ),
              ),
            ),
          ],
        ),
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
  final String? tooltip;
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
