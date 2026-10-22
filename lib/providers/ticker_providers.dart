import 'package:flutter_riverpod/flutter_riverpod.dart';
// In flutter_riverpod 3.x, StateProvider lives in the legacy library.
// (On 2.x, delete this import line.)
import 'package:flutter_riverpod/legacy.dart';
import '../models/tick.dart';
import '../services/tick_feed.dart';

/// null = never fail, otherwise fail after N ticks.
final failAfterProvider = StateProvider<int?>((ref) => null);

/// Overridable in tests and in the error demo.
final tickFeedProvider = Provider<TickFeed>((ref) {
  return TickFeed(failAfter: ref.watch(failAfterProvider));
});

final tickerProvider = StreamProvider.autoDispose<List<Tick>>(
  (ref) => ref.watch(tickFeedProvider).watch(),
  // Riverpod 3 auto-retries failed providers by default. Disable it so the
  // error state (and the manual Retry button) is visible. Remove this line
  // if you are on 2.x.
  retry: (_, _) => null,
);