import 'package:flutter/material.dart';

class UseCaseFrame extends StatelessWidget {
  const UseCaseFrame({
    super.key,
    required this.builder,
    this.padding = const EdgeInsets.all(20),
    this.scrollable = true,
  });

  final WidgetBuilder builder;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) {
            final child = Padding(padding: padding, child: builder(context));
            if (!scrollable) {
              return child;
            }
            return SingleChildScrollView(
              child: Align(alignment: Alignment.topCenter, child: child),
            );
          },
        ),
      ),
    );
  }
}
