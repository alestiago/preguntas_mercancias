import 'package:flutter/material.dart';

enum PracticeProgressSegmentStatus { pending, correct, incorrect }

class PracticeProgressDivider extends StatelessWidget {
  const PracticeProgressDivider({
    super.key,
    required this.segments,
    required this.currentIndex,
  });

  final List<PracticeProgressSegmentStatus> segments;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 7,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var index = 0; index < segments.length; index += 1)
            Expanded(
              child: _PracticeProgressSegment(
                status: segments[index],
                isCurrent: index == currentIndex,
              ),
            ),
        ],
      ),
    );
  }
}

class _PracticeProgressSegment extends StatelessWidget {
  const _PracticeProgressSegment({
    required this.status,
    required this.isCurrent,
  });

  final PracticeProgressSegmentStatus status;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    if (isCurrent) {
      return Container(
        height: 7,
        decoration: BoxDecoration(
          color: status.color(isCurrent: true),
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    return SizedBox(
      height: 3,
      child: ColoredBox(color: status.color(isCurrent: false)),
    );
  }
}

extension _PracticeProgressSegmentStatusColor on PracticeProgressSegmentStatus {
  Color color({required bool isCurrent}) {
    return switch (this) {
      _ when isCurrent => const Color(0xFF1976D2),
      PracticeProgressSegmentStatus.correct ||
      PracticeProgressSegmentStatus.incorrect => const Color(0xFF2E7D32),
      PracticeProgressSegmentStatus.pending => Colors.grey,
    };
  }
}
