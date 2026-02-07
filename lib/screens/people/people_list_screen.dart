import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/student_bottom_navbar.dart';

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

          final classData = classSnapshot.data?.data() as Map<String, dynamic>?;
          final teacherId = classData?['teacherId'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // People Title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'People',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              // People List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classId)
                      .collection('students')
                      .orderBy('enrolledAt', descending: true)
                      .snapshots(),
                  builder: (context, studentSnapshot) {
                    if (studentSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                          (teacherId != null ? 1 : 0) + studentDocs.length,
                      itemBuilder: (context, index) {
                        // Show Teacher first
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
                              final teacherName =
                                  teacherData?['name'] ?? 'Unknown Teacher';

                              return _buildPersonItem(
                                name: teacherName,
                                role: 'Teacher',
                                context: context,
                              );
                            },
                          );
                        }

                        // Show Students
                        final studentIndex = teacherId != null
                            ? index - 1
                            : index;
                        final studentEnrollment = studentDocs[studentIndex];
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
                            final name = userData?['name'] ?? 'Unknown Student';

                            return _buildPersonItem(
                              name: name,
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
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This feature is coming soon!')),
            );
          }
        },
      ),
    );
  }

  Widget _buildPersonItem({
    required String name,
    required String role,
    required BuildContext context,
  }) {
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
            backgroundColor: Colors.grey[400],
            child: const Icon(Icons.person, color: Colors.white, size: 28),
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
              // TODO: Handle menu actions
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$result for $name')));
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'View Profile',
                child: Text('View Profile'),
              ),
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
}
