import 'package:flutter/material.dart';
import 'choose_questions_type_screen.dart';

class ChooseAssignmentTypeScreen extends StatelessWidget {
  final String classCode;

  const ChooseAssignmentTypeScreen({super.key, required this.classCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          classCode,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'CHOOSE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            _buildTypeButton(
              context,
              label: 'EXAM',
              collectionName: 'exams',
              onTap: () => _navigateToCreate(context, 'exams', 'Exams'),
            ),
            const SizedBox(height: 16),
            _buildTypeButton(
              context,
              label: 'ACTIVITY',
              collectionName: 'activities',
              onTap: () =>
                  _navigateToCreate(context, 'activities', 'Activities'),
            ),
            const SizedBox(height: 16),
            _buildTypeButton(
              context,
              label: 'QUIZ',
              collectionName: 'quizzes',
              onTap: () => _navigateToCreate(context, 'quizzes', 'Quizzes'),
            ),
            const SizedBox(height: 16),
            _buildTypeButton(
              context,
              label: 'ASSIGNMENT',
              collectionName: 'assignments',
              onTap: () =>
                  _navigateToCreate(context, 'assignments', 'Assignments'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreate(
    BuildContext context,
    String collectionName,
    String materialTitle,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChooseQuestionsTypeScreen(
          classCode: classCode,
          collectionName: collectionName,
          materialTitle: materialTitle,
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context, {
    required String label,
    required String collectionName,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF009688), // Teal color from mockup
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description, color: Colors.red, size: 24),
                    Text(
                      'PDF',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
