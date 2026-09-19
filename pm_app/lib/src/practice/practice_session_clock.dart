/// Supplies elapsed time for one practice-session lifetime.
abstract interface class PracticeSessionClock {
  Duration get elapsed;
}

/// A monotonic practice-session clock.
///
/// It starts when the practice page is initialized, before the initial question
/// load. Loading and retries do not reset it. A [Stopwatch] also keeps measuring
/// while UI callbacks are suspended in the background, so elapsed time means
/// the total attempt duration until completion rather than foreground-only time.
final class StopwatchPracticeSessionClock implements PracticeSessionClock {
  StopwatchPracticeSessionClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  Duration get elapsed => _stopwatch.elapsed;
}
