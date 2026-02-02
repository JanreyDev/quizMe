import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'take_exam_screen.dart';

class StudentAssignmentsScreen extends StatelessWidget {
  final String classCode;
  final String className;

  const StudentAssignmentsScreen({
    super.key,
    required this.classCode,
    required this.className,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Available Assignments',
              style: TextStyle(
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

                      // While loading submissions, we can still show a loading indicator or proceed with empty set
                      if (submissionSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final submittedIds = (submissionSnapshot.data?.docs ?? [])
                          .map((doc) => doc['assignmentId'] as String)
                          .toSet();

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('assignments')
                            .where('classCode', isEqualTo: classCode)
                            .where('isPublished', isEqualTo: true)
                            .snapshots(),
                        builder: (context, assignmentSnapshot) {
                          if (assignmentSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Assignment Error: ${assignmentSnapshot.error}',
                              ),
                            );
                          }
                          if (assignmentSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!assignmentSnapshot.hasData ||
                              assignmentSnapshot.data == null) {
                            return const Center(
                              child: Text('No assignment data available.'),
                            );
                          }

                          final docs = assignmentSnapshot.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text(
                                  'No assignments published yet for this class.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            );
                          }

                          // Client-side sorting
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
                              final title = data['title'] ?? 'Untitled';
                              final type = data['type'] ?? 'Assignment';
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
                                        assignmentTitle: title,
                                        isReadOnly: isDone,
                                      ),
                                    ),
                                  );
                                },
                                child: _buildAssignmentCard(
                                  title: type,
                                  subtitle: title,
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
    );
  }

  Widget _buildAssignmentCard({
    required String title,
    required String subtitle,
    required String dueDate,
    bool isDone = false,
  }) {
    // Determine icon based on type
    IconData iconData = Icons.assignment;
    if (title.toUpperCase().contains('QUIZ')) {
      iconData = Icons.quiz;
    } else if (title.toUpperCase().contains('ACTIVITY')) {
      iconData = Icons.edit_document;
    } else if (title.toUpperCase().contains('EXAM')) {
      iconData = Icons.assignment;
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
            // Circular White Icon Container
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
            // Text Details
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
