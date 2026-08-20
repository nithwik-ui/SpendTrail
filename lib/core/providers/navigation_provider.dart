import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to handle global bottom navigation tab state
final navigationProvider = StateProvider<int>((ref) => 0);
