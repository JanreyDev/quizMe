import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../profile/student_profile_screen.dart';
import '../dashboard/todo_screen.dart';
import '../../widgets/student_bottom_navbar.dart';
import '../assignments/student_unified_assignments_screen.dart';
import '../modules/student_modules_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: user == null
          ? const Center(child: Text('Please log in to see notifications'))
          : StreamBuilder<QuerySnapshot>(
              stream: NotificationService.getNotifications(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort in-memory (newest first)
                final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
                sortedDocs.sort((a, b) {
                  final aTime =
                      (a.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  final bTime =
                      (b.data() as Map<String, dynamic>)['createdAt']
                          as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

                // Group by className
                final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                for (var doc in sortedDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final className = data['className'] ?? 'Other';
                  grouped.putIfAbsent(className, () => []).add(doc);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: grouped.keys.length,
                  itemBuilder: (context, index) {
                    final className = grouped.keys.elementAt(index);
                    final classDocs = grouped[className]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            className,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        ...classDocs.map(
                          (doc) => _buildNotificationItem(context, doc),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: StudentBottomNavBar(
        currentIndex: 2, // Notification tab
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TodoScreen()),
            );
          } else if (index == 2) {
            // Already here
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

  Widget _buildNotificationItem(
    BuildContext context,
    QueryDocumentSnapshot doc,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Notification';
    final message = data['message'] ?? '';
    final type = data['type'] ?? 'assignment';
    final isRead = data['isRead'] ?? false;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    Widget iconWidget;

    switch (type.toLowerCase()) {
      case 'module':
        iconWidget = _buildIconContainer(
          Icons.folder_open_rounded,
          Colors.blue[400]!,
          const Color(0xFFE3F2FD),
        );
        break;
      case 'quiz':
        iconWidget = _buildIconContainer(
          Icons.lightbulb_outline_rounded,
          Colors.amber[700]!,
          const Color(0xFFFFF8E1),
        );
        break;
      case 'assignment':
      case 'activity':
      default:
        iconWidget = _buildIconContainer(
          Icons.menu_book_rounded,
          const Color(0xFF2E7D32),
          const Color(0xFFE8F5E9),
        );
        break;
    }

    return InkWell(
      onTap: () {
        if (!isRead) {
          NotificationService.markAsRead(doc.id);
        }

        final classId = data['classId'] as String?;
        final classCode = data['classCode'] as String?;

        if (classId == null || classCode == null) return;

        if (type.toLowerCase() == 'modules' || type.toLowerCase() == 'module') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  StudentModulesScreen(classCode: classCode, classId: classId),
            ),
          );
        } else {
          final className = data['className'] as String? ?? 'Class';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentUnifiedAssignmentsScreen(
                classCode: classCode,
                className: className,
                classId: classId,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.08),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            iconWidget,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isRead ? Colors.black87 : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (createdAt != null)
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color iconColor, Color bgColor) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}
