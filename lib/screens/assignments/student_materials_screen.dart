import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'take_exam_screen.dart';
import '../../widgets/student_bottom_navbar.dart';

class StudentMaterialsScreen extends StatelessWidget {
  final String classCode;
  final String className;
  final String collectionName;
  final String title;

  const StudentMaterialsScreen({
    super.key,
    required this.classCode,
    required this.className,
    required this.collectionName,
    required this.title,
  });

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Available $title',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: user == null
                ? const Center(child: Text('Please log in'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('submissions')
                        .where('studentId', isEqualTo: user.uid)
                        .snapshots(),
                    builder: (context, submissionSnapshot) {
                      if (submissionSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Submission Error: ${submissionSnapshot.error}',
                          ),
                        );
                      }

                      if (submissionSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final submittedIds = (submissionSnapshot.data?.docs ?? [])
                          .map((doc) => doc['assignmentId'] as String)
                          .toSet();

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection(collectionName)
                            .where('classCode', isEqualTo: classCode)
                            .where('isPublished', isEqualTo: true)
                            .snapshots(),
                        builder: (context, materialSnapshot) {
                          if (materialSnapshot.hasError) {
                            return Center(
                              child: Text('Error: ${materialSnapshot.error}'),
                            );
                          }
                          if (materialSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = materialSnapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'No ${title.toLowerCase()} published yet for this class.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          final sortedDocs = List<QueryDocumentSnapshot>.from(
                            docs,
                          );
                          sortedDocs.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>;
                            final bData = b.data() as Map<String, dynamic>;
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;
                            if (aTime == null) return 1;
                            if (bTime == null) return -1;
                            return bTime.compareTo(aTime);
                          });

                          return ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: sortedDocs.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final doc = sortedDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final mTitle = data['title'] ?? 'Untitled';
                              final dueDate = data['dueDate'] as Timestamp?;
                              final isDone = submittedIds.contains(docId);

                              String formattedDate = 'N/A';
                              if (dueDate != null) {
                                formattedDate = DateFormat(
                                  'MMM dd, hh:mm a',
                                ).format(dueDate.toDate());
                              }

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TakeExamScreen(
                                        assignmentId: docId,
                                        assignmentTitle: mTitle,
                                        isReadOnly: isDone,
                                        collectionName: collectionName,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildMaterialCard(
                                  title: title,
                                  subtitle: mTitle,
                                  dueDate: formattedDate,
                                  isDone: isDone,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
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

  Widget _buildMaterialCard({
    required String title,
    required String subtitle,
    required String dueDate,
    bool isDone = false,
  }) {
    IconData iconData = Icons.assignment;
    if (collectionName == 'quizzes') {
      iconData = Icons.quiz;
    } else if (collectionName == 'activities') {
      iconData = Icons.edit_document;
    }

    return Opacity(
      opacity: isDone ? 0.7 : 1.0,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDone
                ? [Colors.grey[300]!, Colors.grey[400]!]
                : [Colors.grey[400]!, Colors.grey[600]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
              child: Icon(iconData, color: Colors.grey[700], size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isDone ? 'COMPLETED' : 'Due: $dueDate',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDone ? Colors.green[700] : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.check_circle, color: Colors.green, size: 28),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
