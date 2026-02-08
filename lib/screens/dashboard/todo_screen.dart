import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../assignments/take_exam_screen.dart';
import '../profile/student_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../widgets/student_bottom_navbar.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<String> _collections = [
    'exams',
    'quizzes',
    'activities',
    'assignments',
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
        ),
        title: const Text(
          'To-do lists',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Get enrolled classes first
        stream: FirebaseFirestore.instance
            .collectionGroup('students')
            .where('studentId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'active')
            .snapshots(),
        builder: (context, enrollmentSnapshot) {
          if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final enrolledClassCodes =
              enrollmentSnapshot.data?.docs.map((doc) {
                // Need to look up class details to get the classCode
                // This is a bit complex in a StreamBuilder, but we can use asyncMap or a separate Future
                return doc.reference.parent.parent!.id;
              }).toList() ??
              [];

          if (enrolledClassCodes.isEmpty) {
            return const Center(child: Text('No enrolled classes'));
          }

          // Wrap everything in a StreamBuilder for submissions to make it dynamic
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('studentId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, submissionsSnapshot) {
              final submittedIds =
                  submissionsSnapshot.data?.docs
                      .map((d) => d['assignmentId'].toString())
                      .toSet() ??
                  {};

              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAllTodoItems(enrolledClassCodes),
                builder: (context, itemsSnapshot) {
                  if (itemsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = itemsSnapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(child: Text('No tasks found'));
                  }

                  // Split into Active and Done based on real-time submissions
                  final activeItems = items
                      .where((i) => !submittedIds.contains(i['id']))
                      .toList();
                  final doneItems = items
                      .where((i) => submittedIds.contains(i['id']))
                      .map((i) => {...i, 'isDone': true})
                      .toList();

                  // Sort by due date
                  activeItems.sort((a, b) {
                    final aDate = a['dueDate'] as Timestamp?;
                    final bDate = b['dueDate'] as Timestamp?;
                    if (aDate == null) return 1;
                    if (bDate == null) return -1;
                    return aDate.compareTo(bDate);
                  });

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    children: [
                      ...activeItems.map(
                        (item) => _buildTodoCard(item, context),
                      ),
                      if (doneItems.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(),
                        ),
                        const Text(
                          'Completed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...doneItems.map(
                          (item) => _buildTodoCard(item, context),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            // Already here
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
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllTodoItems(
    List<String> classIds,
  ) async {
    List<Map<String, dynamic>> allItems = [];

    // Get class details
    Map<String, Map<String, dynamic>> classMap = {};
    for (String id in classIds) {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(id)
          .get();
      if (doc.exists) {
        classMap[id] = doc.data()!..putIfAbsent('id', () => id);
      }
    }

    for (String coll in _collections) {
      for (var entry in classMap.entries) {
        final classData = entry.value;
        final classCode = classData['classCode'];

        final query = await FirebaseFirestore.instance
            .collection(coll)
            .where('classCode', isEqualTo: classCode)
            .where('isPublished', isEqualTo: true)
            .get();

        for (var doc in query.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          data['collection'] = coll;
          data['className'] = classData['name'] ?? 'Class';
          data['classCode'] = classCode;
          data['classId'] = entry.key;
          allItems.add(data);
        }
      }
    }

    return allItems;
  }

  void _startAssignment(Map<String, dynamic> item, BuildContext context) {
    final String collectionName = item['collection'];
    final bool isDone = item['isDone'] ?? false;

    if (isDone) {
      _navigateToExam(item, context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Ready to start?'),
          ],
        ),
        content: Text(
          'You are about to start your ${collectionName.substring(0, collectionName.length - 1).toUpperCase()}.\n\n'
          'IMPORTANT:\n'
          '• Once you begin, you cannot exit until you submit your answers.\n'
          '• Your progress will not be saved if you leave early.\n'
          '• Make sure you have a stable internet connection.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NOT YET',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToExam(item, context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('START NOW'),
          ),
        ],
      ),
    );
  }

  void _navigateToExam(Map<String, dynamic> item, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TakeExamScreen(
          assignmentId: item['id'],
          assignmentTitle: item['title'] ?? 'Untitled',
          isReadOnly: item['isDone'] ?? false,
          collectionName: item['collection'],
          classId: item['classId'],
        ),
      ),
    );
  }

  Widget _buildTodoCard(Map<String, dynamic> item, BuildContext context) {
    final String title = item['title'] ?? 'Untitled';
    final String className = item['className'] ?? '';
    final Timestamp? dueDate = item['dueDate'] as Timestamp?;
    final bool isDone = item['isDone'] ?? false;

    String dateStr = 'N/A';
    if (dueDate != null) {
      dateStr = DateFormat('MMM dd, h:mm a').format(dueDate.toDate());
    }

    return GestureDetector(
      onTap: () => _startAssignment(item, context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDone
                ? [Colors.grey[400]!, Colors.grey[600]!]
                : [const Color(0xFF2774A3), const Color(0xFF1E3A5F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$className — $title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(Due $dateStr)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
