import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as sdk;
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import '../services/call_service.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext ctx) => PopScope(
    // Back minimizes the app instead of closing it, so the call keeps going.
    // (This screen stays in the tree behind the join screen, hence the connected check.)
    canPop: !ctx.select<components.RoomContext, bool>((roomCtx) => roomCtx.connected),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(CallService.moveToBackground());
    },
    child: Material(
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Selector<components.RoomContext, bool>(
                selector: (ctx, roomCtx) => roomCtx.pinnedTracks.isNotEmpty,
                builder: (ctx, hasPinnedTracks, child) => components.ParticipantLoop(
                  // One tile per participant: their camera (or a placeholder) plus any screen share.
                  showVideoTracks: true,
                  showAudioTracks: false,
                  showParticipantPlaceholder: true,
                  layoutBuilder: hasPinnedTracks
                      ? const components.CarouselLayoutBuilder()
                      : const components.GridLayoutBuilder(),
                  participantTrackBuilder: (ctx, identifier) => const Padding(
                    padding: EdgeInsets.all(2),
                    child: _ParticipantTile(),
                  ),
                ),
              ),
            ),
            components.MediaDeviceContextBuilder(
              builder: (ctx, roomCtx, deviceCtx) => const components.ControlBar(
                chat: false,
                screenShare: false,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile();

  @override
  Widget build(BuildContext ctx) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Stack(
      children: [
        Positioned.fill(
          child: components.IsSpeakingIndicator(
            builder: (ctx, isSpeaking) => components.IsSpeakingIndicatorWidget(
              isSpeaking: isSpeaking ?? false,
              // Crop cameras to fill the tile, but never crop a screen share.
              child: components.VideoTrackWidget(
                fit: (ctx.watch<components.TrackReferenceContext?>()?.isScreenShare ?? false)
                    ? sdk.VideoViewFit.contain
                    : sdk.VideoViewFit.cover,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 0,
          right: 0,
          child: components.FocusToggle(),
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: components.ParticipantStatusBar(),
        ),
      ],
    ),
  );
}
