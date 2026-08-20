import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Awake locale data so Formatters can render Arabic dates.
  await initializeDateFormatting('ar', null);

  // Make status bar transparent so gradient backgrounds extend fully.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF6F7FB),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: _InitializedApp(),
    ),
  );
}

class _InitializedApp extends ConsumerStatefulWidget {
  const _InitializedApp();
  @override
  ConsumerState<_InitializedApp> createState() => _InitializedAppState();
}

class _InitializedAppState extends ConsumerState<_InitializedApp> {
  @override
  void initState() {
    super.initState();
    // Touch the auth controller so it begins resolving the persisted session.
    Future.microtask(() => ref.read(authControllerProvider));
  }

  @override
  Widget build(BuildContext context) {
    return const BinaAcademyApp();
  }
}
