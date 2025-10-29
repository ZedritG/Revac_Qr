import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:revec_qr/app/app.dart';
import 'package:revec_qr/shared/providers/provider_logger.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  runApp(
    ProviderScope(
      observers: const [AppProviderObserver()],
      child: const App(),
    ),
  );
}
