import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  void _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          // Decorative circles
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome,',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1A3A5C),
                            ),
                          ),
                          Text(
                            user?.displayName ?? 'Teacher',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5C),
                            ),
                          ),
                        ],
                      ),
                      // Logout button
                      IconButton(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFF5DADE2),
                        ),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5DADE2).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '👨‍🏫 TEACHER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // My Quizzes section
                  const Text(
                    'My Quizzes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Placeholder for quizzes
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 80,
                            color: const Color(0xFF5DADE2).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quizzes created yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF1A3A5C).withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first quiz!',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1A3A5C).withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create quiz screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create Quiz - Coming Soon!')),
          );
        },
        backgroundColor: const Color(0xFF5DADE2),
        icon: const Icon(Icons.add, color: Color(0xFF1A3A5C)),
        label: const Text(
          'Create Quiz',
          style: TextStyle(
            color: Color(0xFF1A3A5C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
