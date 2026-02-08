import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../assignments/student_unified_assignments_screen.dart';
import '../modules/student_modules_screen.dart';
import '../people/people_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/student_profile_screen.dart';
import '../../widgets/student_bottom_navbar.dart';

class StudentSubjectViewScreen extends StatelessWidget {
  final String classCode;
  final String className;
  final String classId;

  const StudentSubjectViewScreen({
    super.key,
    required this.classCode,
    required this.className,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('students')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        // If snapshot has no data or document doesn't exist, they are not enrolled
        final bool isEnrolled =
            enrollmentSnapshot.hasData && enrollmentSnapshot.data!.exists;

        // While loading the initial enrollment check
        if (enrollmentSnapshot.connectionState == ConnectionState.waiting &&
            !enrollmentSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!isEnrolled) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Access Denied',
                style: TextStyle(color: Colors.black),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_person_outlined,
                      size: 80,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Access Revoked',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are no longer enrolled in $className. Please contact your teacher if you believe this is an error.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF42A5F5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'BACK TO DASHBOARD',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Class Dashboard',
              style: TextStyle(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
                        title: 'School work',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StudentUnifiedAssignmentsScreen(
                                    classCode: classCode,
                                    className: className,
                                    classId: classId,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentModulesScreen(
                                classCode: classCode,
                                classId: classId,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildMenuOption(
                        context,
                        icon: Icons.people_outline,
                        title: 'People',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PeopleListScreen(
                                classCode: classCode,
                                classId: classId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: StudentBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              if (index == 0) {
                Navigator.pop(context);
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentProfileScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('This feature is coming soon!')),
                );
              }
            },
          ),
        );
      },
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
