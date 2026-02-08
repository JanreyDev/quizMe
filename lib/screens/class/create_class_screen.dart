import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  String _generateClassCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      6,
      (index) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  Future<void> _handleCreateClass() async {
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter a class name');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final classCode = _generateClassCode();

      await FirebaseFirestore.instance.collection('classes').add({
        'name': _nameController.text.trim(),
        'section': _sectionController.text.trim(),
        'classCode': classCode,
        'teacherId': user?.uid,
        'teacherName': user?.displayName ?? 'Teacher',
        'createdAt': FieldValue.serverTimestamp(),
        'studentCount': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class "$classCode" created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to create class: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      resizeToAvoidBottomInset: false, // Prevents background from moving
      body: Stack(
        children: [
          // Decorative circles in background - top right (Matches Login)
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6E9F8).withOpacity(0.5),
              ),
            ),
          ),
          // Decorative circle - bottom left (Matches Login)
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6E9F8).withOpacity(0.5),
              ),
            ),
          ),
          // Main content
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            // Back button
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back),
                              color: const Color(0xFF1A3A5C),
                            ),
                            const SizedBox(height: 20),
                            // Title
                            const Text(
                              'Create',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A5C),
                                height: 1.2,
                              ),
                            ),
                            const Text(
                              'a Class',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A5C),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 60),
                            // Form Fields
                            _InputField(
                              controller: _nameController,
                              hintText: 'Class Name / Subject',
                              icon: Icons.class_outlined,
                            ),
                            const SizedBox(height: 20),
                            _InputField(
                              controller: _sectionController,
                              hintText: 'Section / Description',
                              icon: Icons.segment,
                            ),
                            const Spacer(),
                            _InputField(
                              controller: TextEditingController(
                                text: user?.displayName ?? 'Teacher',
                              ),
                              hintText: 'Instructor',
                              icon: Icons.person_outline,
                              enabled: false,
                            ),
                            const SizedBox(height: 20),
                            // Create Button
                            _ActionButton(
                              text: _isLoading ? 'Creating...' : 'Create Class',
                              onPressed: _isLoading
                                  ? () {}
                                  : _handleCreateClass,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _InputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF5DADE2), width: 2),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A3A5C)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 15,
            color: const Color(0xFF1A3A5C).withOpacity(0.4),
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF5DADE2)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _ActionButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF5DADE2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5DADE2).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3A5C),
            ),
          ),
        ),
      ),
    );
  }
}
