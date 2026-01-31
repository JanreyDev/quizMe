import 'package:flutter/material.dart';
import 'package:quizme/screens/splash_screen.dart';

void main() {
  runApp(const QuizMeApp());
}

class QuizMeApp extends StatelessWidget {
  const QuizMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
