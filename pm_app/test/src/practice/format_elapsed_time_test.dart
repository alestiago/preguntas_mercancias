import 'package:flutter_test/flutter_test.dart';
import 'package:pm_app/src/practice/format_elapsed_time.dart';

void main() {
  test('formats elapsed time below one minute', () {
    expect(formatElapsedTime(const Duration(seconds: 59)), '00:59');
  });

  test('formats elapsed time at one minute', () {
    expect(formatElapsedTime(const Duration(seconds: 60)), '01:00');
  });

  test('formats elapsed time over one hour', () {
    expect(
      formatElapsedTime(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });
}
