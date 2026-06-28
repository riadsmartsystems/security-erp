import 'package:flutter/material.dart';
import 'color_tokens.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: Brightness.dark,
    surface: kSurfaceDark,
  ),
  scaffoldBackgroundColor: kSurfaceDark,
  cardColor: kSurfaceCard,
);

final vaultTheme = appTheme.copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: kVaultAccent,
    brightness: Brightness.dark,
  ),
);
