import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notifications/notifications_screen.dart';
import '../dashboard/todo_screen.dart';
import '../profile/student_profile_screen.dart';
import '../../widgets/student_bottom_navbar.dart';
import '../../services/notification_service.dart';

class PeopleListScreen extends StatelessWidget {
  final String classCode;
  final String classId;

  const PeopleListScreen({
    super.key,
    required this.classCode,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, userRoleSnapshot) {
        if (!userRoleSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final userRoleData =
            userRoleSnapshot.data?.data() as Map<String, dynamic>?;
        final String role =
            userRoleData?['role']?.toString().toUpperCase() ?? 'STUDENT';

        // Helper to build the main people list scaffold
        Widget buildMainScaffold() {
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
                'People',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .get(),
              builder: (context, classSnapshot) {
                if (classSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (classSnapshot.hasError) {
                  return Center(child: Text('Error: ${classSnapshot.error}'));
                }

                final classData =
                    classSnapshot.data?.data() as Map<String, dynamic>?;
                final teacherId = classData?['teacherId'];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class Code Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Text(
                        classCode,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('classes')
                            .doc(classId)
                            .collection('students')
                            .snapshots(),
                        builder: (context, studentSnapshot) {
                          if (studentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (studentSnapshot.hasError) {
                            return Center(
                              child: Text('Error: ${studentSnapshot.error}'),
                            );
                          }

                          final studentDocs = studentSnapshot.data?.docs ?? [];

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount:
                                (teacherId != null ? 1 : 0) +
                                studentDocs.length,
                            itemBuilder: (context, index) {
                              if (teacherId != null && index == 0) {
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(teacherId)
                                      .get(),
                                  builder: (context, teacherSnapshot) {
                                    if (!teacherSnapshot.hasData) {
                                      return const SizedBox.shrink();
                                    }
                                    final teacherData =
                                        teacherSnapshot.data!.data()
                                            as Map<String, dynamic>?;
                                    return _buildPersonItem(
                                      userId: teacherId,
                                      userData: teacherData!,
                                      role: 'Teacher',
                                      context: context,
                                    );
                                  },
                                );
                              }

                              final studentIndex = teacherId != null
                                  ? index - 1
                                  : index;
                              final studentEnrollment =
                                  studentDocs[studentIndex];
                              final studentId = studentEnrollment.id;

                              return FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(studentId)
                                    .get(),
                                builder: (context, userSnapshot) {
                                  if (!userSnapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  final userData =
                                      userSnapshot.data!.data()
                                          as Map<String, dynamic>?;

                                  if (userData == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return _buildPersonItem(
                                    userId: studentId,
                                    userData: userData,
                                    role: 'Student',
                                    context: context,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            bottomNavigationBar: role == 'STUDENT'
                ? StudentBottomNavBar(
                    currentIndex: 0,
                    onTap: (index) {
                      if (index == 0) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      } else if (index == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TodoScreen(),
                          ),
                        );
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
                      }
                    },
                  )
                : null,
          );
        }

        if (role == 'STUDENT') {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .collection('students')
                .doc(currentUser?.uid)
                .snapshots(),
            builder: (context, enrollmentSnapshot) {
              final bool isEnrolled =
                  enrollmentSnapshot.hasData && enrollmentSnapshot.data!.exists;

              if (enrollmentSnapshot.connectionState ==
                      ConnectionState.waiting &&
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
                            'You are no longer enrolled in this class. Please contact your teacher if you believe this is an error.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF42A5F5),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
              return buildMainScaffold();
            },
          );
        }

        return buildMainScaffold();
      },
    );
  }

  void _showProfileModal({
    required BuildContext context,
    required Map<String, dynamic> userData,
    required String role,
  }) {
    final String name = userData['name'] ?? 'Unknown Member';
    final String? photoUrl = userData['photoUrl'];
    final String course = userData['course'] ?? 'No Course';
    final String age = userData['age']?.toString() ?? 'N/A';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.grey, size: 50)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              if (role != 'Teacher') ...[
                _buildProfileDetail(Icons.school_outlined, 'Course', course),
                const SizedBox(height: 16),
              ],
              _buildProfileDetail(
                Icons.calendar_today_outlined,
                'Age',
                '$age years old',
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF4EB3FD), size: 24),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonItem({
    required String userId,
    required Map<String, dynamic> userData,
    required String role,
    required BuildContext context,
  }) {
    final String name = userData['name'] ?? 'Unknown Member';
    final String? photoUrl = userData['photoUrl'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl == null || photoUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.grey, size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          // Name and Role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          // Three-dot menu
          PopupMenuButton<String>(
            icon: Row(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.only(left: 3),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            onSelected: (String result) {
              if (result == 'View Profile') {
                _showProfileModal(
                  context: context,
                  userData: userData,
                  role: role,
                );
              } else if (result == 'Remove') {
                _removeStudent(
                  context: context,
                  studentId: userId,
                  studentName: name,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'View Profile',
                child: Text('View Profile'),
              ),
              if (role != 'Teacher')
                const PopupMenuItem<String>(
                  value: 'Remove',
                  child: Text('Remove', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _removeStudent({
    required BuildContext context,
    required String studentId,
    required String studentName,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Remove Student'),
          content: Text('Are you sure you want to remove $studentName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                try {
                  // 1. Remove from students subcollection
                  await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classId)
                      .collection('students')
                      .doc(studentId)
                      .delete();

                  // 2. Send notification to student
                  await NotificationService.sendToStudent(
                    studentId: studentId,
                    classId: classId,
                    classCode: classCode,
                    className: classCode, // Use classCode as name for now
                    title: 'Class Update',
                    message: 'You have been removed from class $classCode.',
                    type: 'system',
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Removed $studentName')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error removing student: $e')),
                    );
                  }
                }
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
