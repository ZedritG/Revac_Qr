import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Basic observer to trace provider life cycle events during development.
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void didUpdateProvider(
    ProviderBase<dynamic> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    assert(() {
      // ignore: avoid_print
      print(
        'Provider \${provider.name ?? provider.runtimeType} updated: '
        '\$previousValue -> \$newValue',
      );
      return true;
    }());
  }
}
