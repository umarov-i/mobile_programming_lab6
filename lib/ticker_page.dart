import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/tick.dart';
import 'providers/ticker_providers.dart';
import 'widgets/tick_row.dart';

class TickerPage extends ConsumerWidget {
  const TickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticks = ref.watch(tickerProvider);

    Widget list(List<Tick> value) => RefreshIndicator(
          // Exercise 4.3: swap for ref.invalidate(tickerProvider) to compare.
          onRefresh: () => ref.refresh(tickerProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [for (final t in value) TickRow(t, key: ValueKey(t.symbol))],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live ticker'),
        actions: [
          IconButton(
            tooltip: 'Make feed fail after 5 ticks',
            icon: const Icon(Icons.bug_report),
            onPressed: () => ref.read(failAfterProvider.notifier).state = 5,
          ),
          IconButton(
            tooltip: 'Feed healthy',
            icon: const Icon(Icons.check_circle_outline),
            onPressed: () => ref.read(failAfterProvider.notifier).state = null,
          ),
        ],
      ),
      body: switch (ticks) {
        // Error with stale data: dimmed rows + banner on top
        AsyncError(:final error, :final value?) => Column(children: [
            MaterialBanner(
              content: Text('Feed error: $error — showing last prices'),
              actions: [
                TextButton(
                  onPressed: () => ref.invalidate(tickerProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            Expanded(child: Opacity(opacity: 0.5, child: list(value))),
          ]),

        // Error with nothing to show
        AsyncError(:final error) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Could not load ticker\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(tickerProvider),
                child: const Text('Retry'),
              ),
            ]),
          ),

        // Refresh/reload in progress: keep rows, thin progress bar
        AsyncValue(:final value?, isLoading: true) => Column(children: [
            const LinearProgressIndicator(),
            Expanded(child: list(value)),
          ]),

        // Content-based arms (exercise 3.4): must be above the general arm
        AsyncData(value: []) => const Center(child: Text('No symbols subscribed')),
        AsyncData(value: [final only]) => Center(child: TickRow(only)),

        AsyncData(:final value) => list(value),

        // Cold start only
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}