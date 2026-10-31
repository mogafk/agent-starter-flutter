import 'package:flutter/material.dart';
import 'package:livekit_components/livekit_components.dart' as components;
import 'package:provider/provider.dart';

import 'controllers/app_ctrl.dart';
import 'screens/join_screen.dart';
import 'screens/room_screen.dart';
import 'ui/color_pallette.dart' show LKColorPaletteLight, LKColorPaletteDark;
import 'widgets/app_layout_switcher.dart';

final appCtrl = AppCtrl();

class MeetApp extends StatelessWidget {
  const MeetApp({super.key});

  ThemeData buildTheme({required bool isLight}) {
    final colorPallete = isLight ? LKColorPaletteLight() : LKColorPaletteDark();

    return ThemeData(
      useMaterial3: true,
      cardColor: colorPallete.bg2,
      scaffoldBackgroundColor: colorPallete.bg1,
      canvasColor: colorPallete.bg1,
      inputDecorationTheme: InputDecorationTheme(
        fillColor: colorPallete.bg2,
        hintStyle: TextStyle(
          color: colorPallete.fg4,
          fontSize: 14,
        ),
      ),
      buttonTheme: ButtonThemeData(
        disabledColor: Colors.red,
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          secondary: Colors.white,
          surface: colorPallete.fgAccent,
        ),
      ),
      colorScheme: isLight
          ? const ColorScheme.light(
              primary: Colors.black,
              secondary: Colors.black,
              surface: Colors.white,
            )
          : const ColorScheme.dark(
              primary: Colors.white,
              secondary: Colors.white,
              surface: Colors.black,
            ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => ChangeNotifierProvider.value(
    value: appCtrl,
    // AppCtrl swaps in a new RoomContext after every call, so the provider below follows it.
    child: Selector<AppCtrl, components.RoomContext>(
      selector: (ctx, appCtrl) => appCtrl.roomContext,
      builder: (ctx, roomContext, child) => ChangeNotifierProvider.value(
        key: ObjectKey(roomContext),
        value: roomContext,
        child: child,
      ),
      child: MaterialApp(
        title: 'Englishmans livekit',
        theme: buildTheme(isLight: true),
        darkTheme: buildTheme(isLight: false),
        home: Selector<components.RoomContext, bool>(
          selector: (ctx, roomCtx) => roomCtx.connected,
          builder: (ctx, isConnected, _) => AppLayoutSwitcher(
            frontBuilder: (ctx) => const JoinScreen(),
            backBuilder: (ctx) => const RoomScreen(),
            isFront: !isConnected,
          ),
        ),
      ),
    ),
  );
}
