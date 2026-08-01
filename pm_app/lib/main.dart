import 'package:flutter/material.dart';

import 'src/practice/bloc/practice_bloc.dart';
import 'src/practice/practice_page.dart';

void main() {
  runApp(const PreguntasMercanciasApp());
}

class PreguntasMercanciasApp extends StatelessWidget {
  const PreguntasMercanciasApp({super.key, this.loadQuestions});

  final LoadQuestions? loadQuestions;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preguntas Mercancias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF136F63)),
        scaffoldBackgroundColor: const Color(0xFFF6F7F9),
        useMaterial3: true,
      ),
      home: QuestionPracticePage(loadQuestions: loadQuestions),
    );
  }
}
