import 'package:flutter/material.dart';
import 'choose_exam_type_screen.dart';

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
              icon: Icons.edit_note,
              label: 'EXAM',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChooseExamTypeScreen(classCode: classCode),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildTypeButton(
              context,
              icon: Icons.edit_note,
              label: 'ACTIVITY',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildTypeButton(
              context,
              icon: Icons.edit_note,
              label: 'QUIZ',
              onTap: () {},
            ),
            const SizedBox(height: 16),
            _buildTypeButton(
              context,
              icon: Icons.edit_note,
              label: 'ASSIGNMENT',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF00796B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
