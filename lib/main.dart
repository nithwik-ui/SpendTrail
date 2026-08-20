import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/services/volume_shortcut_service.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — use bundled or system fonts for smoother UX
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize the volume-down shortcut listener
  VolumeShortcutService.init();

  runApp(
    const ProviderScope(
      child: SpendTrailApp(),
    ),
  );
}
