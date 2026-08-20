import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — use bundled or system fonts for smoother UX
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    const ProviderScope(
      child: SpendTrailApp(),
    ),
  );
}
