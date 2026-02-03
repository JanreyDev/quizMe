import 'package:flutter/material.dart';
import '../assignments/student_unified_assignments_screen.dart';

class StudentSubjectViewScreen extends StatelessWidget {
  final String classCode;
  final String className;

  const StudentSubjectViewScreen({
    super.key,
    required this.classCode,
    required this.className,
  });

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject Name Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Text(
              className,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Menu Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuOption(
                    context,
                    icon: Icons.assignment_outlined,
                    title: 'Assignments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentUnifiedAssignmentsScreen(
                            classCode: classCode,
                            className: className,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuOption(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: 'Modules',
                    onTap: () {
                      // Future implementation
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuOption(
                    context,
                    icon: Icons.people_outline,
                    title: 'People',
                    onTap: () {
                      // Future implementation
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuOption(
                    context,
                    icon: Icons.menu_book_outlined,
                    title: 'Modules',
                    onTap: () {
                      // Future implementation
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuOption(
                    context,
                    icon: Icons.people_outline,
                    title: 'People',
                    onTap: () {
                      // Future implementation
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF4A4A8C),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'To-do'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notification',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.black87),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
